import 'package:cloud_firestore/cloud_firestore.dart';

enum ChickReservationStatus {
  waiting,
  pickedUp,
  cancelled,
}

extension ChickReservationStatusX on ChickReservationStatus {
  String get code {
    switch (this) {
      case ChickReservationStatus.waiting:
        return 'waiting';
      case ChickReservationStatus.pickedUp:
        return 'pickedUp';
      case ChickReservationStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ChickReservationStatus.waiting:
        return 'Waiting';
      case ChickReservationStatus.pickedUp:
        return 'Picked up';
      case ChickReservationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ChickReservationStatus fromCode(
    String value,
  ) {
    switch (value) {
      case 'pickedUp':
        return ChickReservationStatus.pickedUp;
      case 'cancelled':
        return ChickReservationStatus.cancelled;
      case 'waiting':
      default:
        return ChickReservationStatus.waiting;
    }
  }
}

class ChickReservation {
  const ChickReservation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.quantity,
    required this.reservationDate,
    required this.scheduledDate,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String customerId;

  // Snapshot of name when reservation was created.
  final String customerName;

  final int quantity;

  final DateTime reservationDate;

  // Expected chick batch / pickup date.
  final DateTime scheduledDate;

  final ChickReservationStatus status;

  final String note;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChickReservation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return ChickReservation(
      id: document.id,
      customerId:
          data['customerId'] as String? ?? '',
      customerName:
          data['customerName'] as String? ?? '',
      quantity:
          (data['quantity'] as num?)?.toInt() ?? 0,
      reservationDate:
          (data['reservationDate'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
      scheduledDate:
          (data['scheduledDate'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
      status: ChickReservationStatusX.fromCode(
        data['status'] as String? ?? 'waiting',
      ),
      note:
          data['note'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
    );
  }
}
