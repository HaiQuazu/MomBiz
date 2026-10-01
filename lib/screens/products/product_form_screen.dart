import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_image_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
  });

  final Product? product;

  @override
  State<ProductFormScreen> createState() =>
      _ProductFormScreenState();
}

class _ProductFormScreenState
    extends State<ProductFormScreen> {
  final _nameController =
      TextEditingController();

  final _categoryController =
      TextEditingController();

  final _unitController =
      TextEditingController();

  final _priceController =
      TextEditingController();

  final ImagePicker _imagePicker =
      ImagePicker();

  MoneyCurrency _priceCurrency =
      MoneyCurrency.khr;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  String? _existingImagePath;

  bool _removeExistingImage = false;
  bool _pickingImage = false;
  bool _saving = false;

  bool get _isEditing =>
      widget.product != null;

  bool get _hasExistingImage =>
      !_removeExistingImage &&
      _existingImagePath != null &&
      _existingImagePath!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    final product =
        widget.product;

    if (product != null) {
      _nameController.text =
          product.name;

      _categoryController.text =
          product.category;

      _unitController.text =
          product.unit;

      _priceCurrency =
          product.defaultPriceCurrency;

      if (product.defaultPriceMinor >
          0) {
        _priceController.text =
            _editablePrice(
          product.defaultPriceMinor,
          product.defaultPriceCurrency,
        );
      }

      _loadExistingImage();
    }
  }

  Future<void>
      _loadExistingImage() async {
    final product =
        widget.product;

    if (product == null) {
      return;
    }

    try {
      final path =
          await ProductImageService
              .instance
              .getImagePath(
        product.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _existingImagePath =
            path;
      });
    } catch (_) {
      // Product photos are optional.
      // A local image lookup failure must not block the form.
    }
  }

  String _text({
    required String en,
    required String km,
  }) {
    return Localizations.localeOf(context)
                .languageCode ==
            'km'
        ? km
        : en;
  }

  String _editablePrice(
    int amountMinor,
    MoneyCurrency currency,
  ) {
    switch (currency) {
      case MoneyCurrency.khr:
        return amountMinor.toString();

      case MoneyCurrency.usd:
        final dollars =
            amountMinor ~/ 100;

        final cents =
            amountMinor % 100;

        if (cents == 0) {
          return dollars.toString();
        }

        return '$dollars.'
            '${cents.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickImage() async {
    if (_saving ||
        _pickingImage) {
      return;
    }

    setState(() {
      _pickingImage = true;
    });

    try {
      final image =
          await _imagePicker.pickImage(
        source:
            ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final bytes =
          await image.readAsBytes();

      const maxBytes =
          5 * 1024 * 1024;

      if (bytes.length >
          maxBytes) {
        if (!mounted) {
          return;
        }

        _showError(
          _text(
            en:
                'Please choose an image smaller than 5 MB.',
            km:
                'សូមជ្រើសរើសរូបភាពដែលមានទំហំតិចជាង 5 MB។',
          ),
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pickedImage =
            image;

        _pickedImageBytes =
            bytes;

        _removeExistingImage =
            false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        _text(
          en:
              'Could not choose the photo.',
          km:
              'មិនអាចជ្រើសរើសរូបភាពបានទេ។',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingImage =
              false;
        });
      }
    }
  }

  void _removeImage() {
    if (_saving) {
      return;
    }

    setState(() {
      _pickedImage =
          null;

      _pickedImageBytes =
          null;

      _removeExistingImage =
          _existingImagePath != null;
    });
  }

  Future<void> _save() async {
    final l10n =
        AppLocalizations.of(context)!;

    final name =
        _nameController.text.trim();

    final category =
        _categoryController.text.trim();

    final unit =
        _unitController.text.trim();

    if (name.isEmpty) {
      _showError(
        l10n.pleaseEnterProductName,
      );
      return;
    }

    if (category.isEmpty) {
      _showError(
        l10n.pleaseEnterCategory,
      );
      return;
    }

    if (unit.isEmpty) {
      _showError(
        l10n.pleaseEnterUnit,
      );
      return;
    }

    var defaultPriceMinor = 0;

    final priceText =
        _priceController.text.trim();

    if (priceText.isNotEmpty) {
      final parsed =
          MoneyUtils.parse(
        priceText,
        _priceCurrency,
      );

      if (parsed == null ||
          parsed < 0) {
        _showError(
          l10n.pleaseEnterValidDefaultPrice,
        );
        return;
      }

      defaultPriceMinor =
          parsed;
    }

    setState(() {
      _saving = true;
    });

    String? localPhotoWarning;

    try {
      late final String productId;

      if (_isEditing) {
        productId =
            widget.product!.id;

        await ProductService.instance
            .updateProduct(
          productId: productId,
          name: name,
          category: category,
          unit: unit,
          defaultPriceMinor:
              defaultPriceMinor,
          defaultPriceCurrency:
              _priceCurrency,
        );
      } else {
        productId =
            await ProductService.instance
                .addProduct(
          name: name,
          category: category,
          unit: unit,
          defaultPriceMinor:
              defaultPriceMinor,
          defaultPriceCurrency:
              _priceCurrency,
        );
      }

      try {
        final bytes =
            _pickedImageBytes;

        final image =
            _pickedImage;

        if (bytes != null &&
            image != null) {
          await ProductImageService
              .instance
              .saveImage(
            productId: productId,
            bytes: bytes,
            originalFileName:
                image.name,
          );
        } else if (_isEditing &&
            _removeExistingImage) {
          await ProductImageService
              .instance
              .removeImage(
            productId,
          );
        }
      } catch (_) {
        localPhotoWarning =
            _text(
          en:
              'The product was saved, but the photo could not be saved on this phone. Edit the product and try the photo again.',
          km:
              'ផលិតផលត្រូវបានរក្សាទុក ប៉ុន្តែមិនអាចរក្សារូបភាពនៅលើទូរស័ព្ទនេះបានទេ។ សូមកែផលិតផល ហើយសាកល្បងរូបភាពម្តងទៀត។',
        );
      }

      if (!mounted) {
        return;
      }

      if (localPhotoWarning !=
          null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              localPhotoWarning,
            ),
          ),
        );
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        _isEditing
            ? l10n
                .couldNotUpdateProduct
            : l10n
                .couldNotAddProduct,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _priceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final l10n =
        AppLocalizations.of(context)!;

    final isKhmer =
        Localizations.localeOf(context)
                .languageCode ==
            'km';

    final pageTitleWeight =
        isKhmer
            ? FontWeight.w600
            : FontWeight.w700;

    final sectionTitleWeight =
        isKhmer
            ? FontWeight.w500
            : FontWeight.w600;

    final hasAnyImage =
        _pickedImageBytes != null ||
            _hasExistingImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.editProduct
              : l10n.addProduct,
          style: theme
              .textTheme.titleLarge
              ?.copyWith(
            fontWeight:
                pageTitleWeight,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            140,
          ),
          children: [
            // -------------------------
            // PRODUCT PHOTO
            // -------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    _text(
                      en:
                          'Product photo',
                      km:
                          'រូបភាពផលិតផល',
                    ),
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                          sectionTitleWeight,
                    ),
                  ),
                ),

                Text(
                  l10n.optional,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: colors
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Material(
              color: colors
                  .surfaceContainerLow,
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: InkWell(
                onTap: _saving
                    ? null
                    : _pickImage,
                child: SizedBox(
                  height: 180,
                  width:
                      double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ProductPhotoPreview(
                        pickedBytes:
                            _pickedImageBytes,
                        existingImagePath:
                            _hasExistingImage
                                ? _existingImagePath
                                : null,
                      ),

                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Material(
                          color: colors
                              .surface
                              .withValues(
                            alpha: 0.92,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                if (_pickingImage)
                                  const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                else
                                  Icon(
                                    hasAnyImage
                                        ? AppIcons
                                            .edit
                                        : AppIcons
                                            .add,
                                    size: 17,
                                    color:
                                        colors
                                            .primary,
                                  ),

                                const SizedBox(
                                  width: 7,
                                ),

                                Text(
                                  hasAnyImage
                                      ? _text(
                                          en:
                                              'Change',
                                          km:
                                              'ប្តូរ',
                                        )
                                      : _text(
                                          en:
                                              'Choose photo',
                                          km:
                                              'ជ្រើសរូបភាព',
                                        ),
                                  style: theme
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                    color:
                                        colors
                                            .primary,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (hasAnyImage) ...[
              const SizedBox(
                height: 6,
              ),

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving
                      ? null
                      : _removeImage,
                  icon: Icon(
                    AppIcons.close,
                    size: 17,
                    color:
                        colors.error,
                  ),
                  label: Text(
                    _text(
                      en:
                          'Remove photo',
                      km:
                          'លុបរូបភាព',
                    ),
                    style: TextStyle(
                      color:
                          colors.error,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            // -------------------------
            // PRODUCT NAME
            // -------------------------
            TextField(
              controller:
                  _nameController,
              enabled: !_saving,
              textCapitalization:
                  TextCapitalization
                      .words,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  InputDecoration(
                labelText:
                    l10n.productName,
                hintText:
                    l10n
                        .exampleChickenFood,
                prefixIcon:
                    const Icon(
                  AppIcons.product,
                  size: 21,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------
            // CATEGORY
            // -------------------------
            TextField(
              controller:
                  _categoryController,
              enabled: !_saving,
              textCapitalization:
                  TextCapitalization
                      .words,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  InputDecoration(
                labelText:
                    l10n.category,
                hintText:
                    l10n.exampleFeed,
                prefixIcon:
                    const Icon(
                  AppIcons
                      .productCategory,
                  size: 21,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // -------------------------
            // UNIT
            // -------------------------
            TextField(
              controller:
                  _unitController,
              enabled: !_saving,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  InputDecoration(
                labelText:
                    l10n.unit,
                hintText:
                    l10n.exampleUnits,
                prefixIcon:
                    const Icon(
                  AppIcons.unit,
                  size: 21,
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // -------------------------
            // DEFAULT PRICE
            // -------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.defaultPrice,
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                          sectionTitleWeight,
                    ),
                  ),
                ),
                Text(
                  l10n.optional,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: colors
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Center(
              child:
                  SegmentedButton<
                      MoneyCurrency>(
                segments: const [
                  ButtonSegment<
                      MoneyCurrency>(
                    value:
                        MoneyCurrency.khr,
                    label:
                        Text('KHR ៛'),
                  ),
                  ButtonSegment<
                      MoneyCurrency>(
                    value:
                        MoneyCurrency.usd,
                    label:
                        Text('USD \$'),
                  ),
                ],
                selected: {
                  _priceCurrency,
                },
                onSelectionChanged:
                    _saving
                        ? null
                        : (selection) {
                            final newCurrency =
                                selection
                                    .first;

                            if (newCurrency ==
                                _priceCurrency) {
                              return;
                            }

                            setState(() {
                              _priceCurrency =
                                  newCurrency;

                              _priceController
                                  .clear();
                            });
                          },
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller:
                  _priceController,
              enabled: !_saving,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              decoration:
                  InputDecoration(
                labelText:
                    l10n.defaultPrice,
                hintText: _priceCurrency ==
                        MoneyCurrency.khr
                    ? l10n
                        .example65000
                    : l10n
                        .example1600,
                prefixIcon:
                    const Icon(
                  AppIcons.price,
                  size: 21,
                ),
                prefixText:
                    _priceCurrency ==
                            MoneyCurrency
                                .usd
                        ? '\$ '
                        : null,
                suffixText:
                    _priceCurrency ==
                            MoneyCurrency
                                .khr
                        ? '៛'
                        : null,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              l10n.defaultPriceOptional,
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color:
                    colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),

      bottomSheet: SafeArea(
        child: Container(
          color: theme
              .scaffoldBackgroundColor,
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          child: FilledButton.icon(
            onPressed:
                _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    AppIcons.check,
                    size: 20,
                  ),
            label: Text(
              _saving
                  ? l10n.saving
                  : _isEditing
                      ? l10n
                          .saveChanges
                      : l10n
                          .addProduct,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductPhotoPreview
    extends StatelessWidget {
  const _ProductPhotoPreview({
    required this.pickedBytes,
    required this.existingImagePath,
  });

  final Uint8List? pickedBytes;
  final String? existingImagePath;

  @override
  Widget build(BuildContext context) {
    final bytes =
        pickedBytes;

    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    final path =
        existingImagePath;

    if (path != null &&
        path.trim().isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder:
            (context, error, stackTrace) {
          return _placeholder(
            context,
          );
        },
      );
    }

    return _placeholder(
      context,
    );
  }

  Widget _placeholder(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(context)
                .languageCode ==
            'km';

    return Container(
      alignment:
          Alignment.center,
      color: colors.primaryContainer
          .withValues(
        alpha: 0.5,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            AppIcons.product,
            size: 38,
            color: colors
                .onPrimaryContainer,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            isKhmer
                ? 'បន្ថែមរូបភាពផលិតផល'
                : 'Add product photo',
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: colors
                  .onPrimaryContainer,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
