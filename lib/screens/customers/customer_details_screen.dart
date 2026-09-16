import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
import '../../utils/money_utils.dart';
import '../payments/payment_form_screen.dart';
import '../sales/sale_form_screen.dart';
import 'customer_form_screen.dart';
import '../receipts/sale_receipt_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _editCustomer(BuildContext context, Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );
  }

  Future<void> _newSale(BuildContext context, Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleFormScreen(initialCustomerId: customer.id),
      ),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    Customer customer,
    int khrBalance,
    int usdBalance,
  ) async {
    if (khrBalance <= 0 && usdBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This customer has no outstanding balance.'),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormScreen(
          customer: customer,
          khrOutstanding: khrBalance,
          usdOutstanding: usdBalance,
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive customer?'),
          content: Text(
            '${customer.name} will be hidden from active customers.\n\n'
            'Their sales and payments will remain safe.',
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

    await CustomerService.instance.archiveCustomer(customer.id);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _restore(BuildContext context, Customer customer) async {
    await CustomerService.instance.restoreCustomer(customer.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${customer.name} restored.')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Customer?>(
      stream: CustomerService.instance.watchCustomer(customerId),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load customer.')),
          );
        }

        if (!customerSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final customer = customerSnapshot.data;

        if (customer == null) {
          return const Scaffold(
            body: Center(child: Text('Customer not found.')),
          );
        }

        return StreamBuilder<List<Sale>>(
          stream: SaleService.instance.watchSalesForCustomer(customer.id),
          builder: (context, saleSnapshot) {
            if (saleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Could not load sales.')),
              );
            }

            if (!saleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final sales = saleSnapshot.data!;

            return StreamBuilder<List<CustomerPayment>>(
              stream: PaymentService.instance.watchPaymentsForCustomer(
                customer.id,
              ),
              builder: (context, paymentSnapshot) {
                if (paymentSnapshot.hasError) {
                  return const Scaffold(
                    body: Center(child: Text('Could not load payments.')),
                  );
                }

                if (!paymentSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final payments = paymentSnapshot.data!;

                var khrBalance = 0;
                var usdBalance = 0;

                for (final sale in sales) {
                  if (sale.status != 'active') {
                    continue;
                  }

                  if (sale.currency == MoneyCurrency.khr) {
                    khrBalance += sale.totalMinor;
                  } else {
                    usdBalance += sale.totalMinor;
                  }
                }

                for (final payment in payments) {
                  if (payment.status != 'active') {
                    continue;
                  }

                  if (payment.appliedCurrency == MoneyCurrency.khr) {
                    khrBalance -= payment.appliedAmountMinor;
                  } else {
                    usdBalance -= payment.appliedAmountMinor;
                  }
                }

                if (khrBalance < 0) {
                  khrBalance = 0;
                }

                if (usdBalance < 0) {
                  usdBalance = 0;
                }

                return _CustomerDetailsContent(
                  customer: customer,
                  sales: sales,
                  payments: payments,
                  khrBalance: khrBalance,
                  usdBalance: usdBalance,
                  onEdit: () => _editCustomer(context, customer),
                  onNewSale: () => _newSale(context, customer),
                  onPayment: () =>
                      _recordPayment(context, customer, khrBalance, usdBalance),
                  onArchive: () => _archive(context, customer),
                  onRestore: () => _restore(context, customer),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CustomerDetailsContent extends StatelessWidget {
  const _CustomerDetailsContent({
    required this.customer,
    required this.sales,
    required this.payments,
    required this.khrBalance,
    required this.usdBalance,
    required this.onEdit,
    required this.onNewSale,
    required this.onPayment,
    required this.onArchive,
    required this.onRestore,
  });

  final Customer customer;
  final List<Sale> sales;
  final List<CustomerPayment> payments;

  final int khrBalance;
  final int usdBalance;

  final VoidCallback onEdit;
  final VoidCallback onNewSale;
  final VoidCallback onPayment;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final activities = <_ActivityItem>[];

    for (final sale in sales) {
      if (sale.status != 'active') {
        continue;
      }

      activities.add(_ActivityItem.sale(sale));
    }

    for (final payment in payments) {
      if (payment.status != 'active') {
        continue;
      }

      activities.add(_ActivityItem.payment(payment));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));

    final hasDebt = khrBalance > 0 || usdBalance > 0;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit customer',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      customer.phone.isEmpty
                          ? 'No phone number'
                          : customer.phone,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding balance',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  MoneyUtils.format(khrBalance, MoneyCurrency.khr),
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (usdBalance > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    MoneyUtils.format(usdBalance, MoneyCurrency.usd),
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  hasDebt
                      ? 'Sales minus payments'
                      : 'This customer is fully paid.',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'New sale',
                  onTap: onNewSale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Payment',
                  onTap: onPayment,
                  enabled: hasDebt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${activities.length} records',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (activities.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 42,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No activity yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Sales and payments will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityCard(activity: activity),
              ),
            ),

          const SizedBox(height: 18),

          Text(
            'Customer information',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: customer.phone.isEmpty
                      ? 'Not provided'
                      : customer.phone,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.notes_outlined,
                  title: 'Note',
                  value: customer.note.isEmpty ? 'No note' : customer.note,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          if (customer.isArchived)
            FilledButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restore customer'),
            )
          else
            OutlinedButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive customer'),
            ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({required this.date, this.sale, this.payment});

  final DateTime date;
  final Sale? sale;
  final CustomerPayment? payment;

  factory _ActivityItem.sale(Sale sale) {
    return _ActivityItem(date: sale.saleDate, sale: sale);
  }

  factory _ActivityItem.payment(CustomerPayment payment) {
    return _ActivityItem(date: payment.paymentDate, payment: payment);
  }

  bool get isSale => sale != null;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final _ActivityItem activity;

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _saleTitle(Sale sale) {
    if (sale.items.isEmpty) {
      return 'Sale';
    }

    return sale.items.map((item) => item.productName).join(' • ');
  }

  String _saleQuantitySummary(Sale sale) {
    if (sale.items.isEmpty) {
      return '';
    }

    return sale.items
        .map((item) {
          final unit = item.unit.trim();

          if (unit.isEmpty) {
            return '${item.quantity}';
          }

          return '${item.quantity} $unit';
        })
        .join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (activity.isSale) {
      final sale = activity.sale!;

      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleReceiptScreen(saleId: sale.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
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
                    Icons.receipt_long_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _saleTitle(sale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _saleQuantitySummary(sale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            _formatDate(sale.saleDate),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                  '+${MoneyUtils.format(sale.totalMinor, sale.currency)}',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payment = activity.payment!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.payments_outlined,
                color: colors.onSecondaryContainer,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment received',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${payment.method.label} • '
                    '${_formatDate(payment.paymentDate)}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  if (payment.paidCurrency != payment.appliedCurrency) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Received '
                      '${MoneyUtils.format(payment.paidAmountMinor, payment.paidCurrency)}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            Text(
              '-${MoneyUtils.format(payment.appliedAmountMinor, payment.appliedCurrency)}',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: enabled
          ? colors.surfaceContainerLowest
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: enabled ? null : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
