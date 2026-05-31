import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';

const _uuid = Uuid();

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  XFile? _pickedFile;
  String? _imagePath;
  bool _saving = false;
  ClothingCategory _category = ClothingCategory.top;
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final List<String> _tags = [];

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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _pickedFile = file;
      _imagePath = file.path;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;

    if (_pickedFile != null && SupabaseService.isSignedIn) {
      setState(() => _saving = true);
      try {
        await ref
            .read(wardrobeProvider.notifier)
            .addUploadedItem(
              bytes: await _pickedFile!.readAsBytes(),
              fileName: _pickedFile!.name,
              name: _nameController.text,
              brand: _brandController.text.isEmpty
                  ? null
                  : _brandController.text,
              fallbackCategory: _category,
              tags: _tags,
            );
        if (!mounted) return;
        Navigator.pop(context);
        return;
      } catch (_) {
        setState(() => _saving = false);
      }
    }

    final item = ClothingItem(
      id: _uuid.v4(),
      name: _nameController.text,
      brand: _brandController.text.isEmpty ? null : _brandController.text,
      category: _category,
      imageUrl: _imagePath ?? '',
      tags: _tags,
    );

    ref.read(wardrobeProvider.notifier).addItem(item);
    Navigator.pop(context);
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
                color: Colors.grey.withOpacity(0.3),
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
                    onTap: () => _showSourcePicker(context, l10n),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF241E38)
                            : const Color(0xFFEDE9FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.seedColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _saving
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.seedColor,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n?.addItemSaving ?? 'Saving...',
                                  style: TextStyle(
                                    color: AppColors.seedColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : _imagePath != null
                          ? Stack(
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
                                      color: Colors.black.withOpacity(0.6),
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
                                  color: AppColors.seedColor.withOpacity(0.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n?.addItemTapToAddPhoto ??
                                      'Tap to add photo',
                                  style: TextStyle(
                                    color: AppColors.seedColor.withOpacity(0.7),
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
                                : cat.color.withOpacity(0.12),
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
                      hintText: l10n?.addItemNameHint ??
                          'Item name (e.g. White Linen Shirt)',
                      prefixIcon:
                          const Icon(Icons.label_outline_rounded),
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
                                : AppColors.seedColor.withOpacity(0.1),
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
                      onPressed: _save,
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
      builder: (_) => GlassContainer(
        margin: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l10n?.addItemCamera ?? 'Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n?.addItemPhotoLibrary ?? 'Photo Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
