import 'package:flutter/material.dart';

import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
import '../../utils/money_utils.dart';
import '../receipts/sale_receipt_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onCustomersTap,
    required this.onNewSaleTap,
  });

  final VoidCallback onCustomersTap;
  final VoidCallback onNewSaleTap;

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sale>>(
      stream: SaleService.instance.watchAllSales(),
      builder: (context, saleSnapshot) {
        if (saleSnapshot.hasError) {
          return const _DashboardError(message: 'Could not load sales.');
        }

        if (!saleSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sales = saleSnapshot.data!;

        return StreamBuilder<List<CustomerPayment>>(
          stream: PaymentService.instance.watchAllPayments(),
          builder: (context, paymentSnapshot) {
            if (paymentSnapshot.hasError) {
              return const _DashboardError(message: 'Could not load payments.');
            }

            if (!paymentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final payments = paymentSnapshot.data!;

            var khrOutstanding = 0;
            var usdOutstanding = 0;

            var todaySalesKhr = 0;
            var todaySalesUsd = 0;

            var todayPaymentsKhr = 0;
            var todayPaymentsUsd = 0;

            for (final sale in sales) {
              if (sale.status != 'active') {
                continue;
              }

              if (sale.currency == MoneyCurrency.khr) {
                khrOutstanding += sale.totalMinor;

                if (_isToday(sale.saleDate)) {
                  todaySalesKhr += sale.totalMinor;
                }
              } else {
                usdOutstanding += sale.totalMinor;

                if (_isToday(sale.saleDate)) {
                  todaySalesUsd += sale.totalMinor;
                }
              }
            }

            for (final payment in payments) {
              if (payment.status != 'active') {
                continue;
              }

              if (payment.appliedCurrency == MoneyCurrency.khr) {
                khrOutstanding -= payment.appliedAmountMinor;
              } else {
                usdOutstanding -= payment.appliedAmountMinor;
              }

              if (_isToday(payment.paymentDate)) {
                if (payment.paidCurrency == MoneyCurrency.khr) {
                  todayPaymentsKhr += payment.paidAmountMinor;
                } else {
                  todayPaymentsUsd += payment.paidAmountMinor;
                }
              }
            }

            if (khrOutstanding < 0) {
              khrOutstanding = 0;
            }

            if (usdOutstanding < 0) {
              usdOutstanding = 0;
            }

            final activities = <_DashboardActivity>[];

            for (final sale in sales) {
              if (sale.status == 'active') {
                activities.add(_DashboardActivity.sale(sale));
              }
            }

            for (final payment in payments) {
              if (payment.status == 'active') {
                activities.add(_DashboardActivity.payment(payment));
              }
            }

            activities.sort((a, b) => b.date.compareTo(a.date));

            final recentActivities = activities.take(5).toList();

            return _DashboardContent(
              khrOutstanding: khrOutstanding,
              usdOutstanding: usdOutstanding,
              todaySalesKhr: todaySalesKhr,
              todaySalesUsd: todaySalesUsd,
              todayPaymentsKhr: todayPaymentsKhr,
              todayPaymentsUsd: todayPaymentsUsd,
              activities: recentActivities,
              onCustomersTap: onCustomersTap,
              onNewSaleTap: onNewSaleTap,
            );
          },
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.khrOutstanding,
    required this.usdOutstanding,
    required this.todaySalesKhr,
    required this.todaySalesUsd,
    required this.todayPaymentsKhr,
    required this.todayPaymentsUsd,
    required this.activities,
    required this.onCustomersTap,
    required this.onNewSaleTap,
  });

  final int khrOutstanding;
  final int usdOutstanding;

  final int todaySalesKhr;
  final int todaySalesUsd;

  final int todayPaymentsKhr;
  final int todayPaymentsUsd;

  final List<_DashboardActivity> activities;

  final VoidCallback onCustomersTap;
  final VoidCallback onNewSaleTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // Fixed header.
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MomBiz',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Business overview',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable dashboard content.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding customer debt',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.78),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        MoneyUtils.format(khrOutstanding, MoneyCurrency.khr),
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      if (usdOutstanding > 0) ...[
                        const SizedBox(height: 5),
                        Text(
                          MoneyUtils.format(usdOutstanding, MoneyCurrency.usd),
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      Text(
                        khrOutstanding == 0 && usdOutstanding == 0
                            ? 'No outstanding customer debt.'
                            : 'Across all customers',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _TodayCard(
                        icon: Icons.trending_up_rounded,
                        title: 'Sales today',
                        khr: todaySalesKhr,
                        usd: todaySalesUsd,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _TodayCard(
                        icon: Icons.payments_outlined,
                        title: 'Received today',
                        khr: todayPaymentsKhr,
                        usd: todayPaymentsUsd,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Text(
                  'Quick actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_shopping_cart_rounded,
                        title: 'New sale',
                        onTap: onNewSaleTap,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _QuickAction(
                        icon: Icons.people_alt_outlined,
                        title: 'Customers',
                        onTap: onCustomersTap,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (activities.isNotEmpty)
                      Text(
                        'Latest ${activities.length}',
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
                            Icons.receipt_long_outlined,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.title,
    required this.khr,
    required this.usd,
  });

  final IconData icon;
  final String title;
  final int khr;
  final int usd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: colors.onPrimaryContainer),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),

            const SizedBox(height: 6),

            Text(
              MoneyUtils.format(khr, MoneyCurrency.khr),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),

            if (usd > 0) ...[
              const SizedBox(height: 3),
              Text(
                MoneyUtils.format(usd, MoneyCurrency.usd),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: colors.primary, size: 27),
              const SizedBox(height: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActivity {
  const _DashboardActivity({required this.date, this.sale, this.payment});

  final DateTime date;
  final Sale? sale;
  final CustomerPayment? payment;

  factory _DashboardActivity.sale(Sale sale) {
    return _DashboardActivity(date: sale.saleDate, sale: sale);
  }

  factory _DashboardActivity.payment(CustomerPayment payment) {
    return _DashboardActivity(date: payment.paymentDate, payment: payment);
  }

  bool get isSale => sale != null;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final _DashboardActivity activity;

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}';
  }

  String _saleItems(Sale sale) {
    if (sale.items.isEmpty) {
      return 'Sale';
    }

    return sale.items
        .map((item) {
          final unit = item.unit.trim();

          if (unit.isEmpty) {
            return '${item.productName} ${item.quantity}';
          }

          return '${item.productName} ${item.quantity} $unit';
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
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleReceiptScreen(saleId: sale.id),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: colors.primaryContainer,
            child: Icon(
              Icons.receipt_long_outlined,
              color: colors.onPrimaryContainer,
            ),
          ),
          title: Text(
            sale.customerName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  _saleItems(sale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _date(sale.saleDate),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          trailing: Text(
            '+${MoneyUtils.format(sale.totalMinor, sale.currency)}',
            style: TextStyle(color: colors.error, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    final payment = activity.payment!;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          child: Icon(
            Icons.payments_outlined,
            color: colors.onSecondaryContainer,
          ),
        ),
        title: Text(
          payment.customerName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${payment.method.label} • '
          '${_date(payment.paymentDate)}',
        ),
        trailing: Text(
          '-${MoneyUtils.format(payment.appliedAmountMinor, payment.appliedCurrency)}',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
