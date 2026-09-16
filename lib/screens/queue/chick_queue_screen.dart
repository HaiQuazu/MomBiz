import 'package:flutter/material.dart';

import '../../models/chick_reservation.dart';
import '../../services/chick_queue_service.dart';
import 'chick_reservation_form_screen.dart';
import '../sales/sale_form_screen.dart';

class ChickQueueScreen extends StatefulWidget {
  const ChickQueueScreen({super.key});

  @override
  State<ChickQueueScreen> createState() => _ChickQueueScreenState();
}

class _ChickQueueScreenState extends State<ChickQueueScreen> {
  bool _showHistory = false;
  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _addReservation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChickReservationFormScreen()),
    );
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _cancel(
    ChickReservation reservation,
    List<ChickReservation> waitingReservations,
  ) async {
    ChickReservation? nextReservation;

    final currentIndex = waitingReservations.indexWhere(
      (item) => item.id == reservation.id,
    );

    if (currentIndex >= 0 && currentIndex + 1 < waitingReservations.length) {
      nextReservation = waitingReservations[currentIndex + 1];
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel reservation?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reservation.customerName} • '
                '${reservation.quantity} chicks',
              ),

              const SizedBox(height: 12),

              Text('Batch: ${_date(reservation.scheduledDate)}'),

              if (nextReservation != null) ...[
                const SizedBox(height: 20),

                const Text(
                  'Next customer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                Text(
                  '${nextReservation.customerName} • '
                  '${nextReservation.quantity} chicks',
                ),

                const SizedBox(height: 4),

                Text(
                  'Current batch: '
                  '${_date(nextReservation.scheduledDate)}',
                ),

                const SizedBox(height: 10),

                Text(
                  'Move ${nextReservation.customerName} '
                  'forward to '
                  '${_date(reservation.scheduledDate)}?',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'keep');
              },
              child: const Text('Keep reservation'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'cancelOnly');
              },
              child: const Text('Cancel only'),
            ),

            if (nextReservation != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, 'moveNext');
                },
                child: const Text('Cancel & move next'),
              ),
          ],
        );
      },
    );

    if (choice == null || choice == 'keep') {
      return;
    }

    try {
      await ChickQueueService.instance.cancelAndMoveNext(
        cancelledReservationId: reservation.id,
        nextReservationId: choice == 'moveNext' ? nextReservation?.id : null,
        newScheduledDate: choice == 'moveNext'
            ? reservation.scheduledDate
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == 'moveNext'
                ? 'Reservation cancelled and next customer moved forward.'
                : 'Reservation cancelled.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel reservation.')),
      );
    }
  }

  Future<void> _pickup(ChickReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Customer picked up chicks?'),
          content: Text(
            '${reservation.customerName}\n'
            '${reservation.quantity} chicks\n\n'
            'A sale will be created before this reservation '
            'is marked as picked up.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Create sale'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final saleSaved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SaleFormScreen(
          initialCustomerId: reservation.customerId,
          initialQuantity: reservation.quantity,
        ),
      ),
    );

    if (saleSaved != true) {
      return;
    }

    try {
      await ChickQueueService.instance.markPickedUp(reservation.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reservation.customerName} marked as picked up.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sale was saved, but the reservation could not '
            'be marked as picked up.',
          ),
        ),
      );
    }
  }

  Future<void> _editReservation(ChickReservation reservation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChickReservationFormScreen(reservation: reservation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        floatingActionButton: !_showHistory
            ? FloatingActionButton.extended(
                heroTag: 'chick_queue_add_reservation',
                onPressed: _addReservation,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add reservation'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chick Queue',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.egg_alt_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Waiting'),
                    icon: Icon(Icons.schedule_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('History'),
                    icon: Icon(Icons.history_rounded),
                  ),
                ],
                selected: {_showHistory},
                onSelectionChanged: (selection) {
                  setState(() {
                    _showHistory = selection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<List<ChickReservation>>(
                stream: ChickQueueService.instance.watchReservations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load chick queue.'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allReservations = snapshot.data!;

                  final waitingReservations = allReservations
                      .where(
                        (reservation) =>
                            reservation.status ==
                            ChickReservationStatus.waiting,
                      )
                      .toList();

                  final displayedReservations = allReservations.where((
                    reservation,
                  ) {
                    if (_showHistory) {
                      return reservation.status !=
                          ChickReservationStatus.waiting;
                    }

                    return reservation.status == ChickReservationStatus.waiting;
                  }).toList();

                  if (displayedReservations.isEmpty) {
                    return Center(
                      child: Text(
                        _showHistory
                            ? 'No history yet.'
                            : 'No customers waiting for chicks.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    itemCount: displayedReservations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final reservation = displayedReservations[index];

                      final showBatchHeader =
                          !_showHistory &&
                          (index == 0 ||
                              !_sameDay(
                                displayedReservations[index - 1].scheduledDate,
                                reservation.scheduledDate,
                              ));

                      final batchReservations = displayedReservations.where(
                        (item) => _sameDay(
                          item.scheduledDate,
                          reservation.scheduledDate,
                        ),
                      );

                      final batchCustomerCount = batchReservations.length;

                      final batchChickCount = batchReservations.fold<int>(
                        0,
                        (total, item) => total + item.quantity,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showBatchHeader) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _date(reservation.scheduledDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$batchCustomerCount '
                                          '${batchCustomerCount == 1 ? 'customer' : 'customers'}'
                                          ' • $batchChickCount chicks',
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: colors.primaryContainer,
                                    child: Text(
                                      _showHistory ? '✓' : '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: colors.onPrimaryContainer,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reservation.customerName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          '${reservation.quantity} chicks',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(height: 3),

                                        Text(
                                          'Batch: '
                                          '${_date(reservation.scheduledDate)}',
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),

                                        if (reservation.note.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            reservation.note,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (!_showHistory)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editReservation(reservation);
                                        }

                                        if (value == 'pickup') {
                                          _pickup(reservation);
                                        }

                                        if (value == 'cancel') {
                                          _cancel(
                                            reservation,
                                            waitingReservations,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined),
                                              SizedBox(width: 12),
                                              Text('Edit reservation'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'pickup',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .shopping_cart_checkout_rounded,
                                              ),
                                              SizedBox(width: 12),
                                              Text('Picked up / Create sale'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'cancel',
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel_outlined),
                                              SizedBox(width: 12),
                                              Text('Cancel reservation'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      reservation.status.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
