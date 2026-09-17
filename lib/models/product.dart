import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/money_utils.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.defaultPriceMinor,
    required this.defaultPriceCurrency,
  });

  final String id;
  final String name;
  final String category;
  final String unit;

  final int defaultPriceMinor;
  final MoneyCurrency defaultPriceCurrency;

  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Product(
      id: document.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      defaultPriceMinor: (data['defaultPriceMinor'] as num?)?.toInt() ?? 0,
      defaultPriceCurrency: MoneyCurrency.fromCode(
        data['defaultPriceCurrency'] as String? ?? 'KHR',
      ),
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
