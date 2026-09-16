import 'package:flutter/material.dart';

import '../../models/chick_reservation.dart';
import '../../models/customer.dart';
import '../../services/chick_queue_service.dart';
import '../../services/customer_service.dart';

class ChickReservationFormScreen extends StatefulWidget {
  const ChickReservationFormScreen({
    super.key,
    this.reservation,
  });

  final ChickReservation? reservation;

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

  bool get _isEditing =>
      widget.reservation != null;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers =
          await CustomerService.instance
              .getActiveCustomers();

      // Editing an existing reservation.
      if (_isEditing) {
        final reservation =
            widget.reservation!;

        if (!mounted) return;

        setState(() {
          _customers = customers;

          _customerId =
              reservation.customerId;

          _quantityController.text =
              reservation.quantity.toString();

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

      // Creating a new reservation.
      final lastBatchDate =
          await ChickQueueService.instance
              .getLastWaitingBatchDate();

      if (!mounted) return;

      setState(() {
        _customers = customers;

        if (lastBatchDate == null) {
          _scheduledDate =
              DateTime.now().add(
            const Duration(days: 5),
          );
        } else {
          _scheduledDate =
              lastBatchDate.add(
            const Duration(days: 5),
          );
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        'Could not load customers.',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickReservationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _reservationDate = picked;
    });
  }

  Future<void> _pickScheduledDate() async {
    final firstDate = _isEditing
        ? DateTime(2020)
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: firstDate,
      lastDate:
          DateTime(DateTime.now().year + 3),
    );

    if (picked == null) return;

    setState(() {
      _scheduledDate = picked;
    });
  }

  Future<void> _save() async {
    final customer =
        _selectedCustomer;

    if (customer == null) {
      _showError(
        'Please select a customer.',
      );
      return;
    }

    final quantity = int.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null ||
        quantity <= 0) {
      _showError(
        'Please enter a valid chick quantity.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await ChickQueueService.instance
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
        await ChickQueueService.instance
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

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      if (!mounted) return;

      _showError(
        _isEditing
            ? 'Could not update reservation.'
            : 'Could not save reservation.',
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
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit Chick Reservation'
              : 'New Chick Reservation',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _customerId,
            decoration:
                const InputDecoration(
              labelText: 'Customer',
              prefixIcon: Icon(
                Icons.person_outline,
              ),
            ),
            items: _customers
                .map(
                  (customer) =>
                      DropdownMenuItem(
                    value: customer.id,
                    child: Text(
                      customer.name,
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

          const SizedBox(height: 16),

          TextField(
            controller:
                _quantityController,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText:
                  'Number of chicks',
              hintText: 'Example: 100',
              prefixIcon: Icon(
                Icons.egg_alt_outlined,
              ),
            ),
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap:
                _pickReservationDate,
            child: InputDecorator(
              decoration:
                  const InputDecoration(
                labelText:
                    'Reservation date',
                prefixIcon: Icon(
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

          const SizedBox(height: 16),

          InkWell(
            onTap:
                _pickScheduledDate,
            child: InputDecorator(
              decoration:
                  const InputDecoration(
                labelText:
                    'Scheduled batch date',
                prefixIcon: Icon(
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

          const SizedBox(height: 16),

          TextField(
            controller:
                _noteController,
            minLines: 3,
            maxLines: 5,
            decoration:
                const InputDecoration(
              labelText: 'Note',
              hintText: 'Optional',
            ),
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed:
                _saving ? null : _save,
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
                  ? 'Saving...'
                  : _isEditing
                      ? 'Save changes'
                      : 'Save reservation',
            ),
          ),
        ],
      ),
    );
  }
}
