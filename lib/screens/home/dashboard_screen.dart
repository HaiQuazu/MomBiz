import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Sale>>(
      stream: SaleService.instance.watchAllSales(),
      builder: (context, saleSnapshot) {
        if (saleSnapshot.hasError) {
          return _DashboardError(message: l10n.couldNotLoadSales);
        }

        if (!saleSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sales = saleSnapshot.data!;

        return StreamBuilder<List<CustomerPayment>>(
          stream: PaymentService.instance.watchAllPayments(),
          builder: (context, paymentSnapshot) {
            if (paymentSnapshot.hasError) {
              return _DashboardError(message: l10n.couldNotLoadPayments);
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

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        l10n.businessOverview,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: colors.onPrimaryContainer,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.outstandingCustomerDebt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.82),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        MoneyUtils.format(khrOutstanding, MoneyCurrency.khr),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),

                      if (usdOutstanding > 0) ...[
                        const SizedBox(height: 3),

                        Text(
                          MoneyUtils.format(usdOutstanding, MoneyCurrency.usd),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],

                      const SizedBox(height: 7),

                      Text(
                        khrOutstanding == 0 && usdOutstanding == 0
                            ? l10n.noOutstandingDebt
                            : l10n.acrossAllCustomers,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _TodayCard(
                        icon: Icons.trending_up_rounded,
                        title: l10n.salesToday,
                        khr: todaySalesKhr,
                        usd: todaySalesUsd,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _TodayCard(
                        icon: Icons.payments_outlined,
                        title: l10n.receivedToday,
                        khr: todayPaymentsKhr,
                        usd: todayPaymentsUsd,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text(
                  l10n.quickActions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_shopping_cart_rounded,
                        title: l10n.newSale,
                        onTap: onNewSaleTap,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _QuickAction(
                        icon: Icons.people_alt_outlined,
                        title: l10n.customers,
                        onTap: onCustomersTap,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recentActivity,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (activities.isNotEmpty)
                      Text(
                        l10n.latestCount(activities.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 9),

                if (activities.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 38,
                            color: colors.primary,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            l10n.noActivityYet,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            l10n.activityWillAppearHere,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),

            const SizedBox(height: 4),

            Text(
              MoneyUtils.format(khr, MoneyCurrency.khr),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            if (usd > 0) ...[
              const SizedBox(height: 2),

              Text(
                MoneyUtils.format(usd, MoneyCurrency.usd),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: colors.primary, size: 26),

              const SizedBox(height: 7),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
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
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _saleItems(Sale sale, AppLocalizations l10n) {
    if (sale.items.isEmpty) {
      return l10n.sale;
    }

    return sale.items
        .map((item) {
          final unit = item.unit.trim();

          if (unit.isEmpty) {
            return '${item.productName} '
                '${item.quantity}';
          }

          return '${item.productName} '
              '${item.quantity} '
              '$unit';
        })
        .join(' • ');
  }

  String _paymentMethodLabel(AppLocalizations l10n, CustomerPayment payment) {
    switch (payment.method.label) {
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
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    if (activity.isSale) {
      final sale = activity.sale!;

      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 70,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleReceiptScreen(saleId: sale.id),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 21,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: colors.onPrimaryContainer,
            ),
          ),
          title: Text(
            sale.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${_saleItems(sale, l10n)} • ${_date(sale.saleDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          trailing: Text(
            '+${MoneyUtils.format(sale.totalMinor, sale.currency)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final payment = activity.payment!;

    return Card(
      child: ListTile(
        minTileHeight: 70,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        leading: CircleAvatar(
          radius: 21,
          backgroundColor: colors.secondaryContainer,
          child: Icon(
            Icons.payments_outlined,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
        ),
        title: Text(
          payment.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_paymentMethodLabel(l10n, payment)} • ${_date(payment.paymentDate)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        trailing: Text(
          '-${MoneyUtils.format(payment.appliedAmountMinor, payment.appliedCurrency)}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
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
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 46, color: colors.error),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
