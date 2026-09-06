import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_brand_theme.dart';
import '../models/clothing_item.dart';

class WardrobeImage extends StatelessWidget {
  final ClothingItem item;
  final BoxFit fit;
  final double? width;
  final double? height;

  const WardrobeImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _Fallback(item: item),
      );
    }

    if (imageUrl.isEmpty) return _Fallback(item: item);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => _Fallback(item: item, muted: true),
      errorWidget: (_, __, ___) => _Fallback(item: item),
    );
  }
}

class _Fallback extends StatelessWidget {
  final ClothingItem item;
  final bool muted;

  const _Fallback({required this.item, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Container(
      color: brand.neutralSurface,
      child: Center(
        child: Icon(
          item.category.icon,
          color: item.category.color.withValues(alpha: muted ? 0.5 : 1),
          size: 36,
        ),
      ),
    );
  }
}
