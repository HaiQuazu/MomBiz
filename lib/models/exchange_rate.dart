import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeRate {
  const ExchangeRate({
    required this.khrPerUsd,
    required this.rateDate,
    required this.source,
    required this.updatedAt,
  });

  // Example:
  // 1 USD = 4,010 KHR
  final int khrPerUsd;

  // Date that this official NBC rate applies to.
  final DateTime rateDate;

  // For now this will be "NBC".
  final String source;

  // When MomBiz saved/updated this value.
  final DateTime updatedAt;

  factory ExchangeRate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return ExchangeRate(
      khrPerUsd:
          (data['khrPerUsd'] as num?)?.toInt() ?? 0,
      rateDate:
          (data['rateDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      source: data['source'] as String? ?? 'NBC',
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }
}
