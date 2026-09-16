import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer.dart';

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
}
