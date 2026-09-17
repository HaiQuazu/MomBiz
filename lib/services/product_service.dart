import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import '../utils/money_utils.dart';

class ProductService {
  ProductService._();

  static final ProductService instance =
      ProductService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in.',
      );
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>>
      get _products {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('products');
  }

  Stream<List<Product>> watchProducts({
    required bool archived,
  }) {
    return _products.snapshots().map(
      (snapshot) {
        final products = snapshot.docs
            .map(
              Product.fromFirestore,
            )
            .where(
              (product) =>
                  product.isArchived ==
                  archived,
            )
            .toList();

        products.sort(
          (a, b) => a.name
              .toLowerCase()
              .compareTo(
                b.name.toLowerCase(),
              ),
        );

        return products;
      },
    );
  }

  Future<List<Product>>
      getActiveProducts() async {
    final snapshot =
        await _products.get();

    final products = snapshot.docs
        .map(
          Product.fromFirestore,
        )
        .where(
          (product) =>
              !product.isArchived,
        )
        .toList();

    products.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(
            b.name.toLowerCase(),
          ),
    );

    return products;
  }

  Future<String> addProduct({
    required String name,
    required String category,
    required String unit,
    required int defaultPriceMinor,
    required MoneyCurrency
        defaultPriceCurrency,
  }) async {
    final document =
        _products.doc();

    await document.set({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),

      'defaultPriceMinor':
          defaultPriceMinor,
      'defaultPriceCurrency':
          defaultPriceCurrency.code,

      'isArchived': false,

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String unit,
    required int defaultPriceMinor,
    required MoneyCurrency
        defaultPriceCurrency,
  }) async {
    await _products
        .doc(productId)
        .update({
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),

      'defaultPriceMinor':
          defaultPriceMinor,
      'defaultPriceCurrency':
          defaultPriceCurrency.code,

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveProduct(
    String productId,
  ) async {
    await _products
        .doc(productId)
        .update({
      'isArchived': true,

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreProduct(
    String productId,
  ) async {
    await _products
        .doc(productId)
        .update({
      'isArchived': false,

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}
