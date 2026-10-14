import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.isArchived,
    required this.openingDebtKhrMinor,
    required this.openingDebtUsdMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String note;
  final bool isArchived;

  // Debt that already existed before the customer was first tracked in MomBiz.
  // KHR is stored as whole riel. USD is stored in cents.
  final int openingDebtKhrMinor;
  final int openingDebtUsdMinor;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Customer(
      id: document.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      note: data['note'] as String? ?? '',
      isArchived: data['isArchived'] as bool? ?? false,
      openingDebtKhrMinor:
          (data['openingDebtKhrMinor'] as num?)?.toInt() ?? 0,
      openingDebtUsdMinor:
          (data['openingDebtUsdMinor'] as num?)?.toInt() ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
