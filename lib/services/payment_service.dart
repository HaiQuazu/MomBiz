import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_payment.dart';
import '../utils/money_utils.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _payments {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore.collection('users').doc(user.uid).collection('payments');
  }

  Stream<List<CustomerPayment>> watchPaymentsForCustomer(String customerId) {
    return _payments.where('customerId', isEqualTo: customerId).snapshots().map(
      (snapshot) {
        final payments = snapshot.docs
            .map(CustomerPayment.fromFirestore)
            .toList();

        payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

        return payments;
      },
    );
  }

  Future<String> createPayment({
    required String customerId,
    required String customerName,
    required MoneyCurrency paidCurrency,
    required int paidAmountMinor,
    required MoneyCurrency appliedCurrency,
    required int appliedAmountMinor,
    required int? exchangeRateKhrPerUsd,
    required String? exchangeRateSource,
    required DateTime? exchangeRateFetchedAt,
    required PaymentMethodType method,
    required DateTime paymentDate,
    required String note,
    required DateTime? exchangeRateDate,
  }) async {
    final document = _payments.doc();

    await document.set({
      'customerId': customerId,

      'customerName': customerName,

      'paidCurrency': paidCurrency.code,

      'paidAmountMinor': paidAmountMinor,

      'appliedCurrency': appliedCurrency.code,

      'appliedAmountMinor': appliedAmountMinor,

      'exchangeRateKhrPerUsd': exchangeRateKhrPerUsd,

      'exchangeRateSource': exchangeRateSource,

      'exchangeRateFetchedAt': exchangeRateFetchedAt == null
          ? null
          : Timestamp.fromDate(exchangeRateFetchedAt),

      'method': method.code,

      'paymentDate': Timestamp.fromDate(paymentDate),

      'status': 'active',

      'note': note.trim(),

      'createdAt': FieldValue.serverTimestamp(),

      'updatedAt': FieldValue.serverTimestamp(),

      'exchangeRateDate': exchangeRateDate == null
          ? null
          : Timestamp.fromDate(exchangeRateDate),
    });

    return document.id;
  }

  Stream<List<CustomerPayment>> watchAllPayments() {
    return _payments.snapshots().map((snapshot) {
      final payments = snapshot.docs
          .map(CustomerPayment.fromFirestore)
          .toList();

      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      return payments;
    });
  }
}
