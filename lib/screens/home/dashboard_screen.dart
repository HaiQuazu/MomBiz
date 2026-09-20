import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
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

            // =================================================
            // SALES
            // =================================================

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

            // =================================================
            // PAYMENTS
            // =================================================

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

            // =================================================
            // RECENT ACTIVITY
            // =================================================

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

// ============================================================
// DASHBOARD CONTENT
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final sectionWeight = isKhmer ? FontWeight.w500 : FontWeight.w600;

    final noDebt = khrOutstanding == 0 && usdOutstanding == 0;

    return SafeArea(
      child: Column(
        children: [
          // =================================================
          // FIXED HEADER
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: headingWeight,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        l10n.businessOverview,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    AppIcons.storefront,
                    size: 23,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =================================================
          // ONLY DASHBOARD BODY SCROLLS
          // =================================================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // =================================================
                // OUTSTANDING CUSTOMER DEBT
                // =================================================
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.outstandingCustomerDebt,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.82),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.onPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              AppIcons.payment,
                              size: 19,
                              color: colors.onPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          MoneyUtils.format(khrOutstanding, MoneyCurrency.khr),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (usdOutstanding > 0) ...[
                        const SizedBox(height: 3),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            MoneyUtils.format(
                              usdOutstanding,
                              MoneyCurrency.usd,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 7),

                      Text(
                        noDebt
                            ? l10n.noOutstandingDebt
                            : l10n.acrossAllCustomers,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // TODAY
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: _TodayCard(
                        icon: AppIcons.sale,
                        title: l10n.salesToday,
                        khr: todaySalesKhr,
                        usd: todaySalesUsd,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _TodayCard(
                        icon: AppIcons.payment,
                        title: l10n.receivedToday,
                        khr: todayPaymentsKhr,
                        usd: todayPaymentsUsd,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =================================================
                // QUICK ACTIONS
                // =================================================
                Text(
                  l10n.quickActions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: sectionWeight,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: AppIcons.sale,
                        title: l10n.newSale,
                        onTap: onNewSaleTap,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _QuickAction(
                        icon: AppIcons.customers,
                        title: l10n.customers,
                        onTap: onCustomersTap,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =================================================
                // RECENT ACTIVITY
                // =================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recentActivity,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: sectionWeight,
                        ),
                      ),
                    ),

                    if (activities.isNotEmpty)
                      Text(
                        l10n.latestCount(activities.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 9),

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
                        Icon(AppIcons.receipt, size: 34, color: colors.primary),

                        const SizedBox(height: 10),

                        Text(
                          l10n.noActivityYet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isKhmer
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          l10n.activityWillAppearHere,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
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

// ============================================================
// TODAY CARD
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyUtils.format(khr, MoneyCurrency.khr),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (usd > 0) ...[
            const SizedBox(height: 2),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyUtils.format(usd, MoneyCurrency.usd),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: colors.primary),

              const SizedBox(height: 7),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
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
// DASHBOARD ACTIVITY MODEL
// ============================================================

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

// ============================================================
// ACTIVITY CARD
// ============================================================

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    // ========================================================
    // SALE
    // ========================================================

    if (activity.isSale) {
      final sale = activity.sale!;

      return Material(
        color: colors.surfaceContainerLowest,
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                      size: 19,
                      color: colors.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isKhmer
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          '${_saleItems(sale, l10n)} • '
                          '${_date(sale.saleDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 118),
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
        ),
      );
    }

    // ========================================================
    // PAYMENT
    // ========================================================

    final payment = activity.payment!;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
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
              size: 19,
              color: colors.onSecondaryContainer,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '${_paymentMethodLabel(l10n, payment)} • '
                  '${_date(payment.paymentDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
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
// ERROR STATE
// ============================================================

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.error, size: 38, color: colors.error),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
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
