import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../utils/money_utils.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _nameController = TextEditingController();

  final _categoryController = TextEditingController();

  final _unitController = TextEditingController();

  final _priceController = TextEditingController();

  MoneyCurrency _priceCurrency = MoneyCurrency.khr;

  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    if (product != null) {
      _nameController.text = product.name;

      _categoryController.text = product.category;

      _unitController.text = product.unit;

      _priceCurrency = product.defaultPriceCurrency;

      if (product.defaultPriceMinor > 0) {
        _priceController.text = _editablePrice(
          product.defaultPriceMinor,
          product.defaultPriceCurrency,
        );
      }
    }
  }

  String _editablePrice(int amountMinor, MoneyCurrency currency) {
    switch (currency) {
      case MoneyCurrency.khr:
        return amountMinor.toString();

      case MoneyCurrency.usd:
        final dollars = amountMinor ~/ 100;

        final cents = amountMinor % 100;

        if (cents == 0) {
          return dollars.toString();
        }

        return '$dollars.'
            '${cents.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final name = _nameController.text.trim();

    final category = _categoryController.text.trim();

    final unit = _unitController.text.trim();

    if (name.isEmpty) {
      _showError(l10n.pleaseEnterProductName);
      return;
    }

    if (category.isEmpty) {
      _showError(l10n.pleaseEnterCategory);
      return;
    }

    if (unit.isEmpty) {
      _showError(l10n.pleaseEnterUnit);
      return;
    }

    var defaultPriceMinor = 0;

    final priceText = _priceController.text.trim();

    if (priceText.isNotEmpty) {
      final parsed = MoneyUtils.parse(priceText, _priceCurrency);

      if (parsed == null || parsed < 0) {
        _showError(l10n.pleaseEnterValidDefaultPrice);
        return;
      }

      defaultPriceMinor = parsed;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await ProductService.instance.updateProduct(
          productId: widget.product!.id,
          name: name,
          category: category,
          unit: unit,
          defaultPriceMinor: defaultPriceMinor,
          defaultPriceCurrency: _priceCurrency,
        );
      } else {
        await ProductService.instance.addProduct(
          name: name,
          category: category,
          unit: unit,
          defaultPriceMinor: defaultPriceMinor,
          defaultPriceCurrency: _priceCurrency,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        _isEditing ? l10n.couldNotUpdateProduct : l10n.couldNotAddProduct,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editProduct : l10n.addProduct,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.productName,
                hintText: l10n.exampleChickenFood,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.category,
                hintText: l10n.exampleFeed,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _unitController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.unit,
                hintText: l10n.exampleUnits,
                prefixIcon: const Icon(Icons.straighten_outlined),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.defaultPrice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Text(
                  l10n.optional,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Center(
              child: SegmentedButton<MoneyCurrency>(
                segments: const [
                  ButtonSegment(value: MoneyCurrency.khr, label: Text('KHR ៛')),
                  ButtonSegment(
                    value: MoneyCurrency.usd,
                    label: Text('USD \$'),
                  ),
                ],
                selected: {_priceCurrency},
                onSelectionChanged: (selection) {
                  final newCurrency = selection.first;

                  if (newCurrency == _priceCurrency) {
                    return;
                  }

                  setState(() {
                    _priceCurrency = newCurrency;

                    // Prevent a KHR value
                    // from becoming USD,
                    // or vice versa.
                    _priceController.clear();
                  });
                },
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.defaultPrice,
                hintText: _priceCurrency == MoneyCurrency.khr
                    ? l10n.example65000
                    : l10n.example1600,
                prefixIcon: const Icon(Icons.sell_outlined),
                prefixText: _priceCurrency == MoneyCurrency.usd ? '\$ ' : null,
                suffixText: _priceCurrency == MoneyCurrency.khr ? '៛' : null,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              l10n.defaultPriceOptional,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),

      bottomSheet: SafeArea(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _saving
                  ? l10n.saving
                  : _isEditing
                  ? l10n.saveChanges
                  : l10n.addProduct,
            ),
          ),
        ),
      ),
    );
  }
}
