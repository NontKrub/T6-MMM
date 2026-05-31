import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/avatar_customization_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../shared/models/user_profile.dart';
import 'widgets/avatar_viewer.dart';
import 'widgets/repetition_insight_card.dart';
import '../outfit_generator/outfit_generator_sheet.dart';
import '../outfit_generator/in_a_rush_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final skinTone = ref.watch(skinToneIndexProvider);
    final hairColor = ref.watch(hairColorIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F0E1A), const Color(0xFF1A1628)]
                    : [const Color(0xFFF0EEFF), const Color(0xFFF8F7FF)],
              ),
            ),
          ),
          // Ambient glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.seedColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(10),
                          borderRadius: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.seedColor,
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0]
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(10),
                          borderRadius: 14,
                          child: const Icon(Icons.settings_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                // Avatar area with customize overlay
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: AvatarViewer(
                          avatarType: profile.avatarType,
                          skinToneIndex: skinTone,
                          hairColorIndex: hairColor,
                        ),
                      ),
                      // Customize button — top-right corner of avatar area
                      Positioned(
                        top: 0,
                        right: 24,
                        child: GestureDetector(
                          onTap: () => _showCustomizeSheet(context, ref),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            borderRadius: 20,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: 14,
                                  color: AppColors.seedColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Customize',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.seedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                      ),
                    ],
                  ),
                ),
                // Bottom section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    children: [
                      // Express (In a Rush) button — above Generate Outfit
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showInARush(context, ref),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.accentGold,
                                  Color(0xFFFF6B35),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGold.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        )
                            .animate(delay: 400.ms)
                            .scale(duration: 400.ms, curve: Curves.elasticOut),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _showOutfitGenerator(context, ref),
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                              ),
                              label: const Text('Generate Outfit'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.seedColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 12),
                      const RepetitionInsightCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOutfitGenerator(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutfitGeneratorSheet(ref: ref),
    );
  }

  void _showInARush(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => InARushModal(ref: ref),
    );
  }

  void _showCustomizeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarCustomizeSheet(ref: ref),
    );
  }
}

// ─── Avatar Customize Sheet ───────────────────────────────────────────────────

class _AvatarCustomizeSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _AvatarCustomizeSheet({required this.ref});

  static const _skinTones = [
    Color(0xFFF5E6D3),
    Color(0xFFE8C4A0),
    Color(0xFFC89B6E),
    Color(0xFF8B5A2B),
    Color(0xFF4A2F1A),
  ];

  static const _hairColors = [
    Color(0xFF12090A),
    Color(0xFF2C1810),
    Color(0xFF6B3A2A),
    Color(0xFFC9A96E),
    Color(0xFF8B3A1C),
    Color(0xFFD4CFC8),
  ];

  static const _hairLabels = [
    'Black',
    'Dark',
    'Brown',
    'Blonde',
    'Auburn',
    'Platinum',
  ];

  static const _avatarMeta = [
    (AvatarType.human, Icons.person_rounded, 'Human'),
    (AvatarType.dog, Icons.pets_rounded, 'Dog'),
    (AvatarType.cat, Icons.catching_pokemon_rounded, 'Cat'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final profile = widgetRef.watch(userProfileProvider);
    final skinTone = widgetRef.watch(skinToneIndexProvider);
    final hairColor = widgetRef.watch(hairColorIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = isDark
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.82);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: sheetBg,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Your Avatar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar type — 3 cards, pick one
              Row(
                children: _avatarMeta.map((meta) {
                  final (type, icon, label) = meta;
                  final selected = profile.avatarType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widgetRef
                          .read(userProfileProvider.notifier)
                          .updateAvatarType(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: selected
                              ? null
                              : AppColors.seedColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: selected
                              ? null
                              : Border.all(
                                  color: Colors.grey.withValues(alpha: 0.18),
                                ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.seedColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              size: 26,
                              color: selected
                                  ? Colors.white
                                  : AppColors.seedColor.withValues(alpha: 0.70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.grey,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Skin & hair only for human
              if (profile.avatarType == AvatarType.human) ...[
                const SizedBox(height: 24),
                _SectionLabel(label: 'Skin Tone'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_skinTones.length, (i) {
                    final sel = skinTone == i;
                    return GestureDetector(
                      onTap: () =>
                          widgetRef.read(skinToneIndexProvider.notifier).state =
                              i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _skinTones[i],
                          border: sel
                              ? Border.all(color: AppColors.seedColor, width: 3)
                              : Border.all(
                                  color: Colors.grey.withValues(alpha: 0.20),
                                  width: 1.5,
                                ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: _skinTones[i].withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                _SectionLabel(label: 'Hair'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_hairColors.length, (i) {
                    final sel = hairColor == i;
                    return GestureDetector(
                      onTap: () =>
                          widgetRef
                                  .read(hairColorIndexProvider.notifier)
                                  .state =
                              i,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hairColors[i],
                              border: sel
                                  ? Border.all(
                                      color: AppColors.seedColor,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: Colors.grey.withValues(
                                        alpha: 0.20,
                                      ),
                                      width: 1.5,
                                    ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: _hairColors[i].withValues(
                                          alpha: 0.50,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _hairLabels[i],
                            style: TextStyle(
                              fontSize: 9,
                              color: sel
                                  ? AppColors.seedColor
                                  : Colors.grey.withValues(alpha: 0.55),
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.seedColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.withValues(alpha: 0.65),
        letterSpacing: 0.5,
      ),
    );
  }
}
