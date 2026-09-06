import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';

class MmmSecondaryButton extends StatelessWidget {
  const MmmSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 52),
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.controlBorder,
        ),
      ),
    ),
  );
}
