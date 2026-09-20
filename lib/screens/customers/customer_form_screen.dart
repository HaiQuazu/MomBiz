import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../theme/app_icons.dart';

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

    _noteController = TextEditingController(text: widget.customer?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  String _text({required String en, required String km}) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return languageCode == 'km' ? km : en;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await CustomerService.instance.updateCustomer(
          customerId: widget.customer!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          note: _noteController.text,
        );
      } else {
        await CustomerService.instance.addCustomer(
          name: _nameController.text,
          phone: _phoneController.text,
          note: _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
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
            final colors = Theme.of(dialogContext).colorScheme;

            final isKhmer =
                Localizations.localeOf(dialogContext).languageCode == 'km';

            return AlertDialog(
              icon: Icon(AppIcons.archive, color: colors.primary),
              title: Text(
                _text(
                  en: 'Cannot delete this customer',
                  km: 'មិនអាចលុបអតិថិជននេះបានទេ',
                ),
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                  fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
              content: Text(
                _text(
                  en: 'This customer has sales, payments, or chick reservation history.\n\nTo keep your business records and receipts safe, archive the customer instead.',
                  km: 'អតិថិជននេះមានប្រវត្តិការលក់ ការទូទាត់ ឬការកក់កូនមាន់។\n\nដើម្បីរក្សាទុកប្រវត្តិអាជីវកម្ម និងវិក្កយបត្រឱ្យមានសុវត្ថិភាព សូមទុកអតិថិជននេះក្នុងបណ្ណសារជំនួសវិញ។',
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

          final isKhmer =
              Localizations.localeOf(dialogContext).languageCode == 'km';

          return AlertDialog(
            icon: Icon(AppIcons.delete, color: colors.error),
            title: Text(
              _text(
                en: 'Delete customer permanently?',
                km: 'លុបអតិថិជននេះជាអចិន្ត្រៃយ៍?',
              ),
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
            content: Text(
              _text(
                en: '${customer.name} has no business history, so they can be deleted safely.\n\nThis cannot be undone.',
                km: '${customer.name} មិនមានប្រវត្តិអាជីវកម្មទេ ដូច្នេះអាចលុបបាន។\n\nសកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
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
              km: 'មិនអាចលុបអតិថិជនបានទេ។',
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final pageTitleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editCustomer : l10n.newCustomer,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: pageTitleWeight,
          ),
        ),
      ),

      // ====================================================
      // SCROLLABLE BODY
      // ====================================================
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
            children: [
              // ------------------------------------------------
              // NAME
              // ------------------------------------------------
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

              // ------------------------------------------------
              // PHONE
              // ------------------------------------------------
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

              const SizedBox(height: 14),

              // ------------------------------------------------
              // NOTE
              // ------------------------------------------------
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

      // ====================================================
      // FIXED ACTION AREA
      // ====================================================
      bottomSheet: SafeArea(
        top: false,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --------------------------------------------
                // SAVE / ADD CUSTOMER
                // --------------------------------------------
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

                // --------------------------------------------
                // DELETE
                // --------------------------------------------
                if (_isEditing) ...[
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(
                          color: colors.error.withValues(alpha: 0.45),
                        ),
                      ),
                      onPressed: _busy ? null : _deleteCustomer,
                      icon: _checkingDelete || _deleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.error,
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
