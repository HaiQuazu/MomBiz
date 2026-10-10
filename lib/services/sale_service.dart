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

  Map<String, dynamic> _saleData({
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
  }) {
    return {
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
    };
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

    await document.set(
      _saleData(
        customerId: customerId,
        customerName: customerName,
        buyerName: buyerName,
        currency: currency,
        items: items,
        subtotalMinor: subtotalMinor,
        discountMinor: discountMinor,
        totalMinor: totalMinor,
        saleDate: saleDate,
        note: note,
      ),
    );

    return document.id;
  }

  Future<String> createSaleForChickPickup({
    required String reservationId,
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
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    final userDocument = _firestore.collection('users').doc(user.uid);
    final saleDocument = userDocument.collection('sales').doc();
    final reservationDocument = userDocument
        .collection('chickReservations')
        .doc(reservationId);

    await _firestore.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservationDocument);

      if (!reservationSnapshot.exists) {
        throw StateError('Chick reservation no longer exists.');
      }

      final reservationData = reservationSnapshot.data() ?? const <String, dynamic>{};
      final reservationStatus =
          reservationData['status'] as String? ?? 'waiting';

      if (reservationStatus != 'waiting') {
        throw StateError('Chick reservation is no longer waiting.');
      }

      final reservationCustomerId =
          (reservationData['customerId'] as String?)?.trim();

      if (reservationCustomerId != null &&
          reservationCustomerId.isNotEmpty &&
          reservationCustomerId != customerId) {
        throw StateError('Chick reservation customer does not match the sale.');
      }

      transaction.set(
        saleDocument,
        _saleData(
          customerId: customerId,
          customerName: customerName,
          buyerName: buyerName,
          currency: currency,
          items: items,
          subtotalMinor: subtotalMinor,
          discountMinor: discountMinor,
          totalMinor: totalMinor,
          saleDate: saleDate,
          note: note,
        ),
      );

      transaction.update(reservationDocument, {
        'status': 'pickedUp',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return saleDocument.id;
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
