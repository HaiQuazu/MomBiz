import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../utils/money_utils.dart';
import '../receipts/sale_receipt_screen.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({
    super.key,
    this.initialCustomerId,
    this.initialQuantity,
  });

  final String? initialCustomerId;
  final int? initialQuantity;

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _buyerController = TextEditingController();
  final _discountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Customer> _customers = [];
  List<Product> _products = [];

  final List<_DraftItem> _items = [];

  String? _customerId;

  MoneyCurrency _currency = MoneyCurrency.khr;

  DateTime _saleDate = DateTime.now();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _discountController.addListener(_refreshTotals);

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CustomerService.instance.getActiveCustomers(),
        ProductService.instance.getActiveProducts(),
      ]);

      if (!mounted) return;

      _customers = results[0] as List<Customer>;
      _products = results[1] as List<Product>;

      if (widget.initialCustomerId != null &&
          _customers.any(
            (customer) => customer.id == widget.initialCustomerId,
          )) {
        _customerId = widget.initialCustomerId;
      }

      _addItem();

      if (widget.initialQuantity != null &&
          widget.initialQuantity! > 0 &&
          _items.isNotEmpty) {
        _items.first.quantityController.text = widget.initialQuantity
            .toString();
      }

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load customers or products.')),
      );
    }
  }

  void _addItem() {
    final item = _DraftItem();

    item.quantityController.addListener(_refreshTotals);

    item.priceController.addListener(_refreshTotals);

    _items.add(item);

    if (mounted) {
      setState(() {});
    }
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;

    _items[index].dispose();
    _items.removeAt(index);

    setState(() {});
  }

  void _refreshTotals() {
    if (mounted) {
      setState(() {});
    }
  }

  int _quantityFor(_DraftItem item) {
    return int.tryParse(item.quantityController.text.trim()) ?? 0;
  }

  int _priceFor(_DraftItem item) {
    return MoneyUtils.parse(item.priceController.text, _currency) ?? 0;
  }

  int get _subtotal {
    var total = 0;

    for (final item in _items) {
      total += _quantityFor(item) * _priceFor(item);
    }

    return total;
  }

  int get _discount {
    return MoneyUtils.parse(_discountController.text, _currency) ?? 0;
  }

  int get _total {
    final result = _subtotal - _discount;

    return result < 0 ? 0 : result;
  }

  Customer? get _selectedCustomer {
    if (_customerId == null) return null;

    for (final customer in _customers) {
      if (customer.id == _customerId) {
        return customer;
      }
    }

    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _saleDate = picked;
    });
  }

  Future<void> _save() async {
    final customer = _selectedCustomer;

    if (customer == null) {
      _showError('Please select a customer.');
      return;
    }

    if (_items.isEmpty) {
      _showError('Add at least one product.');
      return;
    }

    final saleItems = <SaleItem>[];

    for (final item in _items) {
      final product = item.product;

      if (product == null) {
        _showError('Please select a product for every item.');
        return;
      }

      final quantity = _quantityFor(item);

      if (quantity <= 0) {
        _showError('Quantity must be greater than zero.');
        return;
      }

      final price = MoneyUtils.parse(item.priceController.text, _currency);

      if (price == null || price <= 0) {
        _showError('Please enter a valid price for every item.');
        return;
      }

      saleItems.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          unit: product.unit,
          quantity: quantity,
          unitPriceMinor: price,
          lineTotalMinor: quantity * price,
        ),
      );
    }

    final discount = MoneyUtils.parse(_discountController.text, _currency) ?? 0;

    if (discount < 0 || discount > _subtotal) {
      _showError('Discount cannot be greater than the subtotal.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final saleId = await SaleService.instance.createSale(
        customerId: customer.id,
        customerName: customer.name,
        buyerName: _buyerController.text,
        currency: _currency,
        items: saleItems,
        subtotalMinor: _subtotal,
        discountMinor: discount,
        totalMinor: _total,
        saleDate: _saleDate,
        note: _noteController.text,
      );

      if (!mounted) return;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleReceiptScreen(saleId: saleId)),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      _showError('Could not save the sale. Please try again.');
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _discountController.dispose();
    _noteController.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New sale',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            Text(
              'Customer',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: _customerId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'Customer',
              ),
              items: _customers
                  .map(
                    (customer) => DropdownMenuItem(
                      value: customer.id,
                      child: Text(customer.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _customerId = value;
                });
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _buyerController,
              decoration: const InputDecoration(
                labelText: 'Who came to buy?',
                hintText: 'Optional — e.g. Dara\'s son',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),

            const SizedBox(height: 14),

            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sale date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_formatDate(_saleDate)),
              ),
            ),

            const SizedBox(height: 26),

            Text(
              'Currency',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            SegmentedButton<MoneyCurrency>(
              segments: const [
                ButtonSegment(value: MoneyCurrency.khr, label: Text('KHR ៛')),
                ButtonSegment(value: MoneyCurrency.usd, label: Text('USD \$')),
              ],
              selected: {_currency},
              onSelectionChanged: (selection) {
                setState(() {
                  _currency = selection.first;

                  _discountController.clear();

                  for (final item in _items) {
                    item.priceController.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add item'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ...List.generate(_items.length, (index) {
              final item = _items[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SaleItemCard(
                  item: item,
                  products: _products,
                  currency: _currency,
                  canRemove: _items.length > 1,
                  onChanged: _refreshTotals,
                  onRemove: () => _removeItem(index),
                ),
              );
            }),

            const SizedBox(height: 12),

            Text(
              'Discount',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Discount amount',
                hintText: _currency == MoneyCurrency.khr
                    ? 'Example: 50000'
                    : 'Example: 5.00',
                prefixIcon: const Icon(Icons.discount_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _TotalRow(
                    label: 'Subtotal',
                    value: MoneyUtils.format(_subtotal, _currency),
                  ),
                  const SizedBox(height: 10),
                  _TotalRow(
                    label: 'Discount',
                    value: '- ${MoneyUtils.format(_discount, _currency)}',
                  ),
                  const Divider(height: 28),
                  _TotalRow(
                    label: 'Total',
                    value: MoneyUtils.format(_total, _currency),
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          color: Theme.of(context).scaffoldBackgroundColor,
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
                  ? 'Saving...'
                  : 'Save sale • ${MoneyUtils.format(_total, _currency)}',
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftItem {
  Product? product;

  final quantityController = TextEditingController(text: '1');

  final priceController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class _SaleItemCard extends StatefulWidget {
  const _SaleItemCard({
    required this.item,
    required this.products,
    required this.currency,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _DraftItem item;
  final List<Product> products;
  final MoneyCurrency currency;
  final bool canRemove;

  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_SaleItemCard> createState() => _SaleItemCardState();
}

class _SaleItemCardState extends State<_SaleItemCard> {
  @override
  Widget build(BuildContext context) {
    final quantity = int.tryParse(widget.item.quantityController.text) ?? 0;

    final price =
        MoneyUtils.parse(widget.item.priceController.text, widget.currency) ??
        0;

    final lineTotal = quantity * price;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Product>(
                    initialValue: widget.item.product,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: widget.products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product,
                            child: Text(
                              product.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (product) {
                      setState(() {
                        widget.item.product = product;
                      });

                      widget.onChanged();
                    },
                  ),
                ),

                if (widget.canRemove)
                  IconButton(
                    tooltip: 'Remove item',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.item.quantityController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: widget.item.product?.unit.isEmpty ?? true
                          ? null
                          : widget.item.product!.unit,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: widget.item.priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: 'Price each',
                      prefixText: widget.currency == MoneyCurrency.usd
                          ? '\$ '
                          : null,
                      suffixText: widget.currency == MoneyCurrency.khr
                          ? '៛'
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Text(
                  'Line total',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  MoneyUtils.format(lineTotal, widget.currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            fontSize: strong ? 18 : 15,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            fontSize: strong ? 22 : 15,
          ),
        ),
      ],
    );
  }
}
