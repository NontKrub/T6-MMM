import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/user_profile_provider.dart';
import '../../core/services/image_pick_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/mmm_bottom_sheet.dart';
import '../../shared/widgets/mmm_dialog.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import 'profile_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final String _initialName;
  late final ProfileAvatarMode _initialAvatarMode;
  late final String? _initialAvatarPath;
  late ProfileAvatarMode _avatarMode;
  late String? _avatarPath;
  Uint8List? _avatarBytes;
  String _avatarName = 'profile.png';
  bool _saving = false;

  UserProfile get _profile => ref.read(userProfileProvider);

  bool get _dirty =>
      _nameController.text.trim() != _initialName ||
      _avatarMode != _initialAvatarMode ||
      _avatarPath != _initialAvatarPath ||
      _avatarBytes != null;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _initialName = profile.name;
    _initialAvatarMode = profile.avatarMode;
    _initialAvatarPath = profile.avatarPath;
    _avatarMode = profile.avatarMode;
    _avatarPath = profile.avatarPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreLostPhoto());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = _profile.copyWith(
      avatarMode: _avatarMode,
      avatarPath: _avatarPath,
      avatarDisplayUrl:
          _avatarPath != null &&
              (_avatarPath!.startsWith('/') ||
                  _avatarPath!.startsWith('file://'))
          ? _avatarPath
          : null,
    );
    return PopScope<void>(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving || !_dirty) return;
        if (!await _confirmDiscard()) return;
        if (!mounted || !context.mounted) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n?.commonBack ?? 'Back',
            onPressed: () async {
              if (await _confirmDiscard()) {
                if (context.mounted) context.pop();
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(l10n?.profileEditTitle ?? 'Edit profile'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Center(
              child: ProfileAvatar(
                profile: preview,
                bytes: _avatarBytes,
                size: 112,
                onTap: _showPhotoOptions,
                showEditBadge: true,
                semanticLabel: l10n?.profilePhoto ?? 'Profile photo',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _showPhotoOptions,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n?.profileChangePhoto ?? 'Change photo'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            MmmSurfaceCard(
              child: TextField(
                controller: _nameController,
                enabled: !_saving,
                maxLength: 50,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n?.profileDisplayName ?? 'Display name',
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    _saving ||
                        !_dirty ||
                        _validateName(_nameController.text.trim(), l10n) != null
                    ? null
                    : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n?.profileSave ?? 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final choice = await MmmBottomSheet.show<_PhotoChoice>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n?.profileChangePhoto ?? 'Change photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _photoOption(
            icon: Icons.photo_library_outlined,
            label: l10n?.profileChooseFromPhotos ?? 'Choose from Photos',
            value: _PhotoChoice.gallery,
          ),
          _photoOption(
            icon: Icons.camera_alt_outlined,
            label: l10n?.profileTakePhoto ?? 'Take photo',
            value: _PhotoChoice.camera,
          ),
          if (_profile.avatarUrl?.isNotEmpty == true)
            _photoOption(
              icon: Icons.account_circle_outlined,
              label: l10n?.profileUseAccountPhoto ?? 'Use account photo',
              value: _PhotoChoice.provider,
            ),
          if (_avatarMode != ProfileAvatarMode.none)
            _photoOption(
              icon: Icons.hide_image_outlined,
              label: l10n?.profileRemovePhoto ?? 'Remove photo',
              value: _PhotoChoice.none,
            ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == _PhotoChoice.gallery || choice == _PhotoChoice.camera) {
      await _pick(
        choice == _PhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      return;
    }
    setState(() {
      _avatarMode = switch (choice) {
        _PhotoChoice.provider => ProfileAvatarMode.provider,
        _PhotoChoice.none => ProfileAvatarMode.none,
        _ => _avatarMode,
      };
      _avatarPath = null;
      _avatarBytes = null;
    });
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required _PhotoChoice value,
  }) => ListTile(
    minVerticalPadding: 8,
    leading: Icon(icon),
    title: Text(label),
    onTap: () => Navigator.pop(context, value),
  );

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await ref
          .read(imagePickServiceProvider)
          .pickImage(source: source, imageQuality: 90);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarMode = ProfileAvatarMode.custom;
        _avatarPath = null;
        _avatarBytes = bytes;
        _avatarName = file.name;
      });
    } catch (error) {
      debugPrint('Profile photo selection failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.profileChangePhotoFailed ??
                'That photo could not be used. Try another image.',
          ),
        ),
      );
    }
  }

  Future<void> _restoreLostPhoto() async {
    try {
      final file = await ref.read(imagePickServiceProvider).retrieveLostImage();
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarMode = ProfileAvatarMode.custom;
        _avatarPath = null;
        _avatarBytes = bytes;
        _avatarName = file.name;
      });
    } catch (error) {
      debugPrint('Lost profile photo recovery failed: $error');
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final error = _validateName(name, l10n);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateIdentity(
            displayName: name,
            avatarMode: _avatarMode,
            avatarPath: _avatarPath,
            customAvatarBytes: _avatarBytes,
            customAvatarName: _avatarName,
          );
      if (mounted) context.pop();
    } catch (error) {
      debugPrint('Profile identity update failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.profileIdentitySaveFailed ??
                'Profile changes could not be saved.',
          ),
        ),
      );
    }
  }

  String? _validateName(String value, AppLocalizations? l10n) {
    if (value.isEmpty) {
      return l10n?.profileDisplayNameRequired ?? 'Enter a display name.';
    }
    if (value.runes.length > 50 ||
        RegExp(r'[\u0000-\u001F\u007F]').hasMatch(value)) {
      return l10n?.profileDisplayNameInvalid ??
          'Use 50 characters or fewer without control characters.';
    }
    return null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving || !mounted) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await MmmDialog.show<bool>(
      context: context,
      title: Text(l10n?.profileDiscardTitle ?? 'Discard changes?'),
      content: Text(
        l10n?.profileDiscardMessage ??
            'Your profile edits have not been saved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.profileKeepEditing ?? 'Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n?.profileDiscard ?? 'Discard'),
        ),
      ],
    );
    return discard == true;
  }
}

enum _PhotoChoice { gallery, camera, provider, none }
