import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';
import '../utils/money_utils.dart';

class SaleService {
  SaleService._();

  static final SaleService instance = SaleService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _sales {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore.collection('users').doc(user.uid).collection('sales');
  }

  Future<String> createSale({
    required String customerId,
    required String customerName,
    required String buyerName,
    required MoneyCurrency currency,
    required List<SaleItem> items,
    required int subtotalMinor,
    required int discountMinor,
    required int totalMinor,
    required DateTime saleDate,
    required String note,
  }) async {
    final document = _sales.doc();

    await document.set({
      'customerId': customerId,
      'customerName': customerName,
      'buyerName': buyerName.trim(),
      'currency': currency.code,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotalMinor': subtotalMinor,
      'discountMinor': discountMinor,
      'totalMinor': totalMinor,
      'saleDate': Timestamp.fromDate(saleDate),
      'status': 'active',
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<List<Sale>> watchSalesForCustomer(String customerId) {
    return _sales.where('customerId', isEqualTo: customerId).snapshots().map((
      snapshot,
    ) {
      final sales = snapshot.docs.map(Sale.fromFirestore).toList();

      sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      return sales;
    });
  }

  Stream<List<Sale>> watchAllSales() {
    return _sales.snapshots().map((snapshot) {
      final sales = snapshot.docs.map(Sale.fromFirestore).toList();

      sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

      return sales;
    });
  }

  Future<Sale?> getSale(String saleId) async {
    final document = await _sales.doc(saleId).get();

    if (!document.exists) {
      return null;
    }

    return Sale.fromFirestore(document);
  }
}
