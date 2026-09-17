import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../models/sale.dart';
import '../../services/sale_service.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.receipt,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Sale?>(
        future: SaleService.instance.getSale(saleId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.couldNotLoadReceipt));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sale = snapshot.data;

          if (sale == null) {
            return Center(child: Text(l10n.saleNotFound));
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

    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          RepaintBoundary(
            key: _receiptKey,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------
                    // RECEIPT HEADER
                    // ------------------
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: colors.onPrimaryContainer,
                              size: 29,
                            ),
                          ),

                          const SizedBox(height: 11),

                          Text(
                            l10n.appName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            l10n.saleReceipt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------
                    // SALE INFORMATION
                    // ------------------
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

                          // Older sales may
                          // still contain buyerName.
                          if (sale.buyerName.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(label: l10n.buyer, value: sale.buyerName),
                          ],

                          const SizedBox(height: 8),

                          _InfoRow(label: l10n.date, value: widget.dateText),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ------------------
                    // ITEMS
                    // ------------------
                    ...sale.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReceiptItem(
                          item: item,
                          currency: sale.currency,
                        ),
                      ),
                    ),

                    const Divider(height: 26),

                    // ------------------
                    // TOTALS
                    // ------------------
                    _MoneyRow(
                      label: l10n.subtotal,
                      amount: sale.subtotalMinor,
                      currency: sale.currency,
                    ),

                    const SizedBox(height: 9),

                    _MoneyRow(
                      label: l10n.discount,
                      amount: sale.discountMinor,
                      currency: sale.currency,
                      negative: true,
                    ),

                    const Divider(height: 26),

                    _MoneyRow(
                      label: l10n.total,
                      amount: sale.totalMinor,
                      currency: sale.currency,
                      strong: true,
                    ),

                    const SizedBox(height: 18),

                    // ------------------
                    // AMOUNT DUE
                    // ------------------
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            MoneyUtils.format(sale.totalMinor, sale.currency),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

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
                            Text(
                              l10n.note,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              sale.note,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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

          OutlinedButton.icon(
            onPressed: _sharing ? null : _shareReceipt,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(_sharing ? l10n.openingShare : l10n.shareReceipt),
          ),

          const SizedBox(height: 10),

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({required this.item, required this.currency});

  final SaleItem item;
  final MoneyCurrency currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final unit = item.unit.trim();

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 5),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  unit.isEmpty
                      ? '${item.quantity} × '
                            '${MoneyUtils.format(item.unitPriceMinor, currency)}'
                      : '${item.quantity} $unit × '
                            '${MoneyUtils.format(item.unitPriceMinor, currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                MoneyUtils.format(item.lineTotalMinor, currency),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

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
    final labelStyle = strong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    final valueStyle = strong
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle?.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Text(
          '${negative && amount > 0 ? '- ' : ''}'
          '${MoneyUtils.format(amount, currency)}',
          style: valueStyle?.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
