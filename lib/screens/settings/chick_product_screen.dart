import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/app_settings_service.dart';
import '../../services/product_image_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import '../../widgets/app_picker_create_tile.dart';
import '../products/product_form_screen.dart';

class ChickProductScreen extends StatefulWidget {
  const ChickProductScreen({super.key});

  @override
  State<ChickProductScreen> createState() =>
      _ChickProductScreenState();
}

class _ChickProductScreenState
    extends State<ChickProductScreen> {
  final _searchController =
      TextEditingController();

  List<Product> _products = [];

  String _search = '';
  String? _selectedProductId;

  bool _loading = true;
  bool _saving = false;

  String _text({
    required String en,
    required String km,
  }) {
    return Localizations.localeOf(context)
                .languageCode ==
            'km'
        ? km
        : en;
  }

  @override
  void initState() {
    super.initState();

    _selectedProductId =
        AppSettingsService
            .instance
            .chickProductId;

    _loadProducts();
  }

  Future<void> _loadProducts({String? selectProductId}) async {
    try {
      final products =
          await ProductService.instance.getActiveProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;

        if (selectProductId != null &&
            products.any((product) => product.id == selectProductId)) {
          _selectedProductId = selectProductId;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Could not load products.',
              km: 'មិនអាចទាញយកផលិតផលបានទេ។',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _addProduct() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final productId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );

    if (!mounted || productId == null) {
      return;
    }

    await _loadProducts(selectProductId: productId);
  }

  Product? get _selectedProduct {
    final selectedId =
        _selectedProductId;

    if (selectedId == null) {
      return null;
    }

    for (final product in _products) {
      if (product.id == selectedId) {
        return product;
      }
    }

    return null;
  }

  Future<void> _save() async {
    final product =
        _selectedProduct;

    if (product == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en:
                  'Choose a chick product first.',
              km:
                  'សូមជ្រើសផលិតផលកូនមាន់ជាមុនសិន។',
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AppSettingsService.instance
          .setChickProductId(
        product.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en:
                  '${product.name} will now be used for chick queue sales.',
              km:
                  '${product.name} នឹងត្រូវប្រើសម្រាប់ការលក់ពីជួរកូនមាន់។',
            ),
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en:
                  'Could not save the chick product.',
              km:
                  'មិនអាចរក្សាទុកផលិតផលកូនមាន់បានទេ។',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final l10n =
        AppLocalizations.of(context)!;

    final isKhmer =
        Localizations.localeOf(context)
                .languageCode ==
            'km';

    final pageTitleWeight =
        isKhmer
            ? FontWeight.w600
            : FontWeight.w700;

    final compactPhone =
        MediaQuery.sizeOf(context).width < 420;

    final horizontalPadding =
        compactPhone ? 16.0 : 20.0;

    final bottomSystemInset =
        MediaQuery.viewPaddingOf(context).bottom;

    final keyboardInset =
        MediaQuery.viewInsetsOf(context).bottom;

    final keyboardOpen =
        keyboardInset > 0;

    final actionBottomPadding =
        keyboardOpen
            ? 12.0
            : 12.0 + bottomSystemInset;

    final filteredProducts =
        _products.where((product) {
      if (_search.isEmpty) {
        return true;
      }

      return product.name
              .toLowerCase()
              .contains(_search) ||
          product.category
              .toLowerCase()
              .contains(_search) ||
          product.unit
              .toLowerCase()
              .contains(_search);
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        title: Text(
          _text(
            en: 'Chick product',
            km: 'ផលិតផលកូនមាន់',
          ),
          style: theme
              .textTheme.titleLarge
              ?.copyWith(
            fontWeight:
                pageTitleWeight,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(
                horizontalPadding,
                compactPhone ? 6 : 8,
                horizontalPadding,
                0,
              ),
              child: Container(
                width:
                    double.infinity,
                padding:
                    EdgeInsets.all(
                  compactPhone ? 12 : 16,
                ),
                decoration:
                    BoxDecoration(
                  color: colors
                      .primaryContainer
                      .withValues(
                    alpha: 0.45,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Container(
                      width: compactPhone ? 40 : 44,
                      height: compactPhone ? 40 : 44,
                      alignment:
                          Alignment.center,
                      decoration:
                          BoxDecoration(
                        color: colors
                            .primaryContainer,
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: Icon(
                        AppIcons.chick,
                        size: compactPhone ? 20 : 22,
                        color: colors
                            .onPrimaryContainer,
                      ),
                    ),

                    SizedBox(
                      width: compactPhone ? 10 : 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _text(
                              en:
                                  'Used automatically for queue pickup sales',
                              km:
                                  'ប្រើដោយស្វ័យប្រវត្តិសម្រាប់ការលក់ពេលមកយកកូនមាន់',
                            ),
                            style: theme
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                              fontSize:
                                  compactPhone ? 13 : null,
                              height:
                                  compactPhone ? 1.22 : null,
                              fontWeight:
                                  isKhmer
                                      ? FontWeight
                                          .w500
                                      : FontWeight
                                          .w600,
                            ),
                          ),

                          SizedBox(
                            height: compactPhone ? 2 : 4,
                          ),

                          Text(
                            _text(
                              en:
                                  'You can change this anytime. MomBiz will use its default price and currency.',
                              km:
                                  'អ្នកអាចប្តូរវាបានគ្រប់ពេល។ MomBiz នឹងប្រើតម្លៃ និងរូបិយប័ណ្ណលំនាំដើមរបស់ផលិតផលនេះ។',
                            ),
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              fontSize:
                                  compactPhone ? 11.5 : null,
                              height:
                                  compactPhone ? 1.22 : null,
                              color: colors
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: compactPhone ? 10 : 14,
            ),

            Padding(
              padding:
                  EdgeInsets
                      .symmetric(
                horizontal: horizontalPadding,
              ),
              child: SearchBar(
                controller:
                    _searchController,
                hintText:
                    l10n.searchProducts,
                leading:
                    const Icon(
                  AppIcons.search,
                  size: 21,
                ),
                elevation:
                    const WidgetStatePropertyAll(
                  0,
                ),
                constraints:
                    compactPhone
                        ? const BoxConstraints(
                            minHeight: 48,
                            maxHeight: 48,
                          )
                        : null,
                onChanged: (value) {
                  setState(() {
                    _search =
                        value
                            .trim()
                            .toLowerCase();
                  });
                },
                trailing: [
                  if (_search
                      .isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _search =
                              '';
                        });
                      },
                      icon:
                          const Icon(
                        AppIcons.close,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(
              height: compactPhone ? 8 : 10,
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: AppPickerCreateTile(
                label: l10n.addProduct,
                onTap: _saving ? null : _addProduct,
              ),
            ),

            SizedBox(
              height: compactPhone ? 8 : 10,
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : filteredProducts
                          .isEmpty
                      ? _EmptyProducts(
                          message:
                              _products
                                      .isEmpty
                                  ? l10n
                                      .noProductsYet
                                  : _text(
                                      en:
                                          'No matching products.',
                                      km:
                                          'មិនមានផលិតផលត្រូវគ្នាទេ។',
                                    ),
                        )
                      : ListView
                          .separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .onDrag,
                          padding:
                              EdgeInsets
                                  .fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            (compactPhone
                                    ? 96.0
                                    : 110.0) +
                                keyboardInset,
                          ),
                          itemCount:
                              filteredProducts
                                  .length,
                          separatorBuilder:
                              (
                            context,
                            index,
                          ) =>
                                  SizedBox(
                            height: compactPhone ? 6 : 8,
                          ),
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final product =
                                filteredProducts[
                                    index];

                            final selected =
                                product.id ==
                                    _selectedProductId;

                            return Material(
                              color: selected
                                  ? colors
                                      .primaryContainer
                                      .withValues(
                                      alpha:
                                          0.55,
                                    )
                                  : colors
                                      .surfaceContainerLowest,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                              clipBehavior:
                                  Clip.antiAlias,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                                onTap: _saving
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _selectedProductId =
                                                product.id;
                                          },
                                        );
                                      },
                                child: Padding(
                                  padding:
                                      EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        compactPhone ? 12 : 14,
                                    vertical:
                                        compactPhone ? 8 : 11,
                                  ),
                                  child: Row(
                                    children: [
                                      _ProductThumbnail(
                                        productId:
                                            product.id,
                                        size:
                                            compactPhone ? 56 : 44,
                                      ),

                                      const SizedBox(
                                        width:
                                            12,
                                      ),

                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              product
                                                  .name,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style: theme
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                fontWeight: isKhmer
                                                    ? FontWeight.w500
                                                    : FontWeight.w600,
                                              ),
                                            ),

                                            if (product
                                                    .category
                                                    .trim()
                                                    .isNotEmpty ||
                                                product
                                                    .unit
                                                    .trim()
                                                    .isNotEmpty) ...[
                                              const SizedBox(
                                                height:
                                                    2,
                                              ),

                                              Text(
                                                [
                                                  if (product.category.trim().isNotEmpty)
                                                    product.category,
                                                  if (product.unit.trim().isNotEmpty)
                                                    product.unit,
                                                ].join(
                                                  ' • ',
                                                ),
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],

                                            if (product
                                                    .defaultPriceMinor >
                                                0) ...[
                                              const SizedBox(
                                                height:
                                                    3,
                                              ),

                                              Text(
                                                MoneyUtils
                                                    .format(
                                                  product
                                                      .defaultPriceMinor,
                                                  product
                                                      .defaultPriceCurrency,
                                                ),
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      colors.primary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(
                                        width:
                                            8,
                                      ),

                                      if (selected)
                                        Icon(
                                          AppIcons
                                              .selected,
                                          size: 22,
                                          color:
                                              colors.primary,
                                        )
                                      else
                                        const Icon(
                                          AppIcons
                                              .chevronRight,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      bottomSheet: AnimatedPadding(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.only(
          bottom: keyboardInset,
        ),
        child: Material(
          color: theme
              .scaffoldBackgroundColor,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(
              horizontalPadding,
              compactPhone ? 10 : 12,
              horizontalPadding,
              actionBottomPadding,
            ),
            child: SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton.icon(
                onPressed:
                    _saving ||
                            _selectedProduct ==
                                null
                        ? null
                        : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        AppIcons.check,
                        size: 20,
                      ),
                label: Text(
                  _saving
                      ? _text(
                          en:
                              'Saving...',
                          km:
                              'កំពុងរក្សាទុក...',
                        )
                      : _text(
                          en:
                              'Use for chick queue',
                          km:
                              'ប្រើសម្រាប់ជួរកូនមាន់',
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail
    extends StatelessWidget {
  const _ProductThumbnail({
    required this.productId,
    required this.size,
  });

  final String productId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future:
          ProductImageService.instance
              .getImagePath(
        productId,
      ),
      builder: (
        context,
        snapshot,
      ) {
        final path =
            snapshot.data;

        return ClipRRect(
          borderRadius:
              BorderRadius.circular(
            size >= 48 ? 15 : 14,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: path != null &&
                    path
                        .trim()
                        .isNotEmpty
                ? Image.file(
                    File(path),
                    fit:
                        BoxFit.cover,
                    gaplessPlayback:
                        true,
                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _fallback(
                        context,
                      );
                    },
                  )
                : _fallback(
                    context,
                  ),
          ),
        );
      },
    );
  }

  Widget _fallback(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      alignment:
          Alignment.center,
      color: colors
          .primaryContainer,
      child: Icon(
        AppIcons.chick,
        size: size >= 56 ? 25 : 21,
        color: colors
            .onPrimaryContainer,
      ),
    );
  }
}

class _EmptyProducts
    extends StatelessWidget {
  const _EmptyProducts({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          36,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: colors
                    .primaryContainer,
                borderRadius:
                    BorderRadius
                        .circular(
                  22,
                ),
              ),
              child: Icon(
                AppIcons.chick,
                size: 32,
                color: colors
                    .onPrimaryContainer,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colors
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
