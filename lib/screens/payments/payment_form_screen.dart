import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
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
    return MoneyUtils.parse(_amountController.text, _paidCurrency) ?? 0;
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
    if (_paidCurrency == MoneyCurrency.khr &&
        _appliedCurrency == MoneyCurrency.usd) {
      return ((paidAmount * 100) + (rate ~/ 2)) ~/ rate;
    }

    // Customer paid USD toward KHR debt.
    // USD is stored as cents.
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
      final rate = await ExchangeRateService.instance.fetchNbcRateForDate(
        _paymentDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nbcRate = rate;
        _loadingRate = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _nbcRate = null;
        _loadingRate = false;
        _rateError = l10n.couldNotGetNbcRateForDate;
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

    if (selected == null || !mounted) {
      return;
    }

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

  String _paymentMethodLabel(AppLocalizations l10n, PaymentMethodType method) {
    switch (method.label) {
      case 'Cash':
        return l10n.cash;

      case 'ABA QR':
        return l10n.abaQr;

      case 'ACLEDA QR':
        return l10n.acledaQr;

      default:
        return l10n.other;
    }
  }

  IconData _paymentMethodIcon(PaymentMethodType method) {
    switch (method.label) {
      case 'Cash':
        return Icons.payments_outlined;

      case 'ABA QR':
        return Icons.qr_code_2_rounded;

      case 'ACLEDA QR':
        return Icons.qr_code_2_rounded;

      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Future<void> _pickPaymentMethod() async {
    final l10n = AppLocalizations.of(context)!;

    final selected = await showModalBottomSheet<PaymentMethodType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.paymentMethod,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 14),

                ...PaymentMethodType.values.map((method) {
                  final isSelected = method == _method;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? colors.primaryContainer.withValues(alpha: 0.7)
                          : colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext, method);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  _paymentMethodIcon(method),
                                  size: 21,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  _paymentMethodLabel(l10n, method),
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),

                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: colors.primary,
                                )
                              else
                                const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _method = selected;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_paidAmount <= 0) {
      _showError(l10n.pleaseEnterPaymentAmount);
      return;
    }

    if (_needsConversion && _nbcRate == null) {
      _showError(l10n.nbcRateRequiredForConversion);
      return;
    }

    if (_appliedAmount <= 0) {
      _showError(l10n.paymentAmountInvalid);
      return;
    }

    if (_appliedAmount > _selectedOutstanding) {
      _showError(l10n.paymentGreaterThanBalance);
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

        exchangeRateKhrPerUsd: _needsConversion ? _nbcRate!.khrPerUsd : null,

        exchangeRateSource: _needsConversion ? _nbcRate!.source : null,

        exchangeRateDate: _needsConversion ? _nbcRate!.rateDate : null,

        exchangeRateFetchedAt: _needsConversion ? _nbcRate!.updatedAt : null,

        method: _method,

        paymentDate: _paymentDate,

        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paymentSavedSuccessfully)));

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(l10n.couldNotSavePayment);
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

    final l10n = AppLocalizations.of(context)!;

    final balanceSegments = <ButtonSegment<MoneyCurrency>>[];

    if (widget.khrOutstanding > 0) {
      balanceSegments.add(
        ButtonSegment(
          value: MoneyCurrency.khr,
          label: Text(
            MoneyUtils.format(widget.khrOutstanding, MoneyCurrency.khr),
          ),
        ),
      );
    }

    if (widget.usdOutstanding > 0) {
      balanceSegments.add(
        ButtonSegment(
          value: MoneyCurrency.usd,
          label: Text(
            MoneyUtils.format(widget.usdOutstanding, MoneyCurrency.usd),
          ),
        ),
      );
    }

    // Safety fallback.
    if (balanceSegments.isEmpty) {
      balanceSegments.add(
        ButtonSegment(
          value: _appliedCurrency,
          label: Text(MoneyUtils.format(0, _appliedCurrency)),
        ),
      );
    }

    final compactSegmentStyle = ButtonStyle(
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.recordPayment,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            // -----------------------
            // CUSTOMER
            // -----------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      widget.customer.name.trim().isEmpty
                          ? '?'
                          : widget.customer.name.trim()[0].toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          l10n.recordMoneyReceived,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------
            // COMPACT CURRENCY CARD
            // -----------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _CompactChoiceRow(
                    label: l10n.payingWhichBalance,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<MoneyCurrency>(
                        style: compactSegmentStyle,
                        segments: balanceSegments,
                        selected: {_appliedCurrency},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _appliedCurrency = selection.first;

                            _paidCurrency = _appliedCurrency;

                            _amountController.clear();

                            _nbcRate = null;

                            _rateError = null;
                          });
                        },
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),

                  _CompactChoiceRow(
                    label: l10n.customerPaidIn,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<MoneyCurrency>(
                        style: compactSegmentStyle,
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
                        selected: {_paidCurrency},
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
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------
            // AMOUNT
            // -----------------------
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: l10n.amountReceived,
                hintText: _paidCurrency == MoneyCurrency.khr
                    ? l10n.example100000
                    : l10n.example2500,
                prefixIcon: const Icon(Icons.payments_outlined),
                prefixText: _paidCurrency == MoneyCurrency.usd ? '\$ ' : null,
                suffixText: _paidCurrency == MoneyCurrency.khr ? '៛' : null,
              ),
            ),

            if (_needsConversion) ...[
              const SizedBox(height: 14),

              _NbcRateCard(
                loading: _loadingRate,
                rate: _nbcRate,
                error: _rateError,
                formatDate: _formatDate,
                onRefresh: _loadNbcRate,
              ),
            ],

            const SizedBox(height: 14),

            // -----------------------
            // PAYMENT METHOD
            // -----------------------
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickPaymentMethod,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.paymentMethod,
                  prefixIcon: Icon(_paymentMethodIcon(_method)),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                child: Text(
                  _paymentMethodLabel(l10n, _method),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------
            // DATE
            // -----------------------
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.paymentDate,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_formatDate(_paymentDate)),
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------
            // NOTE
            // -----------------------
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.note,
                hintText: l10n.optional,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------
            // SUMMARY
            // -----------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: l10n.received,
                    value: MoneyUtils.format(_paidAmount, _paidCurrency),
                  ),

                  if (_needsConversion) ...[
                    const SizedBox(height: 10),

                    _SummaryRow(
                      label: l10n.appliedToDebt,
                      value: MoneyUtils.format(
                        _appliedAmount,
                        _appliedCurrency,
                      ),
                    ),
                  ],

                  const Divider(height: 26),

                  _SummaryRow(
                    label: l10n.balanceBefore,
                    value: MoneyUtils.format(
                      _selectedOutstanding,
                      _appliedCurrency,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _SummaryRow(
                    label: l10n.balanceAfter,
                    value: MoneyUtils.format(_balanceAfter, _appliedCurrency),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? l10n.saving : l10n.savePayment),
          ),
        ),
      ),
    );
  }
}

class _CompactChoiceRow extends StatelessWidget {
  const _CompactChoiceRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Align(alignment: Alignment.centerRight, child: child),
        ),
      ],
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

    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

            const SizedBox(width: 12),

            Expanded(child: Text(l10n.gettingNbcRate)),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: colors.error),

                const SizedBox(width: 10),

                Expanded(child: Text(error!)),
              ],
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    if (rate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.currency_exchange_rounded,
              size: 22,
              color: colors.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nbcOfficialRate,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 3),

                Text(
                  l10n.oneUsdEqualsKhr(rate!.khrPerUsd),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  l10n.effectiveDateValue(formatDate(rate!.rateDate)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: l10n.refreshRate,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
        Expanded(
          child: Text(
            label,
            style:
                (strong
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                    ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          value,
          style:
              (strong
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
                  ),
        ),
      ],
    );
  }
}
