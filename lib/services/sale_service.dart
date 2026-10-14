import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';
import '../utils/money_utils.dart';

class SaleUpdateWouldOverpayException implements Exception {
  const SaleUpdateWouldOverpayException(this.currency);

  final MoneyCurrency currency;

  @override
  String toString() =>
      'The edited sale would make payments greater than the customer debt.';
}

class SaleNotEditableException implements Exception {
  const SaleNotEditableException();

  @override
  String toString() => 'This sale can no longer be edited.';
}

class SaleService {
  SaleService._();

  static final SaleService instance = SaleService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>> get _sales =>
      _userDocument.collection('sales');

  CollectionReference<Map<String, dynamic>> get _payments =>
      _userDocument.collection('payments');

  CollectionReference<Map<String, dynamic>> get _customers =>
      _userDocument.collection('customers');

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

  Map<String, dynamic> _saleUpdateData({
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
      // customerId is deliberately not changed when editing a saved sale.
      // This keeps payments and customer history attached to the same account.
      'customerName': customerName,
      'buyerName': buyerName.trim(),
      'currency': currency.code,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotalMinor': subtotalMinor,
      'discountMinor': discountMinor,
      'totalMinor': totalMinor,
      'saleDate': Timestamp.fromDate(saleDate),
      'note': note.trim(),
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
    final userDocument = _userDocument;
    final saleDocument = userDocument.collection('sales').doc();
    final reservationDocument = userDocument
        .collection('chickReservations')
        .doc(reservationId);

    await _firestore.runTransaction((transaction) async {
      final reservationSnapshot = await transaction.get(reservationDocument);

      if (!reservationSnapshot.exists) {
        throw StateError('Chick reservation no longer exists.');
      }

      final reservationData =
          reservationSnapshot.data() ?? const <String, dynamic>{};
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

  Future<void> updateSale({
    required String saleId,
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
    final saleDocument = _sales.doc(saleId);
    final existingSnapshot = await saleDocument.get();

    if (!existingSnapshot.exists) {
      throw const SaleNotEditableException();
    }

    final existingSale = Sale.fromFirestore(existingSnapshot);

    if (existingSale.status != 'active' ||
        existingSale.customerId != customerId ||
        existingSale.currency != currency) {
      throw const SaleNotEditableException();
    }

    await _ensureEditDoesNotCreateCustomerCredit(
      saleId: saleId,
      customerId: customerId,
      currency: currency,
      replacementTotalMinor: totalMinor,
    );

    // Re-check the sale document immediately before writing. This protects
    // against editing a sale that was changed/voided while the form was open.
    await _firestore.runTransaction((transaction) async {
      final latestSnapshot = await transaction.get(saleDocument);

      if (!latestSnapshot.exists) {
        throw const SaleNotEditableException();
      }

      final latestSale = Sale.fromFirestore(latestSnapshot);

      if (latestSale.status != 'active' ||
          latestSale.customerId != customerId ||
          latestSale.currency != currency) {
        throw const SaleNotEditableException();
      }

      transaction.update(
        saleDocument,
        _saleUpdateData(
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
    });
  }

  Future<void> _ensureEditDoesNotCreateCustomerCredit({
    required String saleId,
    required String customerId,
    required MoneyCurrency currency,
    required int replacementTotalMinor,
  }) async {
    final results = await Future.wait([
      _customers.doc(customerId).get(),
      _sales.where('customerId', isEqualTo: customerId).get(),
      _payments.where('customerId', isEqualTo: customerId).get(),
    ]);

    final customerSnapshot =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final salesSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;
    final paymentsSnapshot =
        results[2] as QuerySnapshot<Map<String, dynamic>>;

    final customerData = customerSnapshot.data() ?? const <String, dynamic>{};

    var khrDebt =
        (customerData['openingDebtKhrMinor'] as num?)?.toInt() ?? 0;
    var usdDebt =
        (customerData['openingDebtUsdMinor'] as num?)?.toInt() ?? 0;

    for (final document in salesSnapshot.docs) {
      final sale = Sale.fromFirestore(document);

      if (sale.status != 'active') {
        continue;
      }

      final amount = sale.id == saleId ? replacementTotalMinor : sale.totalMinor;

      if (sale.currency == MoneyCurrency.khr) {
        khrDebt += amount;
      } else {
        usdDebt += amount;
      }
    }

    for (final document in paymentsSnapshot.docs) {
      final data = document.data();
      final status = data['status'] as String? ?? 'active';

      if (status != 'active') {
        continue;
      }

      final appliedCurrency =
          MoneyCurrency.fromCode(data['appliedCurrency'] as String?);
      final appliedAmount =
          (data['appliedAmountMinor'] as num?)?.toInt() ?? 0;

      if (appliedCurrency == MoneyCurrency.khr) {
        khrDebt -= appliedAmount;
      } else {
        usdDebt -= appliedAmount;
      }
    }

    if (currency == MoneyCurrency.khr && khrDebt < 0) {
      throw const SaleUpdateWouldOverpayException(MoneyCurrency.khr);
    }

    if (currency == MoneyCurrency.usd && usdDebt < 0) {
      throw const SaleUpdateWouldOverpayException(MoneyCurrency.usd);
    }
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
