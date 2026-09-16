import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../utils/money_utils.dart';

class SaleReceiptScreen extends StatelessWidget {
  const SaleReceiptScreen({
    super.key,
    required this.saleId,
  });

  final String saleId;

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receipt',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<Sale?>(
        future: SaleService.instance.getSale(
          saleId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load receipt.',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sale = snapshot.data;

          if (sale == null) {
            return const Center(
              child: Text(
                'Sale not found.',
              ),
            );
          }

          return _ReceiptContent(
            sale: sale,
            dateText: _date(
              sale.saleDate,
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptContent extends StatefulWidget {
  const _ReceiptContent({
    required this.sale,
    required this.dateText,
  });

  final Sale sale;
  final String dateText;

  @override
  State<_ReceiptContent> createState() =>
      _ReceiptContentState();
}

class _ReceiptContentState
    extends State<_ReceiptContent> {
  final GlobalKey _receiptKey = GlobalKey();

  bool _sharing = false;

  Future<void> _shareReceipt() async {
    if (_sharing) {
      return;
    }

    setState(() {
      _sharing = true;
    });

    try {
      await Future.delayed(
        const Duration(
          milliseconds: 100,
        ),
      );

      final renderObject =
          _receiptKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw Exception(
          'Receipt image could not be created.',
        );
      }

      final image = await renderObject.toImage(
        pixelRatio: 3.0,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception(
          'Receipt image could not be created.',
        );
      }

      final pngBytes =
          byteData.buffer.asUint8List();

      final safeCustomerName = widget.sale.customerName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final fileName =
          'MomBiz_${safeCustomerName}_'
          '${widget.dateText.replaceAll('/', '-')}.png';

      await SharePlus.instance.share(
        ShareParams(
          title: 'MomBiz Receipt',
          text:
              'Receipt for ${widget.sale.customerName}',
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: [
            fileName,
          ],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not share receipt image.',
          ),
        ),
      );
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
    final colors =
        Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          40,
        ),
        children: [
          RepaintBoundary(
            key: _receiptKey,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration:
                                BoxDecoration(
                              color: colors
                                  .primaryContainer,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                            child: Icon(
                              Icons
                                  .storefront_rounded,
                              color: colors
                                  .onPrimaryContainer,
                              size: 30,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          const Text(
                            'MomBiz',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            'SALE RECEIPT',
                            style: TextStyle(
                              color: colors
                                  .onSurfaceVariant,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              letterSpacing:
                                  1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    _InfoRow(
                      label: 'Customer',
                      value:
                          sale.customerName,
                    ),

                    if (sale.buyerName
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      _InfoRow(
                        label: 'Buyer',
                        value:
                            sale.buyerName,
                      ),
                    ],

                    const SizedBox(height: 8),

                    _InfoRow(
                      label: 'Date',
                      value: widget.dateText,
                    ),

                    const Divider(
                      height: 32,
                    ),

                    ...sale.items.map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 18,
                        ),
                        child: _ReceiptItem(
                          item: item,
                          currency:
                              sale.currency,
                        ),
                      ),
                    ),

                    const Divider(
                      height: 20,
                    ),

                    _MoneyRow(
                      label: 'Subtotal',
                      amount:
                          sale.subtotalMinor,
                      currency:
                          sale.currency,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _MoneyRow(
                      label: 'Discount',
                      amount:
                          sale.discountMinor,
                      currency:
                          sale.currency,
                      negative: true,
                    ),

                    const Divider(
                      height: 26,
                    ),

                    _MoneyRow(
                      label: 'Total',
                      amount:
                          sale.totalMinor,
                      currency:
                          sale.currency,
                      strong: true,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colors
                            .primaryContainer
                            .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Remaining debt',
                            style:
                                TextStyle(
                              color: colors
                                  .onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            MoneyUtils.format(
                              sale.totalMinor,
                              sale.currency,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 23,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (sale.note
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 20,
                      ),

                      Text(
                        'Note',
                        style: TextStyle(
                          color: colors
                              .onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        sale.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed:
                _sharing ? null : _shareReceipt,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                  ),
            label: Text(
              _sharing
                  ? 'Creating receipt image...'
                  : 'Share receipt image',
            ),
          ),

          const SizedBox(height: 10),

          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({
    required this.item,
    required this.currency,
  });

  final SaleItem item;
  final MoneyCurrency currency;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final unit =
        item.unit.trim();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          item.productName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: Text(
                unit.isEmpty
                    ? '${item.quantity} × '
                        '${MoneyUtils.format(
                          item.unitPriceMinor,
                          currency,
                        )}'
                    : '${item.quantity} $unit × '
                        '${MoneyUtils.format(
                          item.unitPriceMinor,
                          currency,
                        )}',
                style: TextStyle(
                  color:
                      colors.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Text(
              MoneyUtils.format(
                item.lineTotalMinor,
                currency,
              ),
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
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
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
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
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize:
                strong ? 18 : 14,
            fontWeight: strong
                ? FontWeight.w900
                : FontWeight.w500,
          ),
        ),

        const Spacer(),

        Text(
          '${negative && amount > 0 ? '- ' : ''}'
          '${MoneyUtils.format(
            amount,
            currency,
          )}',
          style: TextStyle(
            fontSize:
                strong ? 22 : 15,
            fontWeight: strong
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
