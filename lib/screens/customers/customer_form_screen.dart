import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import '../../utils/riel_input_formatter.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _openingDebtKhrController;
  late final TextEditingController _openingDebtUsdController;
  late final TextEditingController _noteController;

  bool _saving = false;
  bool _checkingDelete = false;
  bool _deleting = false;

  bool get _isEditing => widget.customer != null;

  bool get _busy => _saving || _checkingDelete || _deleting;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.customer?.name ?? '');

    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );

    final customer = widget.customer;

    _openingDebtKhrController = TextEditingController(
      text: customer != null && customer.openingDebtKhrMinor > 0
          ? MoneyUtils.formatRielInput(customer.openingDebtKhrMinor)
          : '',
    );

    _openingDebtUsdController = TextEditingController(
      text: customer != null && customer.openingDebtUsdMinor > 0
          ? _editableUsd(customer.openingDebtUsdMinor)
          : '',
    );

    _noteController = TextEditingController(text: widget.customer?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingDebtKhrController.dispose();
    _openingDebtUsdController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  String _text({required String en, required String km}) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return languageCode == 'km' ? km : en;
  }

  String _editableUsd(int amountMinor) {
    final dollars = amountMinor ~/ 100;
    final cents = amountMinor % 100;

    if (cents == 0) {
      return dollars.toString();
    }

    return '$dollars.${cents.toString().padLeft(2, '0')}';
  }

  int? _openingDebtValue(
    TextEditingController controller,
    MoneyCurrency currency,
  ) {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return 0;
    }

    return MoneyUtils.parse(text, currency);
  }

  String? _validateOpeningDebt(String? value, MoneyCurrency currency) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final parsed = MoneyUtils.parse(text, currency);

    if (parsed == null || parsed < 0) {
      return _text(
        en: currency == MoneyCurrency.khr
            ? 'Enter a valid whole KHR amount.'
            : 'Enter a valid USD amount.',
        km: currency == MoneyCurrency.khr
            ? 'សូមបញ្ចូលចំនួនប្រាក់រៀលជាចំនួនគត់ត្រឹមត្រូវ'
            : 'សូមបញ្ចូលចំនួនប្រាក់ដុល្លារត្រឹមត្រូវ',
      );
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final openingDebtKhrMinor = _openingDebtValue(
      _openingDebtKhrController,
      MoneyCurrency.khr,
    );
    final openingDebtUsdMinor = _openingDebtValue(
      _openingDebtUsdController,
      MoneyCurrency.usd,
    );

    if (openingDebtKhrMinor == null ||
        openingDebtKhrMinor < 0 ||
        openingDebtUsdMinor == null ||
        openingDebtUsdMinor < 0) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? createdCustomerId;

      if (_isEditing) {
        await CustomerService.instance.updateCustomer(
          customerId: widget.customer!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          note: _noteController.text,
          openingDebtKhrMinor: openingDebtKhrMinor,
          openingDebtUsdMinor: openingDebtUsdMinor,
        );
      } else {
        createdCustomerId = await CustomerService.instance.addCustomer(
          name: _nameController.text,
          phone: _phoneController.text,
          note: _noteController.text,
          openingDebtKhrMinor: openingDebtKhrMinor,
          openingDebtUsdMinor: openingDebtUsdMinor,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, createdCustomerId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotSaveCustomer)));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final customer = widget.customer;

    if (customer == null || _busy) {
      return;
    }

    setState(() {
      _checkingDelete = true;
    });

    try {
      final check = await CustomerService.instance.checkDeleteCustomer(
        customer.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingDelete = false;
      });

      if (!check.canDelete) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              icon: Icon(
                AppIcons.archive,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              title: Text(
                _text(
                  en: 'Cannot delete this customer',
                  km: 'មិនអាចលុបអតិថិជននេះបានទេ',
                ),
              ),
              content: Text(
                _text(
                  en: 'This customer has sales, payments, chick reservation history, or an existing debt balance.\n\nTo keep your business records and receipts safe, archive the customer instead.',
                  km: 'អតិថិជននេះមានប្រវត្តិការលក់ ការទូទាត់ ការកក់កូនមាន់ ឬមានបំណុលចាស់\n\nដើម្បីរក្សាទុកប្រវត្តិអាជីវកម្ម និងវិក្កយបត្រឱ្យមានសុវត្ថិភាព សូមទុកអតិថិជននេះក្នុងបណ្ណសារជំនួសវិញ',
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(_text(en: 'OK', km: 'យល់ព្រម')),
                ),
              ],
            );
          },
        );

        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            icon: Icon(AppIcons.delete, color: colors.error),
            title: Text(
              _text(
                en: 'Delete customer permanently?',
                km: 'លុបអតិថិជននេះជាអចិន្ត្រៃយ៍?',
              ),
            ),
            content: Text(
              _text(
                en: '${customer.name} has no business history, so they can be deleted safely.\n\nThis cannot be undone.',
                km: '${customer.name} មិនមានប្រវត្តិអាជីវកម្មទេ ដូច្នេះអាចលុបបាន\n\nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(AppIcons.delete, size: 20),
                label: Text(
                  _text(en: 'Delete permanently', km: 'លុបជាអចិន្ត្រៃយ៍'),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() {
        _deleting = true;
      });

      await CustomerService.instance.deleteCustomer(customer.id);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, 'deleted');
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Could not delete customer.',
              km: 'មិនអាចលុបអតិថិជនបានទេ',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingDelete = false;
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final pageTitleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final bottomSystemInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;

    final actionBottomPadding =
        keyboardOpen ? 12.0 : 12.0 + bottomSystemInset;

    final bodyBottomPadding =
        (_isEditing ? 150.0 : 100.0) + keyboardInset;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editCustomer : l10n.newCustomer,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: pageTitleWeight),
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              bodyBottomPadding,
            ),
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofocus: !_isEditing,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.customerName,
                  hintText: l10n.exampleDara,
                  prefixIcon: const Icon(AppIcons.customer, size: 21),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCustomerName;
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: l10n.optional,
                  prefixIcon: const Icon(AppIcons.phone, size: 21),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                _text(
                  en: 'Existing debt before MomBiz',
                  km: 'បំណុលចាស់មុនប្រើ MomBiz',
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _text(
                  en: 'Enter only money this customer already owed before you started recording sales in MomBiz. Leave blank if there is no old debt.',
                  km: 'បញ្ចូលតែប្រាក់ដែលអតិថិជននេះបានជំពាក់មុនពេលចាប់ផ្តើមកត់ត្រាការលក់ក្នុង MomBiz បើមិនមានបំណុលចាស់ សូមទុកទទេ',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _openingDebtKhrController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: _text(
                    en: 'Old debt (KHR)',
                    km: 'បំណុលចាស់ (រៀល)',
                  ),
                  hintText: '100,000',
                  prefixIcon: const Icon(AppIcons.payment, size: 21),
                  suffixText: 'រៀល',
                ),
                inputFormatters: const [RielInputFormatter()],
                validator: (value) =>
                    _validateOpeningDebt(value, MoneyCurrency.khr),
              ),

              const SizedBox(height: 22),

              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: l10n.note,
                  hintText: l10n.optionalCustomerInformation,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(AppIcons.note, size: 21),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomSheet: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              actionBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isEditing ? AppIcons.check : AppIcons.customerAdd,
                            size: 20,
                          ),
                    label: Text(
                      _saving
                          ? '${l10n.save}...'
                          : _isEditing
                          ? l10n.saveChanges
                          : l10n.addCustomer,
                    ),
                  ),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.errorContainer,
                        foregroundColor: colors.onErrorContainer,
                      ),
                      onPressed: _busy ? null : _deleteCustomer,
                      icon: _checkingDelete || _deleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onErrorContainer,
                              ),
                            )
                          : const Icon(AppIcons.delete, size: 20),
                      label: Text(
                        _checkingDelete
                            ? _text(en: 'Checking...', km: 'កំពុងពិនិត្យ...')
                            : _deleting
                            ? _text(en: 'Deleting...', km: 'កំពុងលុប...')
                            : _text(en: 'Delete customer', km: 'លុបអតិថិជន'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
