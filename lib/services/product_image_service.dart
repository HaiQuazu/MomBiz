import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductImageService {
  ProductImageService._();

  static final ProductImageService instance =
      ProductImageService._();

  static const _preferencePrefix =
      'local_product_image';

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

  String _key(
    String productId,
  ) {
    return '${_preferencePrefix}_${_userId}_$productId';
  }

  Future<String?> getImagePath(
    String productId,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final path =
        preferences.getString(
      _key(productId),
    );

    if (path == null ||
        path.trim().isEmpty) {
      return null;
    }

    final file =
        File(path);

    if (await file.exists()) {
      return path;
    }

    await preferences.remove(
      _key(productId),
    );

    return null;
  }

  Future<String> saveImage({
    required String productId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception(
        'Image is empty.',
      );
    }

    const maxBytes =
        5 * 1024 * 1024;

    if (bytes.length > maxBytes) {
      throw Exception(
        'Image is larger than 5 MB.',
      );
    }

    final preferences =
        await SharedPreferences.getInstance();

    final previousPath =
        await getImagePath(
      productId,
    );

    final supportDirectory =
        await getApplicationSupportDirectory();

    final productDirectory =
        Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      'product_images'
      '${Platform.pathSeparator}'
      '$_userId',
    );

    if (!await productDirectory.exists()) {
      await productDirectory.create(
        recursive: true,
      );
    }

    final extension =
        _safeExtension(
      originalFileName,
    );

    final fileName =
        '${productId}_'
        '${DateTime.now().microsecondsSinceEpoch}'
        '.$extension';

    final file =
        File(
      '${productDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    await preferences.setString(
      _key(productId),
      file.path,
    );

    if (previousPath != null &&
        previousPath != file.path) {
      final oldFile =
          File(previousPath);

      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {
          // The new local image is already safely saved.
        }
      }
    }

    return file.path;
  }

  Future<void> removeImage(
    String productId,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final path =
        await getImagePath(
      productId,
    );

    if (path != null) {
      final file =
          File(path);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Still clear the saved path below.
        }
      }
    }

    await preferences.remove(
      _key(productId),
    );
  }

  String _safeExtension(
    String fileName,
  ) {
    final lower =
        fileName.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'png';
    }

    if (lower.endsWith('.webp')) {
      return 'webp';
    }

    if (lower.endsWith('.jpeg')) {
      return 'jpeg';
    }

    return 'jpg';
  }
}
