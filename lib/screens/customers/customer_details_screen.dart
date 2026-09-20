import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import '../payments/payment_form_screen.dart';
import '../receipts/sale_receipt_screen.dart';
import '../sales/sale_form_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _editCustomer(BuildContext context, Customer customer) async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );

    if (!context.mounted) {
      return;
    }

    if (result == 'deleted') {
      Navigator.pop(context, true);
    }
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
    final l10n = AppLocalizations.of(context)!;

    if (khrBalance <= 0 && usdBalance <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noOutstandingBalance)));

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
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isKhmer =
            Localizations.localeOf(dialogContext).languageCode == 'km';

        return AlertDialog(
          title: Text(
            l10n.archiveCustomerQuestion,
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
          content: Text(l10n.archiveCustomerMessage(customer.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.archive),
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

    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.customerRestored(customer.name))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {Customer? customer}) {
    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return AppBar(
      title: Text(
        l10n.customer,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: headingWeight),
      ),
      actions: [
        if (customer != null)
          IconButton(
            tooltip: l10n.editCustomer,
            onPressed: () {
              _editCustomer(context, customer);
            },
            icon: const Icon(AppIcons.edit, size: 21),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<Customer?>(
      stream: CustomerService.instance.watchCustomer(customerId),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: Center(child: Text(l10n.couldNotLoadCustomer)),
          );
        }

        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final customer = customerSnapshot.data;

        if (customer == null) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: Center(child: Text(l10n.customerNotFound)),
          );
        }

        return StreamBuilder<List<Sale>>(
          stream: SaleService.instance.watchSalesForCustomer(customer.id),
          builder: (context, saleSnapshot) {
            if (saleSnapshot.hasError) {
              return Scaffold(
                appBar: _buildAppBar(context, customer: customer),
                body: Center(child: Text(l10n.couldNotLoadSales)),
              );
            }

            if (!saleSnapshot.hasData) {
              return Scaffold(
                appBar: _buildAppBar(context, customer: customer),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final sales = saleSnapshot.data!;

            return StreamBuilder<List<CustomerPayment>>(
              stream: PaymentService.instance.watchPaymentsForCustomer(
                customer.id,
              ),
              builder: (context, paymentSnapshot) {
                if (paymentSnapshot.hasError) {
                  return Scaffold(
                    appBar: _buildAppBar(context, customer: customer),
                    body: Center(child: Text(l10n.couldNotLoadPayments)),
                  );
                }

                if (!paymentSnapshot.hasData) {
                  return Scaffold(
                    appBar: _buildAppBar(context, customer: customer),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                final payments = paymentSnapshot.data!;

                var khrBalance = 0;
                var usdBalance = 0;

                // --------------------------------
                // SALES ADD TO OUTSTANDING DEBT
                // --------------------------------

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

                // --------------------------------
                // PAYMENTS SUBTRACT FROM DEBT
                // --------------------------------

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
                  onEdit: () {
                    _editCustomer(context, customer);
                  },
                  onNewSale: () {
                    _newSale(context, customer);
                  },
                  onPayment: () {
                    _recordPayment(context, customer, khrBalance, usdBalance);
                  },
                  onArchive: () {
                    _archive(context, customer);
                  },
                  onRestore: () {
                    _restore(context, customer);
                  },
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final activities = <_ActivityItem>[];

    // --------------------------------
    // ACTIVE SALES
    // --------------------------------

    for (final sale in sales) {
      if (sale.status != 'active') {
        continue;
      }

      activities.add(_ActivityItem.sale(sale));
    }

    // --------------------------------
    // ACTIVE PAYMENTS
    // --------------------------------

    for (final payment in payments) {
      if (payment.status != 'active') {
        continue;
      }

      activities.add(_ActivityItem.payment(payment));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));

    final hasDebt = khrBalance > 0 || usdBalance > 0;

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          l10n.customer,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: headingWeight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.editCustomer,
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit, size: 21),
          ),
        ],
      ),

      // ====================================================
      // ONLY BODY SCROLLS
      // ====================================================
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
          children: [
            // =================================================
            // CUSTOMER
            // =================================================
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    customer.name.trim().isEmpty
                        ? '?'
                        : customer.name.trim()[0].toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    customer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: headingWeight,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =================================================
            // OUTSTANDING BALANCE
            // =================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.outstandingBalance,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.80),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (khrBalance > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyUtils.format(khrBalance, MoneyCurrency.khr),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  if (khrBalance > 0 && usdBalance > 0)
                    const SizedBox(height: 3),

                  if (usdBalance > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyUtils.format(usdBalance, MoneyCurrency.usd),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  if (!hasDebt)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyUtils.format(0, MoneyCurrency.khr),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 7),

                  Text(
                    hasDebt ? l10n.salesMinusPayments : l10n.customerFullyPaid,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =================================================
            // QUICK ACTIONS
            // =================================================
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: AppIcons.sale,
                    label: l10n.newSale,
                    onTap: onNewSale,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _ActionButton(
                    icon: AppIcons.payment,
                    label: l10n.payment,
                    onTap: onPayment,
                    enabled: hasDebt,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // =================================================
            // ACTIVITY
            // =================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activity,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: headingWeight,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  l10n.recordsCount(activities.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (activities.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(AppIcons.history, size: 34, color: colors.primary),

                    const SizedBox(height: 10),

                    Text(
                      l10n.noActivityYet,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      l10n.activityWillAppearHere,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityCard(activity: activity),
                ),
              ),

            const SizedBox(height: 18),

            // =================================================
            // CUSTOMER INFORMATION
            // =================================================
            Text(
              l10n.customerInformation,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: headingWeight,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _InfoTile(
                    icon: AppIcons.phone,
                    title: l10n.phone,
                    value: customer.phone.trim().isEmpty
                        ? l10n.notProvided
                        : customer.phone,
                  ),

                  const Divider(height: 1),

                  _InfoTile(
                    icon: AppIcons.note,
                    title: l10n.note,
                    value: customer.note.trim().isEmpty
                        ? l10n.noNote
                        : customer.note,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =================================================
            // ARCHIVE / RESTORE
            // =================================================
            if (customer.isArchived)
              FilledButton.icon(
                onPressed: onRestore,
                icon: const Icon(AppIcons.restore, size: 20),
                label: Text(l10n.restoreCustomer),
              )
            else
              OutlinedButton.icon(
                onPressed: onArchive,
                icon: const Icon(AppIcons.archive, size: 20),
                label: Text(l10n.archiveCustomer),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVITY MODEL
// ============================================================

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

// ============================================================
// ACTIVITY CARD
// ============================================================

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final _ActivityItem activity;

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _saleTitle(Sale sale, AppLocalizations l10n) {
    if (sale.items.isEmpty) {
      return l10n.sale;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    // ========================================================
    // SALE
    // ========================================================

    if (activity.isSale) {
      final sale = activity.sale!;

      final quantityText = _saleQuantitySummary(sale);

      return Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleReceiptScreen(saleId: sale.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    AppIcons.receipt,
                    size: 20,
                    color: colors.onPrimaryContainer,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _saleTitle(sale, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isKhmer
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          if (quantityText.isNotEmpty)
                            Flexible(
                              child: Text(
                                quantityText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),

                          if (quantityText.isNotEmpty)
                            Text(
                              ' • ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),

                          Text(
                            _formatDate(sale.saleDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '+${MoneyUtils.format(sale.totalMinor, sale.currency)}',
                      maxLines: 1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ========================================================
    // PAYMENT
    // ========================================================

    final payment = activity.payment!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              AppIcons.payment,
              size: 20,
              color: colors.onSecondaryContainer,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentReceived,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${_paymentMethodLabel(l10n, payment.method)} • '
                  '${_formatDate(payment.paymentDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                if (payment.paidCurrency != payment.appliedCurrency) ...[
                  const SizedBox(height: 2),

                  Text(
                    l10n.receivedAmount(
                      MoneyUtils.format(
                        payment.paidAmountMinor,
                        payment.paidCurrency,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '-${MoneyUtils.format(payment.appliedAmountMinor, payment.appliedCurrency)}',
                maxLines: 1,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: enabled
          ? colors.surfaceContainerLowest
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled ? colors.primary : colors.onSurfaceVariant,
              ),

              const SizedBox(height: 7),

              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: enabled ? null : colors.onSurfaceVariant,
                  fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER INFO TILE
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
