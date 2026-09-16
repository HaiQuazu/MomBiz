import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  String _search = '';
  bool _showArchived = false;

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton.extended(
              heroTag: 'products_add_product',
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search products',
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

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Active'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.archive_outlined),
                  label: Text('Archived'),
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

          const SizedBox(height: 18),

          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.instance.watchProducts(
                archived: _showArchived,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load products.'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.where((product) {
                  if (_search.isEmpty) return true;

                  return product.name.toLowerCase().contains(_search) ||
                      product.category.toLowerCase().contains(_search);
                }).toList();

                if (products.isEmpty) {
                  return _EmptyProducts(archived: _showArchived);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Material(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _editProduct(product),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Icon(
                                  _iconForCategory(product.category),
                                  color: colors.onPrimaryContainer,
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      [
                                        if (product.category.isNotEmpty)
                                          product.category,
                                        if (product.unit.isNotEmpty)
                                          product.unit,
                                      ].join(' • '),
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final value = category.toLowerCase();

    if (value.contains('feed') || value.contains('food')) {
      return Icons.grass_rounded;
    }

    if (value.contains('vaccine') ||
        value.contains('medicine') ||
        value.contains('vitamin')) {
      return Icons.medication_outlined;
    }

    if (value.contains('fertilizer')) {
      return Icons.eco_outlined;
    }

    if (value.contains('chick')) {
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                archived ? Icons.archive_outlined : Icons.inventory_2_outlined,
                size: 38,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              archived ? 'No archived products' : 'No products yet',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              archived
                  ? 'Archived products will appear here.'
                  : 'Add the products your mom sells.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
