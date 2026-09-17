import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
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

    // Keep both streams alive.
    // Switching tabs no longer creates
    // a brand-new Firestore stream.
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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForCategory(product.category),
                          size: 21,
                          color: colors.onPrimaryContainer,
                        ),
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
                                  ?.copyWith(fontWeight: FontWeight.w600),
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
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(Icons.chevron_right_rounded),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.products,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton.extended(
              heroTag: 'products_add_product',
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addProduct),
            ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: l10n.searchProducts,
              leading: const Icon(Icons.search_rounded),
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
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(l10n.active),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.archive_outlined),
                  label: Text(l10n.archived),
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

          const SizedBox(height: 14),

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
      return Icons.grass_rounded;
    }

    if (value.contains('vaccine') ||
        value.contains('medicine') ||
        value.contains('vitamin') ||
        value.contains('វ៉ាក់សាំង') ||
        value.contains('ថ្នាំ') ||
        value.contains('វីតាមីន')) {
      return Icons.medication_outlined;
    }

    if (value.contains('fertilizer') || value.contains('ជី')) {
      return Icons.eco_outlined;
    }

    if (value.contains('chick') || value.contains('កូនមាន់')) {
      return Icons.egg_alt_outlined;
    }

    return Icons.inventory_2_outlined;
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

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
                archived ? Icons.archive_outlined : Icons.inventory_2_outlined,
                size: 30,
                color: colors.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              archived ? l10n.noArchivedProducts : l10n.noProductsYet,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
