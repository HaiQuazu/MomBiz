import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chick_reservation.dart';
import '../../services/chick_queue_service.dart';
import '../../theme/app_icons.dart';
import '../sales/sale_form_screen.dart';
import 'chick_reservation_form_screen.dart';

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

  Future<void> _addReservation({DateTime? scheduledDate}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChickReservationFormScreen(initialScheduledDate: scheduledDate),
      ),
    );
  }

  Future<void> _editReservation(ChickReservation reservation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChickReservationFormScreen(reservation: reservation),
      ),
    );
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _statusLabel(AppLocalizations l10n, ChickReservationStatus status) {
    switch (status) {
      case ChickReservationStatus.waiting:
        return l10n.waiting;

      case ChickReservationStatus.pickedUp:
        return l10n.pickedUp;

      case ChickReservationStatus.cancelled:
        return l10n.cancelled;
    }
  }

  Future<void> _cancel(
    ChickReservation reservation,
    List<ChickReservation> waitingReservations,
  ) async {
    final l10n = AppLocalizations.of(context)!;

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
        final isKhmer =
            Localizations.localeOf(dialogContext).languageCode == 'km';

        return AlertDialog(
          title: Text(
            l10n.cancelReservationQuestion,
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reservation.customerName} • '
                '${l10n.chickCount(reservation.quantity)}',
              ),

              const SizedBox(height: 10),

              Text(
                l10n.batchDateValue(_date(reservation.scheduledDate)),
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),

              if (nextReservation != null) ...[
                const SizedBox(height: 18),

                Text(
                  l10n.nextCustomer,
                  style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${nextReservation.customerName} • '
                  '${l10n.chickCount(nextReservation.quantity)}',
                ),

                const SizedBox(height: 4),

                Text(
                  l10n.currentBatchValue(_date(nextReservation.scheduledDate)),
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  l10n.moveCustomerForwardQuestion(
                    nextReservation.customerName,
                    _date(reservation.scheduledDate),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'keep');
              },
              child: Text(l10n.keepReservation),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, 'cancelOnly');
              },
              child: Text(l10n.cancelOnly),
            ),

            if (nextReservation != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, 'moveNext');
                },
                child: Text(l10n.cancelAndMoveNext),
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == 'moveNext'
                ? l10n.reservationCancelledAndMoved
                : l10n.reservationCancelled,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotCancelReservation)));
    }
  }

  Future<void> _pickup(ChickReservation reservation) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isKhmer =
            Localizations.localeOf(dialogContext).languageCode == 'km';

        return AlertDialog(
          title: Text(
            l10n.customerPickedUpChicksQuestion,
            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
              fontWeight: isKhmer ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
          content: Text(
            '${reservation.customerName}\n'
            '${l10n.chickCount(reservation.quantity)}\n\n'
            '${l10n.saleCreatedBeforePickup}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.createSale),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.customerMarkedPickedUp(reservation.customerName)),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saleSavedButPickupFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return SafeArea(
      child: Scaffold(
        // ====================================================
        // ADD RESERVATION
        // ====================================================
        floatingActionButton: _showHistory
            ? null
            : FloatingActionButton.extended(
                heroTag: 'chick_queue_add_reservation',
                onPressed: () {
                  _addReservation();
                },
                icon: const Icon(AppIcons.add, size: 21),
                label: Text(l10n.addReservation),
              ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // FIXED HEADER
            // =================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.chickQueue,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: headingWeight,
                      ),
                    ),
                  ),

                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      AppIcons.queue,
                      size: 23,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // FIXED WAITING / HISTORY
            // =================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 240,
                  child: SegmentedButton<bool>(
                    expandedInsets: EdgeInsets.zero,
                    selectedIcon: const Icon(AppIcons.check, size: 18),
                    style: ButtonStyle(
                      visualDensity: const VisualDensity(
                        horizontal: -1,
                        vertical: -2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      textStyle: WidgetStateProperty.resolveWith<TextStyle?>((
                        states,
                      ) {
                        final selected = states.contains(WidgetState.selected);

                        return theme.textTheme.labelLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        );
                      }),
                    ),
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        icon: const Icon(AppIcons.waiting, size: 18),
                        label: Text(
                          l10n.waiting,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(AppIcons.history, size: 18),
                        label: Text(
                          l10n.history,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
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
              ),
            ),

            const SizedBox(height: 14),

            // =================================================
            // ONLY QUEUE LIST SCROLLS
            // =================================================
            Expanded(
              child: StreamBuilder<List<ChickReservation>>(
                stream: ChickQueueService.instance.watchReservations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _QueueMessage(
                      icon: AppIcons.error,
                      message: l10n.couldNotLoadChickQueue,
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
                    return _QueueMessage(
                      icon: _showHistory ? AppIcons.history : AppIcons.queue,
                      message: _showHistory
                          ? l10n.noHistoryYet
                          : l10n.noCustomersWaitingForChicks,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    itemCount: displayedReservations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 9),
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
                            _BatchHeader(
                              date: _date(reservation.scheduledDate),
                              customerText: l10n.customerCount(
                                batchCustomerCount,
                              ),
                              chickText: l10n.chickCount(batchChickCount),
                              onAdd: () {
                                _addReservation(
                                  scheduledDate: reservation.scheduledDate,
                                );
                              },
                              addTooltip: l10n.addReservation,
                            ),

                            const SizedBox(height: 8),
                          ],

                          _ReservationCard(
                            reservation: reservation,
                            position: index + 1,
                            showHistory: _showHistory,
                            statusLabel: _statusLabel(l10n, reservation.status),
                            batchDate: l10n.batchDateValue(
                              _date(reservation.scheduledDate),
                            ),
                            chickCount: l10n.chickCount(reservation.quantity),
                            onEdit: () {
                              _editReservation(reservation);
                            },
                            onPickup: () {
                              _pickup(reservation);
                            },
                            onCancel: () {
                              _cancel(reservation, waitingReservations);
                            },
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

// ============================================================
// BATCH HEADER
// ============================================================

class _BatchHeader extends StatelessWidget {
  const _BatchHeader({
    required this.date,
    required this.customerText,
    required this.chickText,
    required this.onAdd,
    required this.addTooltip,
  });

  final String date;
  final String customerText;
  final String chickText;

  final VoidCallback onAdd;
  final String addTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AppIcons.calendar, size: 20, color: colors.primary),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '$customerText • $chickText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Tooltip(
            message: addTooltip,
            child: IconButton(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              iconSize: 18,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                foregroundColor: colors.primary,
                backgroundColor: colors.surface.withValues(alpha: 0.65),
                minimumSize: const Size(34, 34),
                maximumSize: const Size(34, 34),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RESERVATION CARD
// ============================================================

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.position,
    required this.showHistory,
    required this.statusLabel,
    required this.batchDate,
    required this.chickCount,
    required this.onEdit,
    required this.onPickup,
    required this.onCancel,
  });

  final ChickReservation reservation;

  final int position;
  final bool showHistory;

  final String statusLabel;
  final String batchDate;
  final String chickCount;

  final VoidCallback onEdit;
  final VoidCallback onPickup;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    const cardRadius = 20.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            // ------------------------------------------------
            // POSITION / STATUS ICON
            // ------------------------------------------------
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primaryContainer,
              child: showHistory
                  ? Icon(
                      reservation.status == ChickReservationStatus.pickedUp
                          ? AppIcons.check
                          : AppIcons.close,
                      size: 21,
                      color: colors.onPrimaryContainer,
                    )
                  : Text(
                      '$position',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(width: 13),

            // ------------------------------------------------
            // RESERVATION DETAILS
            // ------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    chickCount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    batchDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  if (reservation.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),

                    Text(
                      reservation.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 6),

            // ------------------------------------------------
            // WAITING ACTION MENU
            // ------------------------------------------------
            if (!showHistory)
              PopupMenuButton<String>(
                icon: const Icon(AppIcons.moreVertical, size: 21),
                tooltip: '',
                elevation: 8,
                offset: const Offset(0, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;

                    case 'pickup':
                      onPickup();
                      break;

                    case 'cancel':
                      onCancel();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(AppIcons.edit, size: 19),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.editReservation)),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'pickup',
                    child: Row(
                      children: [
                        const Icon(AppIcons.sale, size: 19),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.pickedUpCreateSale)),
                      ],
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(AppIcons.cancel, size: 19, color: colors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.cancelReservation,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            // ------------------------------------------------
            // HISTORY STATUS
            // ------------------------------------------------
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: reservation.status == ChickReservationStatus.pickedUp
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY / ERROR
// ============================================================

class _QueueMessage extends StatelessWidget {
  const _QueueMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 32, color: colors.onPrimaryContainer),
            ),

            const SizedBox(height: 14),

            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
