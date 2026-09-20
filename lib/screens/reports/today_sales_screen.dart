import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import '../receipts/sale_receipt_screen.dart';

class TodaySalesScreen extends StatelessWidget {
  const TodaySalesScreen({super.key});

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

  String _saleItems(
    Sale sale,
    AppLocalizations l10n,
  ) {
    if (sale.items.isEmpty) {
      return l10n.sale;
    }

    return sale.items.map((item) {
      final unit = item.unit.trim();

      if (unit.isEmpty) {
        return '${item.productName} × ${item.quantity}';
      }

      return '${item.productName} × ${item.quantity} $unit';
    }).join(' • ');
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
          l10n.salesToday,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: headingWeight,
          ),
        ),
      ),
      body: StreamBuilder<List<Sale>>(
        stream: SaleService.instance.watchAllSales(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: AppIcons.error,
              title: l10n.couldNotLoadSales,
              message: l10n.pleaseTryAgain,
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final todaySales = snapshot.data!
              .where(
                (sale) =>
                    sale.status == 'active' &&
                    _isToday(sale.saleDate),
              )
              .toList();

          todaySales.sort(
            (a, b) => b.saleDate.compareTo(a.saleDate),
          );

          var totalKhr = 0;
          var totalUsd = 0;

          for (final sale in todaySales) {
            if (sale.currency == MoneyCurrency.khr) {
              totalKhr += sale.totalMinor;
            } else {
              totalUsd += sale.totalMinor;
            }
          }

          if (todaySales.isEmpty) {
            return _MessageState(
              icon: AppIcons.sale,
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
                  child: _SalesSummaryCard(
                    totalKhr: totalKhr,
                    totalUsd: totalUsd,
                    count: todaySales.length,
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // SALES LIST
                // =================================================

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      32,
                    ),
                    itemCount: todaySales.length,
                    separatorBuilder:
                        (context, index) =>
                            const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final sale = todaySales[index];

                      return _SaleCard(
                        sale: sale,
                        dateText: _formatDate(
                          sale.saleDate,
                        ),
                        itemText: _saleItems(
                          sale,
                          l10n,
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

class _SalesSummaryCard extends StatelessWidget {
  const _SalesSummaryCard({
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
                  l10n.salesToday,
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
              AppIcons.sale,
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
// SALE CARD
// ============================================================

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.dateText,
    required this.itemText,
  });

  final Sale sale;
  final String dateText;
  final String itemText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleReceiptScreen(
                saleId: sale.id,
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
            children: [
              // ------------------------------------------------
              // SALE ICON
              // ------------------------------------------------

              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  AppIcons.receipt,
                  size: 21,
                  color: colors.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              // ------------------------------------------------
              // CUSTOMER + PRODUCTS
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isKhmer
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      itemText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        Icon(
                          AppIcons.calendar,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          dateText,
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ------------------------------------------------
              // SALE AMOUNT
              // ------------------------------------------------

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 125,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '+${MoneyUtils.format(
                      sale.totalMinor,
                      sale.currency,
                    )}',
                    maxLines: 1,
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                AppIcons.chevronRight,
                size: 19,
              ),
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
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: colors.onPrimaryContainer,
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
