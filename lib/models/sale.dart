import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/money_utils.dart';

class SaleItem {
  const SaleItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
  });

  final String productId;

  // Snapshot values.
  // These stay unchanged even if the product is renamed later.
  final String productName;
  final String unit;

  final int quantity;

  // KHR = whole riel
  // USD = cents
  final int unitPriceMinor;
  final int lineTotalMinor;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'quantity': quantity,
      'unitPriceMinor': unitPriceMinor,
      'lineTotalMinor': lineTotalMinor,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPriceMinor: map['unitPriceMinor'] as int? ?? 0,
      lineTotalMinor: map['lineTotalMinor'] as int? ?? 0,
    );
  }
}

class Sale {
  const Sale({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.buyerName,
    required this.currency,
    required this.items,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.totalMinor,
    required this.saleDate,
    required this.status,
    required this.note,
    required this.createdAt,
  });

  final String id;

  final String customerId;

  // Snapshot so history still makes sense
  // even if customer name changes later.
  final String customerName;

  final String buyerName;

  final MoneyCurrency currency;

  final List<SaleItem> items;

  final int subtotalMinor;
  final int discountMinor;
  final int totalMinor;

  final DateTime saleDate;

  // active / voided
  final String status;

  final String note;

  final DateTime createdAt;

  factory Sale.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final rawItems = data['items'] as List<dynamic>? ?? [];

    return Sale(
      id: document.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      currency: MoneyCurrencyX.fromCode(
        data['currency'] as String? ?? 'KHR',
      ),
      items: rawItems
          .map(
            (item) => SaleItem.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      subtotalMinor: data['subtotalMinor'] as int? ?? 0,
      discountMinor: data['discountMinor'] as int? ?? 0,
      totalMinor: data['totalMinor'] as int? ?? 0,
      saleDate:
          (data['saleDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      status: data['status'] as String? ?? 'active',
      note: data['note'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
    );
  }
}
