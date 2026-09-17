import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chick_reservation.dart';
import '../../models/customer.dart';
import '../../services/chick_queue_service.dart';
import '../../services/customer_service.dart';

class ChickReservationFormScreen
    extends StatefulWidget {
  const ChickReservationFormScreen({
    super.key,
    this.reservation,
    this.initialScheduledDate,
  });

  final ChickReservation? reservation;

  // Used when tapping + on a batch header.
  final DateTime? initialScheduledDate;

  @override
  State<ChickReservationFormScreen>
      createState() =>
          _ChickReservationFormScreenState();
}

class _ChickReservationFormScreenState
    extends State<ChickReservationFormScreen> {
  final _quantityController =
      TextEditingController();

  final _noteController =
      TextEditingController();

  List<Customer> _customers = [];

  String? _customerId;

  DateTime _reservationDate =
      DateTime.now();

  DateTime _scheduledDate =
      DateTime.now();

  bool _loading = true;
  bool _saving = false;

  bool get _isEditing =>
      widget.reservation != null;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  Future<void> _loadCustomers() async {
    try {
      final customers =
          await CustomerService.instance
              .getActiveCustomers();

      // -------------------------
      // EDIT EXISTING RESERVATION
      // -------------------------
      if (_isEditing) {
        final reservation =
            widget.reservation!;

        if (!mounted) {
          return;
        }

        setState(() {
          _customers = customers;

          _customerId =
              reservation.customerId;

          _quantityController.text =
              reservation.quantity
                  .toString();

          _reservationDate =
              reservation.reservationDate;

          _scheduledDate =
              reservation.scheduledDate;

          _noteController.text =
              reservation.note;

          _loading = false;
        });

        return;
      }

      // -------------------------
      // ADD TO EXISTING BATCH
      //
      // If the Queue batch +
      // button supplied a date,
      // use that exact date.
      // -------------------------
      if (widget.initialScheduledDate !=
          null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _customers = customers;

          _scheduledDate = _dateOnly(
            widget.initialScheduledDate!,
          );

          _loading = false;
        });

        return;
      }

      // -------------------------
      // NORMAL NEW RESERVATION
      //
      // Suggest last waiting
      // batch + 5 days.
      // -------------------------
      final lastBatchDate =
          await ChickQueueService.instance
              .getLastWaitingBatchDate();

      if (!mounted) {
        return;
      }

      setState(() {
        _customers = customers;

        if (lastBatchDate == null) {
          _scheduledDate =
              _dateOnly(
            DateTime.now().add(
              const Duration(
                days: 5,
              ),
            ),
          );
        } else {
          _scheduledDate =
              _dateOnly(
            lastBatchDate.add(
              const Duration(
                days: 5,
              ),
            ),
          );
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n =
          AppLocalizations.of(context)!;

      setState(() {
        _loading = false;
      });

      _showError(
        l10n.couldNotLoadCustomers,
      );
    }
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

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void>
      _pickReservationDate() async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          _reservationDate,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime.now(),
    );

    if (picked == null ||
        !mounted) {
      return;
    }

    setState(() {
      _reservationDate =
          _dateOnly(picked);
    });
  }

  Future<void>
      _pickScheduledDate() async {
    final firstDate =
        _isEditing
            ? DateTime(2020)
            : DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              );

    var initialDate =
        _scheduledDate;

    // Make sure showDatePicker always
    // receives a valid initial date.
    if (initialDate.isBefore(
      firstDate,
    )) {
      initialDate = firstDate;
    }

    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          initialDate,
      firstDate:
          firstDate,
      lastDate: DateTime(
        DateTime.now().year + 3,
      ),
    );

    if (picked == null ||
        !mounted) {
      return;
    }

    setState(() {
      _scheduledDate =
          _dateOnly(picked);
    });
  }

  Future<void> _save() async {
    final l10n =
        AppLocalizations.of(context)!;

    final customer =
        _selectedCustomer;

    if (customer == null) {
      _showError(
        l10n.pleaseSelectCustomer,
      );
      return;
    }

    final quantity =
        int.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null ||
        quantity <= 0) {
      _showError(
        l10n
            .pleaseEnterValidChickQuantity,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await ChickQueueService
            .instance
            .updateReservation(
          reservationId:
              widget.reservation!.id,
          customerId:
              customer.id,
          customerName:
              customer.name,
          quantity:
              quantity,
          reservationDate:
              _reservationDate,
          scheduledDate:
              _scheduledDate,
          note:
              _noteController.text,
        );
      } else {
        await ChickQueueService
            .instance
            .addReservation(
          customerId:
              customer.id,
          customerName:
              customer.name,
          quantity:
              quantity,
          reservationDate:
              _reservationDate,
          scheduledDate:
              _scheduledDate,
          note:
              _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        _isEditing
            ? l10n
                .couldNotUpdateReservation
            : l10n
                .couldNotSaveReservation,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n
                  .editChickReservation
              : l10n
                  .newChickReservation,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          DropdownButtonFormField<String>(
            initialValue:
                _customerId,
            decoration:
                InputDecoration(
              labelText:
                  l10n.customer,
              prefixIcon:
                  const Icon(
                Icons.person_outline,
              ),
            ),
            items: _customers
                .map(
                  (customer) =>
                      DropdownMenuItem(
                    value:
                        customer.id,
                    child: Text(
                      customer.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _customerId = value;
              });
            },
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
                _quantityController,
            keyboardType:
                TextInputType.number,
            decoration:
                InputDecoration(
              labelText:
                  l10n.numberOfChicks,
              hintText:
                  l10n.example100,
              prefixIcon:
                  const Icon(
                Icons
                    .egg_alt_outlined,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            onTap:
                _pickReservationDate,
            child: InputDecorator(
              decoration:
                  InputDecoration(
                labelText:
                    l10n
                        .reservationDate,
                prefixIcon:
                    const Icon(
                  Icons
                      .calendar_today_outlined,
                ),
              ),
              child: Text(
                _formatDate(
                  _reservationDate,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          InkWell(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            onTap:
                _pickScheduledDate,
            child: InputDecorator(
              decoration:
                  InputDecoration(
                labelText:
                    l10n
                        .scheduledBatchDate,
                prefixIcon:
                    const Icon(
                  Icons
                      .event_available_outlined,
                ),
              ),
              child: Text(
                _formatDate(
                  _scheduledDate,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
                _noteController,
            minLines: 3,
            maxLines: 5,
            decoration:
                InputDecoration(
              labelText:
                  l10n.note,
              hintText:
                  l10n.optional,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          FilledButton.icon(
            onPressed:
                _saving
                    ? null
                    : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                  ),
            label: Text(
              _saving
                  ? l10n.saving
                  : _isEditing
                      ? l10n
                          .saveChanges
                      : l10n
                          .saveReservation,
            ),
          ),
        ],
      ),
    );
  }
}
