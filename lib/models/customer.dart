import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String note;
  final bool isArchived;
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
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
