import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../services/customer_service.dart';
import 'customer_form_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  final Customer customer;

  Future<void> _editCustomer(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(
          customer: customer,
        ),
      ),
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _archiveCustomer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive Customer?'),
          content: Text(
            '${customer.name} will be hidden from the active customer list.\n\n'
            'Their future sales and payment history will still be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await CustomerService.instance.archiveCustomer(customer.id);

      if (!context.mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not archive customer: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            tooltip: 'Edit customer',
            onPressed: () => _editCustomer(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              customer.name.isEmpty
                  ? '?'
                  : customer.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            customer.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (customer.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              customer.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
              ),
            ),
          ],

          const SizedBox(height: 28),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Phone',
                    value: customer.phone.isEmpty
                        ? 'Not provided'
                        : customer.phone,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Note',
                    value: customer.note.isEmpty
                        ? 'No note'
                        : customer.note,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Outstanding debt',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sales and payment history will appear here later.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: () => _archiveCustomer(context),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Customer'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
