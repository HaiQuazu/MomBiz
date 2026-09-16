import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/exchange_rate.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/payment_service.dart';
import '../../utils/money_utils.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({
    super.key,
    required this.customer,
    required this.khrOutstanding,
    required this.usdOutstanding,
  });

  final Customer customer;

  // KHR stored as whole riel.
  final int khrOutstanding;

  // USD stored as cents.
  final int usdOutstanding;

  @override
  State<PaymentFormScreen> createState() =>
      _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late MoneyCurrency _appliedCurrency;
  late MoneyCurrency _paidCurrency;

  PaymentMethodType _method = PaymentMethodType.cash;

  DateTime _paymentDate = DateTime.now();

  ExchangeRate? _nbcRate;

  bool _loadingRate = false;
  bool _saving = false;

  String? _rateError;

  @override
  void initState() {
    super.initState();

    if (widget.khrOutstanding > 0) {
      _appliedCurrency = MoneyCurrency.khr;
    } else {
      _appliedCurrency = MoneyCurrency.usd;
    }

    _paidCurrency = _appliedCurrency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  int get _selectedOutstanding {
    if (_appliedCurrency == MoneyCurrency.khr) {
      return widget.khrOutstanding;
    }

    return widget.usdOutstanding;
  }

  bool get _needsConversion {
    return _paidCurrency != _appliedCurrency;
  }

  int get _paidAmount {
    return MoneyUtils.parse(
          _amountController.text,
          _paidCurrency,
        ) ??
        0;
  }

  int get _appliedAmount {
    final paidAmount = _paidAmount;

    if (paidAmount <= 0) {
      return 0;
    }

    if (!_needsConversion) {
      return paidAmount;
    }

    final rate = _nbcRate?.khrPerUsd;

    if (rate == null || rate <= 0) {
      return 0;
    }

    // Customer paid KHR toward USD debt.
    //
    // Example:
    // 405,300 KHR
    // rate = 4,053 KHR / USD
    //
    // becomes $100.00 = 10,000 cents.
    if (_paidCurrency == MoneyCurrency.khr &&
        _appliedCurrency == MoneyCurrency.usd) {
      return ((paidAmount * 100) + (rate ~/ 2)) ~/ rate;
    }

    // Customer paid USD toward KHR debt.
    //
    // USD is stored as cents.
    // $100.00 = 10,000 cents.
    return ((paidAmount * rate) + 50) ~/ 100;
  }

  int get _balanceAfter {
    final result = _selectedOutstanding - _appliedAmount;

    return result < 0 ? 0 : result;
  }

  Future<void> _loadNbcRate() async {
    if (!_needsConversion) {
      setState(() {
        _nbcRate = null;
        _rateError = null;
        _loadingRate = false;
      });

      return;
    }

    setState(() {
      _loadingRate = true;
      _rateError = null;
    });

    try {
      final rate = await ExchangeRateService.instance
          .fetchNbcRateForDate(
        _paymentDate,
      );

      if (!mounted) return;

      setState(() {
        _nbcRate = rate;
        _loadingRate = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _nbcRate = null;
        _loadingRate = false;
        _rateError =
            'Could not get the NBC rate for this date.';
      });
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null) return;

    setState(() {
      _paymentDate = selected;
    });

    if (_needsConversion) {
      await _loadNbcRate();
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _save() async {
    if (_paidAmount <= 0) {
      _showError(
        'Please enter a payment amount.',
      );

      return;
    }

    if (_needsConversion && _nbcRate == null) {
      _showError(
        'NBC exchange rate is required for this conversion.',
      );

      return;
    }

    if (_appliedAmount <= 0) {
      _showError(
        'The payment amount is invalid.',
      );

      return;
    }

    if (_appliedAmount > _selectedOutstanding) {
      _showError(
        'This payment is greater than the outstanding balance.',
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await PaymentService.instance.createPayment(
        customerId: widget.customer.id,
        customerName: widget.customer.name,
        paidCurrency: _paidCurrency,
        paidAmountMinor: _paidAmount,
        appliedCurrency: _appliedCurrency,
        appliedAmountMinor: _appliedAmount,

        exchangeRateKhrPerUsd:
            _needsConversion ? _nbcRate!.khrPerUsd : null,

        exchangeRateSource:
            _needsConversion ? _nbcRate!.source : null,

        exchangeRateDate:
            _needsConversion ? _nbcRate!.rateDate : null,

        exchangeRateFetchedAt:
            _needsConversion ? _nbcRate!.updatedAt : null,

        method: _method,
        paymentDate: _paymentDate,
        note: _noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment saved successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Could not save payment. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final balanceSegments =
        <ButtonSegment<MoneyCurrency>>[];

    if (widget.khrOutstanding > 0) {
      balanceSegments.add(
        ButtonSegment(
          value: MoneyCurrency.khr,
          label: Text(
            MoneyUtils.format(
              widget.khrOutstanding,
              MoneyCurrency.khr,
            ),
          ),
        ),
      );
    }

    if (widget.usdOutstanding > 0) {
      balanceSegments.add(
        ButtonSegment(
          value: MoneyCurrency.usd,
          label: Text(
            MoneyUtils.format(
              widget.usdOutstanding,
              MoneyCurrency.usd,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Record Payment',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            140,
          ),
          children: [
            Text(
              widget.customer.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 5),

            Text(
              'Record money received from this customer.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Paying which balance?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            SegmentedButton<MoneyCurrency>(
              segments: balanceSegments,
              selected: {
                _appliedCurrency,
              },
              onSelectionChanged: (selection) {
                setState(() {
                  _appliedCurrency = selection.first;

                  // Default to paying in the same currency.
                  _paidCurrency = _appliedCurrency;

                  _amountController.clear();
                  _nbcRate = null;
                  _rateError = null;
                });
              },
            ),

            const SizedBox(height: 26),

            const Text(
              'Customer paid in',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            SegmentedButton<MoneyCurrency>(
              segments: const [
                ButtonSegment(
                  value: MoneyCurrency.khr,
                  label: Text('KHR ៛'),
                ),
                ButtonSegment(
                  value: MoneyCurrency.usd,
                  label: Text('USD \$'),
                ),
              ],
              selected: {
                _paidCurrency,
              },
              onSelectionChanged: (selection) async {
                setState(() {
                  _paidCurrency = selection.first;
                  _amountController.clear();
                  _nbcRate = null;
                  _rateError = null;
                });

                if (_needsConversion) {
                  await _loadNbcRate();
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Amount received',
                hintText:
                    _paidCurrency == MoneyCurrency.khr
                        ? 'Example: 100000'
                        : 'Example: 25.00',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                ),
                prefixText:
                    _paidCurrency == MoneyCurrency.usd
                        ? '\$ '
                        : null,
                suffixText:
                    _paidCurrency == MoneyCurrency.khr
                        ? '៛'
                        : null,
              ),
            ),

            if (_needsConversion) ...[
              const SizedBox(height: 16),

              _NbcRateCard(
                loading: _loadingRate,
                rate: _nbcRate,
                error: _rateError,
                formatDate: _formatDate,
                onRefresh: _loadNbcRate,
              ),
            ],

            const SizedBox(height: 16),

            DropdownButtonFormField<PaymentMethodType>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              items: PaymentMethodType.values
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(
                        method.label,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _method = value;
                });
              },
            ),

            const SizedBox(height: 16),

            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment date',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                ),
                child: Text(
                  _formatDate(_paymentDate),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional',
                alignLabelWithHint: true,
                prefixIcon: Icon(
                  Icons.notes_rounded,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Received',
                    value: MoneyUtils.format(
                      _paidAmount,
                      _paidCurrency,
                    ),
                  ),

                  if (_needsConversion) ...[
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Applied to debt',
                      value: MoneyUtils.format(
                        _appliedAmount,
                        _appliedCurrency,
                      ),
                    ),
                  ],

                  const Divider(
                    height: 28,
                  ),

                  _SummaryRow(
                    label: 'Balance before',
                    value: MoneyUtils.format(
                      _selectedOutstanding,
                      _appliedCurrency,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SummaryRow(
                    label: 'Balance after',
                    value: MoneyUtils.format(
                      _balanceAfter,
                      _appliedCurrency,
                    ),
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomSheet: SafeArea(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                  ),
            label: Text(
              _saving
                  ? 'Saving...'
                  : 'Save payment',
            ),
          ),
        ),
      ),
    );
  }
}

class _NbcRateCard extends StatelessWidget {
  const _NbcRateCard({
    required this.loading,
    required this.rate,
    required this.error,
    required this.formatDate,
    required this.onRefresh,
  });

  final bool loading;
  final ExchangeRate? rate;
  final String? error;

  final String Function(DateTime) formatDate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Getting NBC exchange rate...',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(error!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (rate == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.currency_exchange_rounded,
                color: colors.onPrimaryContainer,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NBC official rate',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 USD = ${rate!.khrPerUsd} KHR',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Rate date: ${formatDate(rate!.rateDate)}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Refresh rate',
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight:
                strong ? FontWeight.w800 : FontWeight.w500,
          ),
        ),

        const Spacer(),

        Text(
          value,
          style: TextStyle(
            fontSize: strong ? 20 : 15,
            fontWeight:
                strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
