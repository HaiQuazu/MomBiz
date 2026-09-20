import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';

class SaleReceiptScreen extends StatelessWidget {
  const SaleReceiptScreen({super.key, required this.saleId});

  final String saleId;

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final pageTitleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          l10n.receipt,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: pageTitleWeight,
          ),
        ),
      ),

      // ====================================================
      // RECEIPT DATA
      // ====================================================
      body: FutureBuilder<Sale?>(
        future: SaleService.instance.getSale(saleId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.couldNotLoadReceipt,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sale = snapshot.data;

          if (sale == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.saleNotFound, textAlign: TextAlign.center),
              ),
            );
          }

          return _ReceiptContent(sale: sale, dateText: _date(sale.saleDate));
        },
      ),
    );
  }
}

class _ReceiptContent extends StatefulWidget {
  const _ReceiptContent({required this.sale, required this.dateText});

  final Sale sale;
  final String dateText;

  @override
  State<_ReceiptContent> createState() => _ReceiptContentState();
}

class _ReceiptContentState extends State<_ReceiptContent> {
  final GlobalKey _receiptKey = GlobalKey();

  bool _sharing = false;

  Future<void> _shareReceipt() async {
    if (_sharing) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final shareTitle = '${l10n.appName} ${l10n.receipt}';

    final shareText = l10n.receiptForCustomer(widget.sale.customerName);

    final errorMessage = l10n.couldNotShareReceipt;

    setState(() {
      _sharing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final renderObject = _receiptKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('Receipt image could not be created.');
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Receipt image could not be created.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final safeCustomerName = widget.sale.customerName.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final fileName =
          'MomBiz_${safeCustomerName}_'
          '${widget.dateText.replaceAll('/', '-')}.png';

      await SharePlus.instance.share(
        ShareParams(
          title: shareTitle,
          text: shareText,
          files: [XFile.fromData(pngBytes, mimeType: 'image/png')],
          fileNameOverrides: [fileName],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final receiptHeadingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return SafeArea(
      top: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // =================================================
          // RECEIPT IMAGE AREA
          // =================================================
          RepaintBoundary(
            key: _receiptKey,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -----------------------------------------
                    // HEADER
                    // -----------------------------------------
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              AppIcons.storefront,
                              color: colors.onPrimaryContainer,
                              size: 27,
                            ),
                          ),

                          const SizedBox(height: 11),

                          Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: receiptHeadingWeight,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            l10n.saleReceipt,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // -----------------------------------------
                    // CUSTOMER / DATE
                    // -----------------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: l10n.customer,
                            value: sale.customerName,
                          ),

                          if (sale.buyerName.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(label: l10n.buyer, value: sale.buyerName),
                          ],

                          const SizedBox(height: 8),

                          _InfoRow(label: l10n.date, value: widget.dateText),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // -----------------------------------------
                    // ITEMS
                    // -----------------------------------------
                    ...sale.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _ReceiptItem(
                          item: item,
                          currency: sale.currency,
                        ),
                      ),
                    ),

                    const Divider(height: 26),

                    // -----------------------------------------
                    // SUBTOTAL
                    // -----------------------------------------
                    _MoneyRow(
                      label: l10n.subtotal,
                      amount: sale.subtotalMinor,
                      currency: sale.currency,
                    ),

                    const SizedBox(height: 9),

                    // -----------------------------------------
                    // DISCOUNT
                    // -----------------------------------------
                    _MoneyRow(
                      label: l10n.discount,
                      amount: sale.discountMinor,
                      currency: sale.currency,
                      negative: true,
                    ),

                    const Divider(height: 26),

                    // -----------------------------------------
                    // TOTAL
                    // -----------------------------------------
                    _MoneyRow(
                      label: l10n.total,
                      amount: sale.totalMinor,
                      currency: sale.currency,
                      strong: true,
                    ),

                    const SizedBox(height: 18),

                    // -----------------------------------------
                    // AMOUNT DUE
                    // -----------------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.amountDueForSale,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              MoneyUtils.format(sale.totalMinor, sale.currency),
                              maxLines: 1,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -----------------------------------------
                    // NOTE
                    // -----------------------------------------
                    if (sale.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.note,
                                  size: 17,
                                  color: colors.onSurfaceVariant,
                                ),

                                const SizedBox(width: 7),

                                Text(
                                  l10n.note,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(sale.note, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =================================================
          // SHARE
          // =================================================
          OutlinedButton.icon(
            onPressed: _sharing ? null : _shareReceipt,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.share, size: 20),
            label: Text(_sharing ? l10n.openingShare : l10n.shareReceipt),
          ),

          const SizedBox(height: 10),

          // =================================================
          // DONE
          // =================================================
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(AppIcons.check, size: 20),
            label: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECEIPT ITEM
// ============================================================

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({required this.item, required this.currency});

  final SaleItem item;
  final MoneyCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final unit = item.unit.trim();

    final quantityText = unit.isEmpty
        ? '${item.quantity} × '
              '${MoneyUtils.format(item.unitPriceMinor, currency)}'
        : '${item.quantity} $unit × '
              '${MoneyUtils.format(item.unitPriceMinor, currency)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  quantityText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    MoneyUtils.format(item.lineTotalMinor, currency),
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MONEY ROW
// ============================================================

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.negative = false,
    this.strong = false,
  });

  final String label;
  final int amount;
  final MoneyCurrency currency;

  final bool negative;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final labelStyle = strong
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;

    final valueStyle = strong
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyMedium;

    final value =
        '${negative && amount > 0 ? '- ' : ''}'
        '${MoneyUtils.format(amount, currency)}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle?.copyWith(
              fontWeight: strong
                  ? isKhmer
                        ? FontWeight.w600
                        : FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 10),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              style: valueStyle?.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
