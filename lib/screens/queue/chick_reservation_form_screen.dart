import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chick_reservation.dart';
import '../../models/customer.dart';
import '../../services/chick_queue_service.dart';
import '../../services/customer_service.dart';
import '../../theme/app_icons.dart';

class ChickReservationFormScreen extends StatefulWidget {
  const ChickReservationFormScreen({
    super.key,
    this.reservation,
    this.initialScheduledDate,
  });

  final ChickReservation? reservation;

  // Used by the + button on a batch header.
  final DateTime? initialScheduledDate;

  @override
  State<ChickReservationFormScreen> createState() =>
      _ChickReservationFormScreenState();
}

class _ChickReservationFormScreenState
    extends State<ChickReservationFormScreen> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  List<Customer> _customers = [];

  String? _customerId;

  DateTime _reservationDate = DateTime.now();
  DateTime _scheduledDate = DateTime.now();

  bool _loading = true;
  bool _saving = false;

  bool get _isEditing => widget.reservation != null;

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

  @override
  void initState() {
    super.initState();

    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await CustomerService.instance.getActiveCustomers();

      if (_isEditing) {
        final reservation = widget.reservation!;

        if (!mounted) {
          return;
        }

        setState(() {
          _customers = customers;
          _customerId = reservation.customerId;
          _quantityController.text = reservation.quantity.toString();
          _reservationDate = reservation.reservationDate;
          _scheduledDate = reservation.scheduledDate;
          _noteController.text = reservation.note;
          _loading = false;
        });

        return;
      }

      // Exact date from batch + button.
      if (widget.initialScheduledDate != null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _customers = customers;
          _scheduledDate = widget.initialScheduledDate!;
          _loading = false;
        });

        return;
      }

      // Normal Add reservation:
      // suggest last waiting batch + 5 days.
      final lastBatchDate = await ChickQueueService.instance
          .getLastWaitingBatchDate();

      if (!mounted) {
        return;
      }

      setState(() {
        _customers = customers;

        if (lastBatchDate == null) {
          _scheduledDate = DateTime.now().add(const Duration(days: 5));
        } else {
          _scheduledDate = lastBatchDate.add(const Duration(days: 5));
        }

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

      _showError(l10n.couldNotLoadCustomers);
    }
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
                  height: MediaQuery.sizeOf(context).height * 0.68,
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
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickReservationDate() async {
    if (_saving) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _reservationDate = picked;
    });
  }

  Future<void> _pickScheduledDate() async {
    if (_saving) {
      return;
    }

    final firstDate = _isEditing ? DateTime(2020) : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: firstDate,
      lastDate: DateTime(DateTime.now().year + 3),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledDate = picked;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final customer = _selectedCustomer;

    if (customer == null) {
      _showError(l10n.pleaseSelectCustomer);
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null || quantity <= 0) {
      _showError(l10n.pleaseEnterValidChickQuantity);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await ChickQueueService.instance.updateReservation(
          reservationId: widget.reservation!.id,
          customerId: customer.id,
          customerName: customer.name,
          quantity: quantity,
          reservationDate: _reservationDate,
          scheduledDate: _scheduledDate,
          note: _noteController.text,
        );
      } else {
        await ChickQueueService.instance.addReservation(
          customerId: customer.id,
          customerName: customer.name,
          quantity: quantity,
          reservationDate: _reservationDate,
          scheduledDate: _scheduledDate,
          note: _noteController.text,
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
        _isEditing
            ? l10n.couldNotUpdateReservation
            : l10n.couldNotSaveReservation,
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
    _quantityController.dispose();
    _noteController.dispose();

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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? l10n.editChickReservation : l10n.newChickReservation,
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
          _isEditing ? l10n.editChickReservation : l10n.newChickReservation,
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            // ------------------------------------------------
            // CUSTOMER
            // ------------------------------------------------
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
            // QUANTITY
            // ------------------------------------------------
            TextField(
              controller: _quantityController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.numberOfChicks,
                hintText: l10n.example100,
                prefixIcon: const Icon(AppIcons.chick, size: 21),
              ),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------
            // RESERVATION DATE
            // ------------------------------------------------
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _saving ? null : _pickReservationDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.reservationDate,
                  prefixIcon: const Icon(AppIcons.calendar, size: 21),
                ),
                child: Text(_formatDate(_reservationDate)),
              ),
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------
            // SCHEDULED BATCH DATE
            // ------------------------------------------------
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _saving ? null : _pickScheduledDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.scheduledBatchDate,
                  prefixIcon: const Icon(AppIcons.calendar, size: 21),
                ),
                child: Text(_formatDate(_scheduledDate)),
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
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.note,
                hintText: l10n.optional,
                alignLabelWithHint: true,
                prefixIcon: const Icon(AppIcons.note, size: 21),
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
                      : _isEditing
                      ? l10n.saveChanges
                      : l10n.saveReservation,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
