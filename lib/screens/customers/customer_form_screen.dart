import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

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

  bool get _isEditing => widget.customer != null;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editCustomer : l10n.newCustomer,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            children: [
              // -----------------------
              // CUSTOMER NAME
              // -----------------------
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofocus: !_isEditing,
                decoration: InputDecoration(
                  labelText: l10n.customerName,
                  hintText: l10n.exampleDara,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCustomerName;
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // -----------------------
              // PHONE
              // -----------------------
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: l10n.optional,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 14),

              // -----------------------
              // NOTE
              // -----------------------
              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: l10n.note,
                  hintText: l10n.optionalCustomerInformation,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
      ),

      // -----------------------
      // SAVE BUTTON
      // -----------------------
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
                : Icon(
                    _isEditing
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
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
      ),
    );
  }
}
