import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer_payment.dart';
import '../../services/payment_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import '../customers/customer_details_screen.dart';

class TodayPaymentsScreen extends StatelessWidget {
  const TodayPaymentsScreen({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _paymentMethodLabel(
    AppLocalizations l10n,
    PaymentMethodType method,
  ) {
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

  IconData _paymentMethodIcon(
    PaymentMethodType method,
  ) {
    switch (method.label) {
      case 'Cash':
        return AppIcons.cash;

      case 'ABA QR':
      case 'ACLEDA QR':
        return AppIcons.qrCode;

      default:
        return AppIcons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isKhmer =
        Localizations.localeOf(context).languageCode == 'km';

    final headingWeight =
        isKhmer ? FontWeight.w600 : FontWeight.w700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.receivedToday,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: headingWeight,
          ),
        ),
      ),
      body: StreamBuilder<List<CustomerPayment>>(
        stream: PaymentService.instance.watchAllPayments(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: AppIcons.error,
              title: l10n.couldNotLoadPayments,
              message: l10n.pleaseTryAgain,
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todayPayments = snapshot.data!
              .where(
                (payment) =>
                    payment.status == 'active' &&
                    _isToday(payment.paymentDate),
              )
              .toList();

          todayPayments.sort(
            (a, b) => b.paymentDate.compareTo(
              a.paymentDate,
            ),
          );

          // ===================================================
          // IMPORTANT
          //
          // These totals use what Mom actually received,
          // not which debt currency the payment reduced.
          // ===================================================

          var totalKhr = 0;
          var totalUsd = 0;

          for (final payment in todayPayments) {
            if (payment.paidCurrency ==
                MoneyCurrency.khr) {
              totalKhr += payment.paidAmountMinor;
            } else {
              totalUsd += payment.paidAmountMinor;
            }
          }

          if (todayPayments.isEmpty) {
            return _MessageState(
              icon: AppIcons.payment,
              title: l10n.noActivityYet,
              message: l10n.activityWillAppearHere,
            );
          }

          return SafeArea(
            top: false,
            child: Column(
              children: [
                // =================================================
                // FIXED SUMMARY
                // =================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    0,
                  ),
                  child: _PaymentsSummaryCard(
                    totalKhr: totalKhr,
                    totalUsd: totalUsd,
                    count: todayPayments.length,
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // PAYMENT LIST
                // =================================================

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      32,
                    ),
                    itemCount: todayPayments.length,
                    separatorBuilder:
                        (context, index) =>
                            const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final payment =
                          todayPayments[index];

                      return _PaymentCard(
                        payment: payment,
                        dateText: _formatDate(
                          payment.paymentDate,
                        ),
                        methodText:
                            _paymentMethodLabel(
                          l10n,
                          payment.method,
                        ),
                        methodIcon:
                            _paymentMethodIcon(
                          payment.method,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _PaymentsSummaryCard extends StatelessWidget {
  const _PaymentsSummaryCard({
    required this.totalKhr,
    required this.totalUsd,
    required this.count,
  });

  final int totalKhr;
  final int totalUsd;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isKhmer =
        Localizations.localeOf(context).languageCode == 'km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.receivedToday,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyUtils.format(
                      totalKhr,
                      MoneyCurrency.khr,
                    ),
                    maxLines: 1,
                    style:
                        theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                if (totalUsd > 0) ...[
                  const SizedBox(height: 3),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      MoneyUtils.format(
                        totalUsd,
                        MoneyCurrency.usd,
                      ),
                      maxLines: 1,
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                Text(
                  l10n.recordsCount(count),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(
                      alpha: 0.72,
                    ),
                    fontWeight: isKhmer
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              AppIcons.payment,
              size: 23,
              color: colors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAYMENT CARD
// ============================================================

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.dateText,
    required this.methodText,
    required this.methodIcon,
  });

  final CustomerPayment payment;

  final String dateText;
  final String methodText;

  final IconData methodIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isKhmer =
        Localizations.localeOf(context).languageCode == 'km';

    final hasConversion =
        payment.paidCurrency !=
            payment.appliedCurrency;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: payment.customerId.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerDetailsScreen(
                      customerId:
                          payment.customerId,
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // PAYMENT METHOD ICON
              // ------------------------------------------------

              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  methodIcon,
                  size: 21,
                  color:
                      colors.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              // ------------------------------------------------
              // CUSTOMER + METHOD
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.customerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isKhmer
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            methodText,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: colors
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),

                        Text(
                          ' • ',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color: colors
                                .onSurfaceVariant,
                          ),
                        ),

                        Text(
                          dateText,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color: colors
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // ------------------------------------------
                    // CONVERSION DETAILS
                    // ------------------------------------------

                    if (hasConversion) ...[
                      const SizedBox(height: 3),

                      Text(
                        '${l10n.appliedToDebt}: '
                        '${MoneyUtils.format(
                          payment.appliedAmountMinor,
                          payment.appliedCurrency,
                        )}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: colors
                              .onSurfaceVariant,
                        ),
                      ),
                    ],

                    if (payment.note
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 3),

                      Text(
                        payment.note,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: colors
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ------------------------------------------------
              // ACTUAL MONEY RECEIVED
              // ------------------------------------------------

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 125,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '-${MoneyUtils.format(
                      payment.paidAmountMinor,
                      payment.paidCurrency,
                    )}',
                    maxLines: 1,
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (payment.customerId.isNotEmpty) ...[
                const SizedBox(width: 5),

                const Icon(
                  AppIcons.chevronRight,
                  size: 19,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY / ERROR STATE
// ============================================================

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(context).languageCode == 'km';

    return SafeArea(
      top: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color:
                      colors.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: isKhmer
                      ? FontWeight.w500
                      : FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
