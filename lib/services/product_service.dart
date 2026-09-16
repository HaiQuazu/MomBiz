import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';

class ProductService {
  ProductService._();

  static final ProductService instance = ProductService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _products {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore.collection('users').doc(user.uid).collection('products');
  }

  Stream<List<Product>> watchProducts({required bool archived}) {
    return _products.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map(Product.fromFirestore)
          .where((product) => product.isArchived == archived)
          .toList();
    });
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String unit,
  }) async {
    await _products.add({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'isArchived': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String unit,
  }) async {
    await _products.doc(productId).update({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveProduct(String productId) async {
    await _products.doc(productId).update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreProduct(String productId) async {
    await _products.doc(productId).update({
      'isArchived': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Product>> getActiveProducts() async {
    final snapshot = await _products.orderBy('name').get();

    return snapshot.docs
        .map(Product.fromFirestore)
        .where((product) => !product.isArchived)
        .toList();
  }
}
