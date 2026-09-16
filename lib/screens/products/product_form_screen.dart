import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
  });

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;

  bool _saving = false;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.product?.name ?? '',
    );

    _categoryController = TextEditingController(
      text: widget.product?.category ?? '',
    );

    _unitController = TextEditingController(
      text: widget.product?.unit ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      if (_editing) {
        await ProductService.instance.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text,
          category: _categoryController.text,
          unit: _unitController.text,
        );
      } else {
        await ProductService.instance.addProduct(
          name: _nameController.text,
          category: _categoryController.text,
          unit: _unitController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save product. Please try again.'),
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

  Future<void> _archive() async {
    final product = widget.product;
    if (product == null) return;

    await ProductService.instance.archiveProduct(product.id);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _restore() async {
    final product = widget.product;
    if (product == null) return;

    await ProductService.instance.restoreProduct(product.id);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit product' : 'New product',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 34,
                  color: colors.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _editing ? 'Update product' : 'Add a product',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                'The selling price will be entered manually when creating a sale.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  hintText: 'Example: Chick Feed 25kg',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Example: Animal Feed',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'Bag, bottle, chick, kg...',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _editing ? 'Save changes' : 'Add product',
                ),
              ),

              if (_editing) ...[
                const SizedBox(height: 14),

                if (widget.product!.isArchived)
                  OutlinedButton.icon(
                    onPressed: _restore,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore product'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _archive,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archive product'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
