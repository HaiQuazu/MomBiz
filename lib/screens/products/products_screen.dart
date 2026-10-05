import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_image_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  late final Stream<List<Product>> _activeProductsStream;

  late final Stream<List<Product>> _archivedProductsStream;

  String _search = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();

    // Keep both streams alive so switching between
    // Active and Archived does not recreate Firestore
    // streams or briefly flash an empty state.
    _activeProductsStream = ProductService.instance.watchProducts(
      archived: false,
    );

    _archivedProductsStream = ProductService.instance.watchProducts(
      archived: true,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _addProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
  }

  Future<void> _editProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Widget _buildProductList({
    required Stream<List<Product>> stream,
    required bool archived,
  }) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l10n.couldNotLoadProducts));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.where((product) {
          if (_search.isEmpty) {
            return true;
          }

          return product.name.toLowerCase().contains(_search) ||
              product.category.toLowerCase().contains(_search) ||
              product.unit.toLowerCase().contains(_search);
        }).toList();

        if (products.isEmpty) {
          return _EmptyProducts(archived: archived);
        }

        return ListView.separated(
          key: PageStorageKey(
            archived ? 'archived_products_list' : 'active_products_list',
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          itemCount: products.length,
          // ignore: unnecessary_underscores
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = products[index];

            return Material(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _editProduct(product),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _LocalProductThumbnail(
                        productId: product.id,
                        fallbackIcon: _iconForCategory(product.category),
                        size: 52,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: isKhmer
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                  ),
                            ),

                            if (product.category.trim().isNotEmpty ||
                                product.unit.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),

                              Text(
                                [
                                  if (product.category.trim().isNotEmpty)
                                    product.category,
                                  if (product.unit.trim().isNotEmpty)
                                    product.unit,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],

                            if (product.defaultPriceMinor > 0) ...[
                              const SizedBox(height: 3),

                              Text(
                                '${l10n.defaultPrice}: '
                                '${MoneyUtils.format(product.defaultPriceMinor, product.defaultPriceCurrency)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: isKhmer
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(AppIcons.chevronRight, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.products,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: headingWeight),
        ),
      ),

      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton.extended(
              heroTag: 'products_add_product',
              onPressed: _addProduct,
              icon: const Icon(AppIcons.add, size: 21),
              label: Text(l10n.addProduct),
            ),

      body: Column(
        children: [
          // -------------------------
          // SEARCH
          // -------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.searchProducts,
              leading: const Icon(AppIcons.search, size: 21),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
              trailing: [
                if (_search.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _search = '';
                      });
                    },
                    icon: const Icon(AppIcons.close, size: 20),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -------------------------
          // ACTIVE / ARCHIVED
          //
          // KEEP OLD COMPACT STYLE.
          // -------------------------
          Center(
            child: SizedBox(
              width: 240,
              child: SegmentedButton<bool>(
                expandedInsets: EdgeInsets.zero,
                selectedIcon: const Icon(AppIcons.check, size: 18),
                style: ButtonStyle(
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -2,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    icon: const Icon(AppIcons.products, size: 18),
                    label: Text(
                      l10n.active,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: const Icon(AppIcons.archive, size: 18),
                    label: Text(
                      l10n.archived,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
                selected: {_showArchived},
                onSelectionChanged: (selection) {
                  setState(() {
                    _showArchived = selection.first;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // -------------------------
          // LISTS
          // -------------------------
          Expanded(
            child: IndexedStack(
              index: _showArchived ? 1 : 0,
              children: [
                _buildProductList(
                  stream: _activeProductsStream,
                  archived: false,
                ),
                _buildProductList(
                  stream: _archivedProductsStream,
                  archived: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('feed') ||
        value.contains('food') ||
        value.contains('ចំណី')) {
      return AppIcons.feed;
    }

    if (value.contains('vaccine') ||
        value.contains('medicine') ||
        value.contains('vitamin') ||
        value.contains('វ៉ាក់សាំង') ||
        value.contains('ថ្នាំ') ||
        value.contains('វីតាមីន')) {
      return AppIcons.medicine;
    }

    if (value.contains('fertilizer') || value.contains('ជី')) {
      return AppIcons.fertilizer;
    }

    if (value.contains('chick') || value.contains('កូនមាន់')) {
      return AppIcons.chick;
    }

    return AppIcons.product;
  }
}


class _LocalProductThumbnail extends StatelessWidget {
  const _LocalProductThumbnail({
    required this.productId,
    required this.fallbackIcon,
    required this.size,
  });

  final String productId;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return FutureBuilder<String?>(
      future: ProductImageService.instance
          .getImagePath(productId),
      builder: (context, snapshot) {
        final path =
            snapshot.data;

        return ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: SizedBox(
            width: size,
            height: size,
            child: path != null &&
                    path.trim().isNotEmpty
                ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder:
                        (context, error, stackTrace) {
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
        Theme.of(context).colorScheme;

    return Container(
      color:
          colors.primaryContainer,
      alignment:
          Alignment.center,
      child: Icon(
        fallbackIcon,
        size: 23,
        color:
            colors.onPrimaryContainer,
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                archived ? AppIcons.archive : AppIcons.products,
                size: 30,
                color: colors.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              archived ? l10n.noArchivedProducts : l10n.noProductsYet,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              archived
                  ? l10n.archivedProductsAppearHere
                  : l10n.addProductsMomSells,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
