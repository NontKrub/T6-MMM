import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/clothing_analysis_service.dart';
import '../../core/services/image_pick_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';

const _uuid = Uuid();

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({
    super.key,
    this.imagePickService,
    this.fileExists,
    this.quickPickSource,
    this.persistImage,
    this.analyzeImage,
    this.readImage,
  });

  final ImagePickService? imagePickService;
  final Future<bool> Function(String path)? fileExists;
  final ImageSource? quickPickSource;
  final Future<File> Function(Uint8List bytes, String name)? persistImage;
  final Future<ClothingAnalysisResult> Function(Uint8List bytes)? analyzeImage;
  final Future<Uint8List> Function(XFile file)? readImage;

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _analyzing = false;
  bool _saving = false;
  ClothingCategory _category = ClothingCategory.top;
  ClothingPattern _pattern = ClothingPattern.unknown;
  ClothingSilhouette _silhouette = ClothingSilhouette.unknown;
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _hexController = TextEditingController();
  final List<String> _tags = [];
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

  @override
  void initState() {
    super.initState();
    _restoreLostImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _restoreLostImage() async {
    try {
      final file = await _imagePickService.retrieveLostImage();
      if (file == null) return;
      await _setPickedFile(file);
    } on PlatformException catch (error) {
      _showPickerError(error, fromCamera: true);
    } catch (_) {
      _showError('Unable to recover your last camera photo.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePickService.pickImage(source: source);
      if (file == null) return;
      await _setPickedFile(file);
    } on PlatformException catch (error) {
      _showPickerError(error, fromCamera: source == ImageSource.camera);
    } catch (_) {
      _showError(
        source == ImageSource.camera
            ? 'Could not open the camera.'
            : 'Could not open the photo library.',
      );
    }
  }

  Future<void> _setPickedFile(XFile file) async {
    final path = file.path;
    if (path.isEmpty) {
      _showError('Image path is unavailable. Please try again.');
      return;
    }
    final exists = await _fileExists(path);
    if (!exists) {
      _showError(
        'Selected photo is no longer available. Please pick or take another photo.',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _analyzing = true);
    try {
      final bytes = await _readImage(file);
      final managedFile = await _persistImage(bytes, file.name);
      if (!mounted) return;
      setState(() {
        _pickedFile = XFile(managedFile.path);
        _imageBytes = bytes;
        _imagePath = managedFile.path;
      });
      try {
        final result = await _analyzeImage(bytes);
        if (!mounted) return;
        setState(() {
          if (result.category != null) _category = result.category!;
          _pattern = result.pattern;
          _silhouette = result.silhouette;
          _hexController.text = result.colorHexes.firstOrNull ?? '';
          _tags.addAll(result.styles.where((tag) => !_tags.contains(tag)));
        });
      } catch (_) {
        _showError(
          'Color analysis failed. You can still tag this item manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_pickedFile == null || _imagePath == null) {
      _showError('Please add a photo before saving.');
      return;
    }

    final hex = _hexController.text.trim().isEmpty
        ? null
        : normalizeHexColor(_hexController.text);
    if (_hexController.text.trim().isNotEmpty && hex == null) {
      _showError('Enter a valid HEX color such as #3366FF.');
      return;
    }
    final trimmedName = _nameController.text.trim();
    final itemName = trimmedName.isNotEmpty ? trimmedName : 'Wardrobe item';
    final brand = _brandController.text.trim();

    if (SupabaseService.isSignedIn) {
      setState(() => _saving = true);
      try {
        await ref
            .read(wardrobeProvider.notifier)
            .addUploadedItem(
              bytes: _imageBytes ?? await _pickedFile!.readAsBytes(),
              fileName: _pickedFile!.name,
              name: trimmedName,
              brand: brand.isEmpty ? null : brand,
              fallbackCategory: _category,
              tags: _tags,
              colorHexes: hex == null ? const [] : [hex],
              color: hex == null ? null : coarseColorName(hex),
              pattern: _pattern,
              silhouette: _silhouette,
            );
        if (!mounted) return;
        Navigator.pop(context);
        return;
      } catch (error) {
        if (mounted) {
          _showError('Could not save item: $error');
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    }

    final item = ClothingItem(
      id: _uuid.v4(),
      name: itemName,
      brand: brand.isEmpty ? null : brand,
      category: _category,
      imageUrl: _imagePath!,
      tags: _tags,
      color: hex == null ? null : coarseColorName(hex),
      colorHexes: hex == null ? const [] : [hex],
      pattern: _pattern,
      silhouette: _silhouette,
    );

    ref.read(wardrobeProvider.notifier).addItem(item);
    Navigator.pop(context);
  }

  bool _isPermissionError(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('access_denied') ||
        code.contains('permission') ||
        code.contains('denied');
  }

  void _showPickerError(PlatformException error, {required bool fromCamera}) {
    if (_isPermissionError(error)) {
      _showError(
        fromCamera
            ? 'Camera permission is denied. Enable camera access in Settings.'
            : 'Photo library permission is denied. Enable photo access in Settings.',
      );
      return;
    }
    _showError(
      fromCamera
          ? 'Could not capture photo (${error.code}).'
          : 'Could not select photo (${error.code}).',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1628) : const Color(0xFFF8F7FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
                  GestureDetector(
                    key: const Key('add-item-image-picker'),
                    onTap: () {
                      final source = widget.quickPickSource;
                      if (source != null) {
                        _pickImage(source);
                        return;
                      }
                      _showSourcePicker(context, l10n);
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF241E38)
                            : const Color(0xFFEDE9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.seedColor.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _saving || _analyzing
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.seedColor,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _analyzing
                                      ? 'Analyzing colors on device...'
                                      : (l10n?.addItemSaving ?? 'Saving...'),
                                  style: TextStyle(
                                    color: AppColors.seedColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : _imagePath != null
                          ? Stack(
                              key: const Key('add-item-preview-image'),
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 160,
                                  ),
                                ),
                                if (SupabaseService.isSignedIn)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      l10n?.addItemCategoryLabel(
                                            _category.label,
                                          ) ??
                                          'Category: ${_category.label}',
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
                                  color: AppColors.seedColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n?.addItemTapToAddPhoto ??
                                      'Tap to add photo',
                                  style: TextStyle(
                                    color: AppColors.seedColor.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ClothingCategory.values.map((cat) {
                      final sel = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? cat.color
                                : cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 14,
                                color: sel ? Colors.white : cat.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: sel ? Colors.white : cat.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Name field
                  TextField(
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
                  TextField(
                    key: const Key('add-item-hex'),
                    controller: _hexController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Primary color (HEX)',
                      hintText: '#3366FF',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ClothingPattern>(
                          key: const Key('add-item-pattern'),
                          initialValue: _pattern,
                          decoration: const InputDecoration(
                            labelText: 'Pattern',
                          ),
                          items: ClothingPattern.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _pattern = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ClothingSilhouette>(
                          key: const Key('add-item-silhouette'),
                          initialValue: _silhouette,
                          decoration: const InputDecoration(
                            labelText: 'Silhouette',
                          ),
                          items: ClothingSilhouette.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _silhouette = value!),
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
                      return GestureDetector(
                        onTap: () => setState(() {
                          sel ? _tags.remove(tag) : _tags.add(tag);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.seedColor
                                : AppColors.seedColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _localizedTag(l10n, tag),
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.seedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('add-item-save'),
                      onPressed: _saving || _analyzing ? null : _save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l10n?.addItemSave ?? 'Save to Wardrobe'),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (sheetContext) => SafeArea(
        child: GlassContainer(
          margin: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
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
          ),
        ),
      ),
    );
  }
}
