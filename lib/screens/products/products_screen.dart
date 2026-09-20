import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
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

    // Keep both streams alive so switching tabs
    // does not recreate Firestore streams.
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = products[index];

            return Material(
              color: archived
                  ? colors.surfaceContainerLow
                  : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _editProduct(product);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // --------------------------
                      // CATEGORY ICON
                      // --------------------------
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: archived
                              ? colors.surfaceContainerHighest
                              : colors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForCategory(product.category),
                          size: 21,
                          color: archived
                              ? colors.onSurfaceVariant
                              : colors.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // --------------------------
                      // PRODUCT DETAILS
                      // --------------------------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: archived
                                    ? colors.onSurfaceVariant
                                    : null,
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],

                            if (product.defaultPriceMinor > 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${l10n.defaultPrice}: '
                                '${MoneyUtils.format(product.defaultPriceMinor, product.defaultPriceCurrency)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: archived
                                      ? colors.onSurfaceVariant
                                      : colors.primary,
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

                      if (archived)
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            AppIcons.archive,
                            size: 17,
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      else
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          l10n.products,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: headingWeight,
          ),
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

      // ====================================================
      // HEADER CONTROLS FIXED
      // ONLY PRODUCT LIST SCROLLS
      // ====================================================
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // --------------------------------------------
            // SEARCH
            // --------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: SearchBar(
                controller: _searchController,
                hintText: l10n.searchProducts,
                leading: const Icon(AppIcons.search, size: 21),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colors.surfaceContainerLow,
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                constraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
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

            // --------------------------------------------
            // ACTIVE / ARCHIVED
            // --------------------------------------------
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
                    textStyle: WidgetStateProperty.resolveWith<TextStyle?>((
                      states,
                    ) {
                      final selected = states.contains(WidgetState.selected);

                      return theme.textTheme.labelLarge?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      );
                    }),
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

            // --------------------------------------------
            // SCROLLABLE LIST ONLY
            // --------------------------------------------
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

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
              alignment: Alignment.center,
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              archived
                  ? l10n.archivedProductsAppearHere
                  : l10n.addProductsMomSells,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
