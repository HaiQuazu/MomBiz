import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
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

      if (!mounted) {
        return;
      }

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
        _items.first.quantityController.text = widget.initialQuantity!
            .toString();
      }

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotLoadCustomersOrProducts)),
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
    if (_items.length == 1) {
      return;
    }

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
    if (_customerId == null) {
      return null;
    }

    for (final customer in _customers) {
      if (customer.id == _customerId) {
        return customer;
      }
    }

    return null;
  }

  Future<void> _pickCustomer() async {
    if (_saving) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final searchController = TextEditingController();

    var search = '';

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;

        final isKhmer =
            Localizations.localeOf(sheetContext).languageCode == 'km';

        final titleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCustomers = _customers.where((customer) {
              if (search.isEmpty) {
                return true;
              }

              // Phone stays searchable but hidden.
              return customer.name.toLowerCase().contains(search) ||
                  customer.phone.toLowerCase().contains(search);
            }).toList();

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Text(
                          l10n.customer,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: titleWeight,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SearchBar(
                          controller: searchController,
                          hintText: l10n.searchNameOrPhone,
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
                          constraints: const BoxConstraints(
                            minHeight: 52,
                            maxHeight: 52,
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              search = value.trim().toLowerCase();
                            });
                          },
                          trailing: [
                            if (search.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setSheetState(() {
                                    search = '';
                                  });
                                },
                                icon: const Icon(AppIcons.close, size: 20),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Expanded(
                        child: filteredCustomers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppIcons.customers,
                                        size: 38,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.noCustomerFound,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: isKhmer
                                                  ? FontWeight.w500
                                                  : FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.tryAnotherNameOrPhone,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: filteredCustomers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final customer = filteredCustomers[index];

                                  final selected = customer.id == _customerId;

                                  return Material(
                                    color: selected
                                        ? colors.primaryContainer.withValues(
                                            alpha: 0.7,
                                          )
                                        : colors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(18),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        Navigator.pop(
                                          sheetContext,
                                          customer.id,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 21,
                                              backgroundColor:
                                                  colors.primaryContainer,
                                              child: Text(
                                                customer.name.trim().isEmpty
                                                    ? '?'
                                                    : customer.name
                                                          .trim()[0]
                                                          .toUpperCase(),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Text(
                                                customer.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight: isKhmer
                                                          ? FontWeight.w500
                                                          : FontWeight.w600,
                                                    ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            if (selected)
                                              Icon(
                                                AppIcons.selected,
                                                size: 21,
                                                color: colors.primary,
                                              )
                                            else
                                              const Icon(
                                                AppIcons.chevronRight,
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
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (!mounted || selectedId == null) {
      return;
    }

    setState(() {
      _customerId = selectedId;
    });
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

  void _applyProductDefaultPrice(_DraftItem item, Product? product) {
    if (product == null) {
      item.priceController.clear();
      return;
    }

    if (product.defaultPriceMinor <= 0) {
      item.priceController.clear();
      return;
    }

    if (product.defaultPriceCurrency != _currency) {
      item.priceController.clear();
      return;
    }

    item.priceController.text = _editablePrice(
      product.defaultPriceMinor,
      _currency,
    );
  }

  void _applyDefaultsForCurrentCurrency() {
    for (final item in _items) {
      _applyProductDefaultPrice(item, item.product);
    }
  }

  Future<void> _pickDate() async {
    if (_saving) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _saleDate = picked;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final customer = _selectedCustomer;

    if (customer == null) {
      _showError(l10n.pleaseSelectCustomer);
      return;
    }

    if (_items.isEmpty) {
      _showError(l10n.addAtLeastOneProduct);
      return;
    }

    final saleItems = <SaleItem>[];

    for (final item in _items) {
      final product = item.product;

      if (product == null) {
        _showError(l10n.pleaseSelectProductEveryItem);
        return;
      }

      final quantity = _quantityFor(item);

      if (quantity <= 0) {
        _showError(l10n.quantityGreaterThanZero);
        return;
      }

      final price = MoneyUtils.parse(item.priceController.text, _currency);

      if (price == null || price <= 0) {
        _showError(l10n.validPriceEveryItem);
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
      _showError(l10n.discountCannotExceedSubtotal);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final saleId = await SaleService.instance.createSale(
        customerId: customer.id,
        customerName: customer.name,
        buyerName: '',
        currency: _currency,
        items: saleItems,
        subtotalMinor: _subtotal,
        discountMinor: discount,
        totalMinor: _total,
        saleDate: _saleDate,
        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleReceiptScreen(saleId: saleId)),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(l10n.couldNotSaveSale);
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
    _discountController.dispose();
    _noteController.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final selectedCustomer = _selectedCustomer;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final pageTitleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final sectionWeight = isKhmer ? FontWeight.w500 : FontWeight.w600;

    final largeSectionWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final compactSegmentStyle = ButtonStyle(
      visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
    );

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.newSale,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: pageTitleWeight,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          l10n.newSale,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: pageTitleWeight,
          ),
        ),
      ),

      // ====================================================
      // SCROLLABLE BODY
      // ====================================================
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            // ------------------------------------------------
            // CUSTOMER
            // ------------------------------------------------
            Text(
              l10n.customer,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: sectionWeight,
              ),
            ),

            const SizedBox(height: 10),

            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _saving ? null : _pickCustomer,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.customer,
                  prefixIcon: const Icon(AppIcons.customer, size: 21),
                  suffixIcon: const Icon(AppIcons.chevronDown, size: 20),
                ),
                child: Text(
                  selectedCustomer?.name ?? l10n.pleaseSelectCustomer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: selectedCustomer == null
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------
            // SALE DATE
            // ------------------------------------------------
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _saving ? null : _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.saleDate,
                  prefixIcon: const Icon(AppIcons.calendar, size: 21),
                ),
                child: Text(_formatDate(_saleDate)),
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------
            // CURRENCY
            // ------------------------------------------------
            Text(
              l10n.currency,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: sectionWeight,
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                width: 230,
                child: SegmentedButton<MoneyCurrency>(
                  expandedInsets: EdgeInsets.zero,
                  selectedIcon: const Icon(AppIcons.check, size: 18),
                  style: compactSegmentStyle,
                  segments: const [
                    ButtonSegment<MoneyCurrency>(
                      value: MoneyCurrency.khr,
                      label: Text('KHR ៛', maxLines: 1, softWrap: false),
                    ),
                    ButtonSegment<MoneyCurrency>(
                      value: MoneyCurrency.usd,
                      label: Text('USD \$', maxLines: 1, softWrap: false),
                    ),
                  ],
                  selected: {_currency},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) {
                          setState(() {
                            _currency = selection.first;

                            _discountController.clear();

                            _applyDefaultsForCurrentCurrency();
                          });
                        },
                ),
              ),
            ),

            const SizedBox(height: 26),

            // =================================================
            // PRODUCTS
            // =================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.products,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: largeSectionWeight,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: _saving ? null : _addItem,
                  icon: const Icon(AppIcons.add, size: 19),
                  label: Text(l10n.addItem),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ...List.generate(_items.length, (index) {
              final item = _items[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SaleItemCard(
                  item: item,
                  products: _products,
                  currency: _currency,
                  canRemove: _items.length > 1,
                  enabled: !_saving,
                  onChanged: _refreshTotals,
                  onRemove: () {
                    _removeItem(index);
                  },
                  onProductChanged: (product) {
                    _applyProductDefaultPrice(item, product);

                    _refreshTotals();
                  },
                ),
              );
            }),

            const SizedBox(height: 10),

            // ------------------------------------------------
            // DISCOUNT
            // ------------------------------------------------
            Text(
              l10n.discount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: sectionWeight,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _discountController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.discountAmount,
                hintText: _currency == MoneyCurrency.khr
                    ? l10n.example50000
                    : l10n.example500,
                prefixIcon: const Icon(AppIcons.discount, size: 21),
                prefixText: _currency == MoneyCurrency.usd ? '\$ ' : null,
                suffixText: _currency == MoneyCurrency.khr ? '៛' : null,
              ),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------
            // NOTE
            // ------------------------------------------------
            TextField(
              controller: _noteController,
              enabled: !_saving,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.note,
                hintText: l10n.optional,
                alignLabelWithHint: true,
                prefixIcon: const Icon(AppIcons.note, size: 21),
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // TOTAL SUMMARY
            // =================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _TotalRow(
                    label: l10n.subtotal,
                    value: MoneyUtils.format(_subtotal, _currency),
                  ),

                  const SizedBox(height: 10),

                  _TotalRow(
                    label: l10n.discount,
                    value: '- ${MoneyUtils.format(_discount, _currency)}',
                  ),

                  const Divider(height: 28),

                  _TotalRow(
                    label: l10n.total,
                    value: MoneyUtils.format(_total, _currency),
                    strong: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ====================================================
      // FIXED SAVE AREA
      // ====================================================
      bottomSheet: SafeArea(
        top: false,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.check, size: 20),
                label: Text(
                  _saving
                      ? l10n.saving
                      : l10n.saveSaleAmount(
                          MoneyUtils.format(_total, _currency),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DRAFT ITEM
// ============================================================

class _DraftItem {
  Product? product;

  final quantityController = TextEditingController(text: '1');

  final priceController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

// ============================================================
// SALE ITEM CARD
// ============================================================

class _SaleItemCard extends StatefulWidget {
  const _SaleItemCard({
    required this.item,
    required this.products,
    required this.currency,
    required this.canRemove,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    required this.onProductChanged,
  });

  final _DraftItem item;
  final List<Product> products;
  final MoneyCurrency currency;
  final bool canRemove;
  final bool enabled;

  final VoidCallback onChanged;
  final VoidCallback onRemove;

  final ValueChanged<Product?> onProductChanged;

  @override
  State<_SaleItemCard> createState() => _SaleItemCardState();
}

class _SaleItemCardState extends State<_SaleItemCard> {
  Future<void> _pickProduct() async {
    if (!widget.enabled) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final searchController = TextEditingController();

    var search = '';

    final selectedProduct = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        final colors = theme.colorScheme;

        final isKhmer =
            Localizations.localeOf(sheetContext).languageCode == 'km';

        final titleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredProducts = widget.products.where((product) {
              if (search.isEmpty) {
                return true;
              }

              return product.name.toLowerCase().contains(search) ||
                  product.category.toLowerCase().contains(search) ||
                  product.unit.toLowerCase().contains(search);
            }).toList();

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.68,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: Text(
                          l10n.products,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: titleWeight,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SearchBar(
                          controller: searchController,
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
                          constraints: const BoxConstraints(
                            minHeight: 52,
                            maxHeight: 52,
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              search = value.trim().toLowerCase();
                            });
                          },
                          trailing: [
                            if (search.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  searchController.clear();

                                  setSheetState(() {
                                    search = '';
                                  });
                                },
                                icon: const Icon(AppIcons.close, size: 20),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Expanded(
                        child: filteredProducts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppIcons.product,
                                        size: 38,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.noProductsYet,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: isKhmer
                                                  ? FontWeight.w500
                                                  : FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: filteredProducts.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];

                                  final selected =
                                      widget.item.product?.id == product.id;

                                  return Material(
                                    color: selected
                                        ? colors.primaryContainer.withValues(
                                            alpha: 0.7,
                                          )
                                        : colors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(18),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        Navigator.pop(sheetContext, product);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: colors.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                AppIcons.product,
                                                size: 21,
                                                color:
                                                    colors.onPrimaryContainer,
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight: isKhmer
                                                              ? FontWeight.w500
                                                              : FontWeight.w600,
                                                        ),
                                                  ),

                                                  if (product.category
                                                          .trim()
                                                          .isNotEmpty ||
                                                      product.unit
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      [
                                                        if (product.category
                                                            .trim()
                                                            .isNotEmpty)
                                                          product.category,
                                                        if (product.unit
                                                            .trim()
                                                            .isNotEmpty)
                                                          product.unit,
                                                      ].join(' • '),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colors
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],

                                                  if (product
                                                          .defaultPriceMinor >
                                                      0) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      MoneyUtils.format(
                                                        product
                                                            .defaultPriceMinor,
                                                        product
                                                            .defaultPriceCurrency,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                colors.primary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            if (selected)
                                              Icon(
                                                AppIcons.selected,
                                                size: 21,
                                                color: colors.primary,
                                              )
                                            else
                                              const Icon(
                                                AppIcons.chevronRight,
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
              ),
            );
          },
        );
      },
    );

    searchController.dispose();

    if (!mounted || selectedProduct == null) {
      return;
    }

    setState(() {
      widget.item.product = selectedProduct;
    });

    widget.onProductChanged(selectedProduct);

    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final quantity = int.tryParse(widget.item.quantityController.text) ?? 0;

    final price =
        MoneyUtils.parse(widget.item.priceController.text, widget.currency) ??
        0;

    final lineTotal = quantity * price;

    final selectedProduct = widget.item.product;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --------------------------------------------
            // PRODUCT PICKER
            // --------------------------------------------
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: widget.enabled ? _pickProduct : null,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.product,
                        prefixIcon: const Icon(AppIcons.product, size: 21),
                        suffixIcon: const Icon(AppIcons.chevronDown, size: 20),
                      ),
                      child: Text(
                        selectedProduct?.name ?? l10n.product,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: selectedProduct == null
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),

                if (widget.canRemove) ...[
                  const SizedBox(width: 4),

                  IconButton(
                    tooltip: l10n.removeItem,
                    onPressed: widget.enabled ? widget.onRemove : null,
                    icon: const Icon(AppIcons.close, size: 20),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // --------------------------------------------
            // QUANTITY + PRICE
            // --------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.item.quantityController,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: l10n.quantity,
                      suffixText: selectedProduct?.unit.isEmpty ?? true
                          ? null
                          : selectedProduct!.unit,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller: widget.item.priceController,
                    enabled: widget.enabled,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: l10n.priceEach,
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

            // --------------------------------------------
            // LINE TOTAL
            // --------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.lineTotal,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      MoneyUtils.format(lineTotal, widget.currency),
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ============================================================
// TOTAL ROW
// ============================================================

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
    final theme = Theme.of(context);

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final labelStyle = strong
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;

    final valueStyle = strong
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle?.copyWith(
              fontWeight: strong
                  ? isKhmer
                        ? FontWeight.w600
                        : FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 10),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              style: valueStyle?.copyWith(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
