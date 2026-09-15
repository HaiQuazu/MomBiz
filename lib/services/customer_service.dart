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

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('customers');
  }

  Stream<List<Customer>> watchActiveCustomers() {
    return _customers.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(Customer.fromFirestore)
              .where((customer) => !customer.isArchived)
              .toList(),
        );
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String note,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _customers.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'note': note.trim(),
      'isArchived': false,
      'createdAt': now,
      'updatedAt': now,
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
}
