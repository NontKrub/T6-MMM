import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../../shared/models/user_profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    super.key,
    this.size = 88,
    this.bytes,
    this.onTap,
    this.showEditBadge = false,
    this.semanticLabel,
  });

  final UserProfile profile;
  final double size;
  final Uint8List? bytes;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: SizedBox.square(dimension: size, child: _image(context)),
        ),
        if (showEditBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: MmmBrandTheme.of(context).raisedSurface,
                  width: 3,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.edit_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
    final labeled = Semantics(
      button: onTap != null,
      label: semanticLabel ?? 'Profile photo for ${profile.name}',
      child: child,
    );
    return onTap == null
        ? labeled
        : InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(padding: const EdgeInsets.all(4), child: labeled),
          );
  }

  Widget _image(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: BoxFit.cover);
    }
    final url = profile.avatarMode == ProfileAvatarMode.custom
        ? profile.avatarDisplayUrl ?? profile.avatarPath
        : profile.avatarMode == ProfileAvatarMode.provider
        ? profile.avatarUrl
        : null;
    if (url == null || url.isEmpty) return _fallback(context);
    if (url.startsWith('/') || url.startsWith('file://')) {
      return Image.file(
        File(url.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return _fallback(context);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => _fallback(context, muted: true),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context, {bool muted = false}) {
    final brand = MmmBrandTheme.of(context);
    final initial = profile.name.trim().isEmpty
        ? 'M'
        : String.fromCharCode(profile.name.trim().runes.first).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(color: brand.neutralSurface),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: muted
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
