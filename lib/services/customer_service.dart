import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer.dart';
import 'chick_queue_service.dart';
import 'payment_service.dart';
import 'sale_service.dart';

class CustomerDeleteCheck {
  const CustomerDeleteCheck({
    required this.hasSales,
    required this.hasPayments,
    required this.hasChickReservations,
  });

  final bool hasSales;
  final bool hasPayments;
  final bool hasChickReservations;

  bool get canDelete => !hasSales && !hasPayments && !hasChickReservations;

  bool get hasHistory => !canDelete;
}

class CustomerService {
  CustomerService._();

  static final CustomerService instance = CustomerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _customers {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore.collection('users').doc(user.uid).collection('customers');
  }

  Stream<List<Customer>> watchCustomers({required bool archived}) {
    return _customers.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map(Customer.fromFirestore)
          .where((customer) => customer.isArchived == archived)
          .toList();
    });
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String note,
  }) async {
    await _customers.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'note': note.trim(),
      'isArchived': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    required String note,
  }) async {
    await _customers.doc(customerId).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveCustomer(String customerId) async {
    await _customers.doc(customerId).update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreCustomer(String customerId) async {
    await _customers.doc(customerId).update({
      'isArchived': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Customer?> watchCustomer(String customerId) {
    return _customers.doc(customerId).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return Customer.fromFirestore(document);
    });
  }

  Future<List<Customer>> getActiveCustomers() async {
    final snapshot = await _customers.orderBy('name').get();

    return snapshot.docs
        .map(Customer.fromFirestore)
        .where((customer) => !customer.isArchived)
        .toList();
  }

  // ------------------------------------------------
  // PERMANENT DELETE CHECK
  // ------------------------------------------------
  //
  // A customer may only be permanently deleted when
  // they have NO sales, NO payments, and NO chick
  // reservation/history records.
  //
  // This protects receipts and business history.
  Future<CustomerDeleteCheck> checkDeleteCustomer(String customerId) async {
    final results = await Future.wait([
      SaleService.instance.watchSalesForCustomer(customerId).first,

      PaymentService.instance.watchPaymentsForCustomer(customerId).first,

      ChickQueueService.instance.watchReservations().first,
    ]);

    final sales = results[0] as List;

    final payments = results[1] as List;

    final reservations = results[2] as List;

    final hasChickReservations = reservations.any(
      (reservation) => reservation.customerId == customerId,
    );

    return CustomerDeleteCheck(
      hasSales: sales.isNotEmpty,
      hasPayments: payments.isNotEmpty,
      hasChickReservations: hasChickReservations,
    );
  }

  // ------------------------------------------------
  // PERMANENT DELETE
  // ------------------------------------------------
  //
  // We check again here instead of trusting only
  // the UI. That prevents accidental deletion if
  // history was created after the first check.
  Future<void> deleteCustomer(String customerId) async {
    final check = await checkDeleteCustomer(customerId);

    if (!check.canDelete) {
      throw StateError(
        'Customer has business history and cannot be permanently deleted.',
      );
    }

    await _customers.doc(customerId).delete();
  }
}
