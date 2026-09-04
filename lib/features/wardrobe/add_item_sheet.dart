import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/clothing_analysis_service.dart';
import '../../core/services/image_pick_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/widgets/mmm_bottom_sheet.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({
    super.key,
    this.imagePickService,
    this.fileExists,
    this.quickPickSource,
    this.persistImage,
    this.analyzeImage,
    this.readImage,
    this.deleteImage,
    this.signedIn,
  });

  final ImagePickService? imagePickService;
  final Future<bool> Function(String path)? fileExists;
  final ImageSource? quickPickSource;
  final Future<File> Function(Uint8List bytes, String name)? persistImage;
  final Future<ClothingAnalysisResult> Function(Uint8List bytes)? analyzeImage;
  final Future<Uint8List> Function(XFile file)? readImage;
  final Future<void> Function(String path)? deleteImage;
  final bool? signedIn;

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _analyzing = false;
  bool _saving = false;
  bool _retainLocalImage = false;
  ClothingCategory? _category;
  ClothingAnalysisResult? _localAnalysis;
  ClothingPattern _pattern = ClothingPattern.unknown;
  ClothingSilhouette _silhouette = ClothingSilhouette.unknown;
  double? _analysisConfidence;
  String? _classificationSource;
  String? _colorSource;
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _hexController = TextEditingController();
  final List<String> _colorHexes = [];
  String? _primaryHex;
  final List<String> _tags = [];
  final Set<String> _correctedFields = {};
  final _imageStorage = ImageStorageService();
  final _analysis = const ClothingAnalysisService();

  ImagePickService get _imagePickService =>
      widget.imagePickService ?? ref.read(imagePickServiceProvider);
  Future<bool> _fileExists(String path) =>
      widget.fileExists?.call(path) ?? File(path).exists();
  Future<File> _persistImage(Uint8List bytes, String name) =>
      widget.persistImage?.call(bytes, name) ??
      _imageStorage.persist(bytes, name);
  Future<ClothingAnalysisResult> _analyzeImage(Uint8List bytes) =>
      widget.analyzeImage?.call(bytes) ?? _analysis.analyze(bytes);
  Future<Uint8List> _readImage(XFile file) =>
      widget.readImage?.call(file) ?? file.readAsBytes();
  Future<void> _deleteImage(String path) =>
      widget.deleteImage?.call(path) ?? _imageStorage.deleteOwned(path);
  bool get _isSignedIn => widget.signedIn ?? SupabaseService.isSignedIn;

  static const _tagOptions = [
    'casual',
    'formal',
    'work',
    'sport',
    'summer',
    'winter',
  ];

  String _localizedTag(AppLocalizations? l, String tag) {
    switch (tag) {
      case 'casual':
        return l?.tagCasual ?? tag;
      case 'formal':
        return l?.tagFormal ?? tag;
      case 'work':
        return l?.tagWork ?? tag;
      case 'sport':
        return l?.tagSport ?? tag;
      case 'summer':
        return l?.tagSummer ?? tag;
      case 'winter':
        return l?.tagWinter ?? tag;
      default:
        return tag;
    }
  }

  String _localizedCategory(AppLocalizations? l, ClothingCategory category) {
    switch (category) {
      case ClothingCategory.hat:
        return l?.clothingCategoryHat ?? category.label;
      case ClothingCategory.top:
        return l?.clothingCategoryTop ?? category.label;
      case ClothingCategory.pants:
        return l?.clothingCategoryPants ?? category.label;
      case ClothingCategory.shoes:
        return l?.clothingCategoryShoes ?? category.label;
      case ClothingCategory.outerwear:
        return l?.clothingCategoryOuterwear ?? category.label;
      case ClothingCategory.dress:
        return l?.clothingCategoryDress ?? category.label;
      case ClothingCategory.bag:
        return l?.clothingCategoryBag ?? category.label;
      case ClothingCategory.accessory:
        return l?.clothingCategoryAccessory ?? category.label;
      case ClothingCategory.unknown:
        return l?.clothingCategoryUnknown ?? category.label;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreLostImage());
    });
  }

  @override
  void dispose() {
    final path = _imagePath;
    if (!_retainLocalImage && path != null) unawaited(_deleteImage(path));
    _nameController.dispose();
    _brandController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _restoreLostImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _imagePickService.retrieveLostImage();
      if (file == null) return;
      if (!mounted) return;
      await _setPickedFile(file);
    } on PlatformException catch (error) {
      _showPickerError(error, fromCamera: true);
    } catch (_) {
      _showError(
        l10n?.addItemRecoveryFailed ??
            "We couldn't recover the last photo. Please choose it again.",
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _imagePickService.pickImage(source: source);
      if (file == null) return;
      if (!mounted) return;
      await _setPickedFile(file);
    } on PlatformException catch (error) {
      _showPickerError(error, fromCamera: source == ImageSource.camera);
    } catch (_) {
      _showError(
        source == ImageSource.camera
            ? (l10n?.addItemCameraOpenFailed ??
                  "Couldn't open the camera. Try again or choose a photo.")
            : (l10n?.addItemPhotoLibraryOpenFailed ??
                  "Couldn't open your photo library. Try again."),
      );
    }
  }

  Future<void> _setPickedFile(XFile file) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final analysisFailedMessage =
        l10n?.addItemAnalysisFailed ??
        'Image analysis failed. You can still tag this item manually.';
    final path = file.path;
    if (path.isEmpty) {
      _showError(
        l10n?.addItemImagePathUnavailable ??
            "This image isn't available. Please try again.",
      );
      return;
    }
    final exists = await _fileExists(path);
    if (!exists) {
      _showError(
        l10n?.addItemPhotoUnavailable ??
            'That photo is no longer available. Please choose another.',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _analyzing = true);
    try {
      final bytes = await _readImage(file);
      final managedFile = await _persistImage(bytes, file.name);
      if (!mounted) {
        await _deleteImage(managedFile.path);
        return;
      }
      final previousPath = _imagePath;
      setState(() {
        _pickedFile = XFile(managedFile.path);
        _imageBytes = bytes;
        _imagePath = managedFile.path;
        _category = null;
        _localAnalysis = null;
        _pattern = ClothingPattern.unknown;
        _silhouette = ClothingSilhouette.unknown;
        _analysisConfidence = null;
        _classificationSource = null;
        _colorSource = null;
        _colorHexes.clear();
        _primaryHex = null;
        _correctedFields.clear();
        _tags.clear();
        _hexController.clear();
      });
      if (previousPath != null && previousPath != managedFile.path) {
        await _deleteImage(previousPath);
      }
      try {
        final result = await _analyzeImage(bytes);
        if (!mounted) return;
        setState(() {
          _localAnalysis = result;
          _category = result.category;
          _pattern = result.pattern;
          _silhouette = result.silhouette;
          _analysisConfidence = result.confidence;
          _classificationSource = result.classificationSource;
          _colorSource = result.colorSource;
          _colorHexes
            ..clear()
            ..addAll(
              result.colorHexes
                  .map(normalizeHexColor)
                  .whereType<String>()
                  .toSet(),
            );
          _primaryHex = _colorHexes.firstOrNull;
          _hexController.clear();
          _tags.addAll(result.styles.where((tag) => !_tags.contains(tag)));
        });
      } catch (_) {
        _showError(analysisFailedMessage);
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _addCustomHex() {
    final hex = normalizeHexColor(_hexController.text);
    if (hex == null) {
      _showError(
        AppLocalizations.of(context)?.addItemInvalidHex ??
            'Enter a valid HEX color such as #3366FF.',
      );
      return;
    }
    setState(() {
      final hadPrimary = _primaryHex != null;
      if (!_colorHexes.contains(hex)) _colorHexes.add(hex);
      _primaryHex ??= hex;
      _colorSource = 'manual';
      _correctedFields.add('dominant_colors');
      if (!hadPrimary) _correctedFields.add('primary_color');
      _hexController.clear();
    });
  }

  Color _colorFromHex(String hex) =>
      Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

  Future<void> _save() async {
    if (_saving) return;
    if (_pickedFile == null || _imagePath == null) {
      _showError(
        AppLocalizations.of(context)?.addItemPhotoRequired ??
            'Please add a photo before saving.',
      );
      return;
    }
    if (_category == null) {
      _showError(
        AppLocalizations.of(context)?.addItemCategoryRequired ??
            'Select a category before saving.',
      );
      return;
    }
    final customHex = _hexController.text.trim().isEmpty
        ? null
        : normalizeHexColor(_hexController.text);
    if (_hexController.text.trim().isNotEmpty && customHex == null) {
      _showError(
        AppLocalizations.of(context)?.addItemInvalidHex ??
            'Enter a valid HEX color such as #3366FF.',
      );
      return;
    }
    if (customHex != null && !_colorHexes.contains(customHex)) {
      final hadPrimary = _primaryHex != null;
      _colorHexes.add(customHex);
      _primaryHex ??= customHex;
      _colorSource = 'manual';
      _correctedFields.add('dominant_colors');
      if (!hadPrimary) _correctedFields.add('primary_color');
    }
    final trimmedName = _nameController.text.trim();
    final brand = _brandController.text.trim();

    setState(() => _saving = true);
    try {
      await ref
          .read(wardrobeProvider.notifier)
          .addUploadedItem(
            bytes: _imageBytes ?? await _pickedFile!.readAsBytes(),
            fileName: _isSignedIn ? _pickedFile!.name : _imagePath!,
            name: trimmedName,
            brand: brand.isEmpty ? null : brand,
            fallbackCategory: _category!,
            tags: _tags,
            colorHexes: List.unmodifiable(_colorHexes),
            color: _primaryHex == null ? null : coarseColorName(_primaryHex!),
            pattern: _pattern,
            silhouette: _silhouette,
            analysisConfidence: _analysisConfidence,
            classificationSource: _classificationSource,
            colorSource: _colorSource,
            correctedFields: Set.unmodifiable(_correctedFields),
            localAnalysis: _localAnalysis,
          );
      if (_isSignedIn) {
        try {
          await _deleteImage(_imagePath!);
          _imagePath = null;
        } catch (error) {
          debugPrint('Could not remove uploaded staging image: $error');
        }
      } else {
        _retainLocalImage = true;
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showError(
          AppLocalizations.of(context)?.addItemSaveFailed ??
              'Could not save item. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isPermissionError(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('access_denied') ||
        code.contains('permission') ||
        code.contains('denied');
  }

  void _showPickerError(PlatformException error, {required bool fromCamera}) {
    final l10n = AppLocalizations.of(context);
    if (_isPermissionError(error)) {
      _showError(
        fromCamera
            ? (l10n?.addItemCameraPermissionDenied ??
                  'Camera access is off. Enable it in Settings or choose a photo instead.')
            : (l10n?.addItemPhotoPermissionDenied ??
                  'Photo access is off. Enable it in Settings or choose another photo.'),
      );
      return;
    }
    _showError(
      fromCamera
          ? (l10n?.addItemCaptureFailed ??
                "Couldn't capture a photo. Please try again.")
          : (l10n?.addItemSelectionFailed ??
                "Couldn't select that photo. Please try again."),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = MmmBrandTheme.of(context);

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: BoxDecoration(
        color: brand.raisedSurface,
        borderRadius: AppRadii.sheetBorder,
        border: Border(top: BorderSide(color: brand.subtleBorder)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: brand.subtleBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.addItemTitle ?? 'Add Item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Image picker
                  Semantics(
                    key: const Key('add-item-image-picker'),
                    button: true,
                    label: l10n?.addItemTapToAddPhoto ?? 'Add clothing photo',
                    child: Material(
                      color: brand.subtleAccentSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.cardBorder,
                        side: BorderSide(color: brand.subtleBorder),
                      ),
                      child: InkWell(
                        onTap: _saving || _analyzing
                            ? null
                            : () {
                                final source = widget.quickPickSource;
                                if (source != null) {
                                  _pickImage(source);
                                  return;
                                }
                                _showSourcePicker(context, l10n);
                              },
                        borderRadius: AppRadii.cardBorder,
                        child: SizedBox(
                          height: 160,
                          child: _saving || _analyzing
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MmmLoadingIndicator(
                                      label: _analyzing
                                          ? (l10n?.addItemAnalysisReading ??
                                                'MMM is reading this piece…')
                                          : (l10n?.addItemSaving ??
                                                'Saving...'),
                                    ),
                                  ],
                                )
                              : _imagePath != null
                              ? Stack(
                                  key: const Key('add-item-preview-image'),
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: AppRadii.cardBorder,
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      ),
                                    ),
                                    if (_isSignedIn && _category != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          l10n?.addItemCategoryLabel(
                                                _localizedCategory(
                                                  l10n,
                                                  _category!,
                                                ),
                                              ) ??
                                              'Category: ${_localizedCategory(l10n, _category!)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 36,
                                      color: brand.primaryGradient.colors.first,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n?.addItemTapToAddPhoto ??
                                          'Tap to add photo',
                                      style: TextStyle(
                                        color:
                                            brand.primaryGradient.colors.first,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Category selector
                  Text(
                    l10n?.addItemCategory ?? 'Category',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_category == null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n?.addItemCategoryRequired ?? 'Select category',
                        key: Key('add-item-category-required'),
                        style: TextStyle(color: brand.warning),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ClothingCategory.values.map((cat) {
                      final sel = _category == cat;
                      return MmmChoiceChip(
                        key: Key('add-item-category-${cat.name}'),
                        label: _localizedCategory(l10n, cat),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          _category = cat;
                          _classificationSource = 'manual';
                          _analysisConfidence = null;
                          _correctedFields.add('category');
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Name field
                  TextField(
                    key: const Key('add-item-name'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText:
                          l10n?.addItemNameHint ??
                          'Item name (e.g. White Linen Shirt)',
                      prefixIcon: const Icon(Icons.label_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Brand field
                  TextField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      hintText: l10n?.addItemBrandHint ?? 'Brand (optional)',
                      prefixIcon: const Icon(Icons.store_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.addItemDetectedColors ?? 'Detected colors',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_colorHexes.isEmpty)
                    Text(l10n?.addItemNoColors ?? 'No colors selected')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorHexes.map((hex) {
                        final primary = hex == _primaryHex;
                        return InputChip(
                          key: Key('add-item-color-$hex'),
                          selected: primary,
                          avatar: CircleAvatar(
                            backgroundColor: _colorFromHex(hex),
                          ),
                          label: Text(hex),
                          onSelected: (_) => setState(() {
                            if (_primaryHex != hex) {
                              _correctedFields.add('primary_color');
                            }
                            _primaryHex = hex;
                            _colorSource = 'manual';
                          }),
                          onDeleted: () => setState(() {
                            _colorHexes.remove(hex);
                            _colorSource = 'manual';
                            _correctedFields.add('dominant_colors');
                            if (primary) {
                              _primaryHex = _colorHexes.firstOrNull;
                              _correctedFields.add('primary_color');
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('add-item-hex'),
                    controller: _hexController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n?.addItemAddHex ?? 'Add custom HEX',
                      hintText: '#3366FF',
                      prefixIcon: Icon(Icons.palette_outlined),
                      suffixIcon: IconButton(
                        key: const Key('add-item-add-hex'),
                        onPressed: _addCustomHex,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(_pattern),
                          child: DropdownButtonFormField<ClothingPattern>(
                            key: const Key('add-item-pattern'),
                            initialValue: _pattern,
                            decoration: InputDecoration(
                              labelText: l10n?.addItemPattern ?? 'Pattern',
                            ),
                            items: ClothingPattern.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() {
                              _pattern = value!;
                              _classificationSource = 'manual';
                              _analysisConfidence = null;
                              _correctedFields.add('pattern');
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KeyedSubtree(
                          key: ValueKey(_silhouette),
                          child: DropdownButtonFormField<ClothingSilhouette>(
                            key: const Key('add-item-silhouette'),
                            initialValue: _silhouette,
                            decoration: InputDecoration(
                              labelText:
                                  l10n?.addItemSilhouette ?? 'Silhouette',
                            ),
                            items: ClothingSilhouette.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() {
                              _silhouette = value!;
                              _classificationSource = 'manual';
                              _analysisConfidence = null;
                              _correctedFields.add('silhouette');
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tags
                  Text(
                    l10n?.addItemTags ?? 'Tags',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tagOptions.map((tag) {
                      final sel = _tags.contains(tag);
                      return MmmChoiceChip(
                        label: _localizedTag(l10n, tag),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          sel ? _tags.remove(tag) : _tags.add(tag);
                          _classificationSource = 'manual';
                          _analysisConfidence = null;
                          _correctedFields.add('tags');
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: KeyedSubtree(
                      key: const Key('add-item-save'),
                      child: MmmGradientButton(
                        label: l10n?.addItemSave ?? 'Add to wardrobe',
                        icon: Icons.check_rounded,
                        isLoading: _saving,
                        onPressed: _saving || _analyzing ? null : _save,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSourcePicker(BuildContext context, AppLocalizations? l10n) {
    MmmBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('add-item-source-camera'),
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text(l10n?.addItemCamera ?? 'Camera'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            key: const Key('add-item-source-gallery'),
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(l10n?.addItemPhotoLibrary ?? 'Photo Library'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
