import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/money_utils.dart';

enum PaymentMethodType { cash, aba, acleda, other }

extension PaymentMethodTypeX on PaymentMethodType {
  String get code {
    switch (this) {
      case PaymentMethodType.cash:
        return 'cash';
      case PaymentMethodType.aba:
        return 'aba';
      case PaymentMethodType.acleda:
        return 'acleda';
      case PaymentMethodType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.aba:
        return 'ABA QR';
      case PaymentMethodType.acleda:
        return 'ACLEDA QR';
      case PaymentMethodType.other:
        return 'Other';
    }
  }

  static PaymentMethodType fromCode(String code) {
    switch (code) {
      case 'aba':
        return PaymentMethodType.aba;
      case 'acleda':
        return PaymentMethodType.acleda;
      case 'other':
        return PaymentMethodType.other;
      case 'cash':
      default:
        return PaymentMethodType.cash;
    }
  }
}

class CustomerPayment {
  const CustomerPayment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.paidCurrency,
    required this.paidAmountMinor,
    required this.appliedCurrency,
    required this.appliedAmountMinor,
    required this.exchangeRateKhrPerUsd,
    required this.exchangeRateSource,
    required this.exchangeRateFetchedAt,
    required this.method,
    required this.paymentDate,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.exchangeRateDate,
  });

  final String id;

  final String customerId;

  // Snapshot of customer name at payment time.
  final String customerName;

  // What Mom actually received.
  final MoneyCurrency paidCurrency;

  // KHR = whole riel
  // USD = cents
  final int paidAmountMinor;

  // Which debt balance this payment reduces.
  final MoneyCurrency appliedCurrency;

  final int appliedAmountMinor;

  // Example:
  // 1 USD = 4100 KHR
  //
  // Null when there was no currency conversion.
  final int? exchangeRateKhrPerUsd;

  // Examples:
  // "api"
  // "manual"
  // null when no conversion happened.
  final String? exchangeRateSource;

  // When the API exchange rate was retrieved.
  // Null for manual rates or same-currency payments.
  final DateTime? exchangeRateFetchedAt;

  final PaymentMethodType method;

  final DateTime paymentDate;

  // active / voided
  final String status;

  final String note;

  final DateTime createdAt;

  final DateTime? exchangeRateDate;

  factory CustomerPayment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CustomerPayment(
      id: document.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      paidCurrency: MoneyCurrencyX.fromCode(
        data['paidCurrency'] as String? ?? 'KHR',
      ),
      paidAmountMinor: (data['paidAmountMinor'] as num?)?.toInt() ?? 0,
      appliedCurrency: MoneyCurrencyX.fromCode(
        data['appliedCurrency'] as String? ?? 'KHR',
      ),
      appliedAmountMinor: (data['appliedAmountMinor'] as num?)?.toInt() ?? 0,
      exchangeRateKhrPerUsd: (data['exchangeRateKhrPerUsd'] as num?)?.toInt(),
      exchangeRateSource: data['exchangeRateSource'] as String?,
      exchangeRateFetchedAt: (data['exchangeRateFetchedAt'] as Timestamp?)
          ?.toDate(),
      method: PaymentMethodTypeX.fromCode(data['method'] as String? ?? 'cash'),
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'active',
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exchangeRateDate: (data['exchangeRateDate'] as Timestamp?)?.toDate(),
    );
  }
}
