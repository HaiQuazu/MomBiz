import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chick_reservation.dart';

class ChickQueueService {
  ChickQueueService._();

  static final ChickQueueService instance = ChickQueueService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _reservations {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chickReservations');
  }

  Stream<List<ChickReservation>> watchReservations() {
    return _reservations.snapshots().map((snapshot) {
      final reservations = snapshot.docs
          .map(ChickReservation.fromFirestore)
          .toList();

      reservations.sort((a, b) {
        final scheduledComparison = a.scheduledDate.compareTo(b.scheduledDate);

        if (scheduledComparison != 0) {
          return scheduledComparison;
        }

        return a.createdAt.compareTo(b.createdAt);
      });

      return reservations;
    });
  }

  Future<void> addReservation({
    required String customerId,
    required String customerName,
    required int quantity,
    required DateTime reservationDate,
    required DateTime scheduledDate,
    required String note,
  }) async {
    await _reservations.add({
      'customerId': customerId,
      'customerName': customerName,
      'quantity': quantity,
      'reservationDate': Timestamp.fromDate(reservationDate),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': 'waiting',
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelReservation(String reservationId) async {
    await _reservations.doc(reservationId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markPickedUp(String reservationId) async {
    await _reservations.doc(reservationId).update({
      'status': 'pickedUp',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAndMoveNext({
    required String cancelledReservationId,
    required String? nextReservationId,
    required DateTime? newScheduledDate,
  }) async {
    final batch = _firestore.batch();

    final cancelledRef = _reservations.doc(cancelledReservationId);

    batch.update(cancelledRef, {
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (nextReservationId != null && newScheduledDate != null) {
      final nextRef = _reservations.doc(nextReservationId);

      batch.update(nextRef, {
        'scheduledDate': Timestamp.fromDate(newScheduledDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<DateTime?> getLastWaitingBatchDate() async {
    final snapshot = await _reservations.get();

    final waiting = snapshot.docs
        .map(ChickReservation.fromFirestore)
        .where(
          (reservation) => reservation.status == ChickReservationStatus.waiting,
        )
        .toList();

    if (waiting.isEmpty) {
      return null;
    }

    waiting.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return waiting.first.scheduledDate;
  }

  Future<void> updateReservation({
    required String reservationId,
    required String customerId,
    required String customerName,
    required int quantity,
    required DateTime reservationDate,
    required DateTime scheduledDate,
    required String note,
  }) async {
    await _reservations.doc(reservationId).update({
      'customerId': customerId,
      'customerName': customerName,
      'quantity': quantity,
      'reservationDate': Timestamp.fromDate(reservationDate),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
