import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/avatar_customization_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_secondary_button.dart';
import '../../shared/models/user_profile.dart';
import 'widgets/avatar_viewer.dart';
import 'widgets/repetition_insight_card.dart';
import '../outfit_generator/outfit_generator_sheet.dart';
import '../outfit_generator/in_a_rush_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final skinTone = ref.watch(skinToneIndexProvider);
    final hairColor = ref.watch(hairColorIndexProvider);
    final bodyShape = ref.watch(bodyShapeProvider);
    final hairStyle = ref.watch(hairStyleIndexProvider);
    final brand = MmmBrandTheme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final avatarHeight =
                AppBreakpoints.largeText(context) || constraints.maxHeight < 700
                ? 200.0
                : math
                      .min(360, math.max(220, constraints.maxHeight * .48))
                      .toDouble();
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Semantics(
                              button: true,
                              label: l10n?.commonProfile ?? 'Open profile',
                              child: Material(
                                color: brand.raisedSurface,
                                borderRadius: AppRadii.controlBorder,
                                child: InkWell(
                                  onTap: () => context.push('/profile'),
                                  borderRadius: AppRadii.controlBorder,
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.xs,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: brand
                                              .primaryGradient
                                              .colors
                                              .first,
                                          child: Text(
                                            profile.name.isNotEmpty
                                                ? profile.name[0]
                                                : 'A',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Flexible(
                                          child: Text(
                                            profile.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: l10n?.commonSettings ?? 'Settings',
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: AppSpacing.screen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.homeGreeting(profile.name) ??
                                'Good morning, ${profile.name}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n?.homePrompt ?? 'What are we wearing today?',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: avatarHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl,
                            ),
                            child: AvatarViewer(
                              avatarType: profile.avatarType,
                              bodyShape: bodyShape,
                              skinToneIndex: skinTone,
                              hairColorIndex: hairColor,
                              hairStyleIndex: hairStyle,
                            ),
                          ),
                          Positioned(
                            right: AppSpacing.lg,
                            top: AppSpacing.xs,
                            child: Material(
                              color: brand.raisedSurface,
                              borderRadius: AppRadii.compactBorder,
                              child: IconButton(
                                tooltip: l10n?.homeCustomize ?? 'Customize',
                                onPressed: () =>
                                    _showCustomizeSheet(context, ref),
                                icon: const Icon(Icons.auto_fix_high_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: MmmGradientButton(
                              label:
                                  l10n?.homeGenerateOutfit ?? 'Generate Outfit',
                              icon: Icons.auto_awesome_rounded,
                              onPressed: () =>
                                  _showOutfitGenerator(context, ref),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: MmmSecondaryButton(
                              label: l10n?.rushTitle ?? 'In a Rush',
                              icon: Icons.bolt_rounded,
                              onPressed: () => _showInARush(context, ref),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const RepetitionInsightCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
    Color(0xFFF5E6D3), // 0: porcelain
    Color(0xFFE8C4A0), // 1: light warm
    Color(0xFFC89B6E), // 2: medium
    Color(0xFFB07840), // 3: medium-tan
    Color(0xFF9A6235), // 4: medium-warm
    Color(0xFF8B5A2B), // 5: medium-dark
    Color(0xFF4A2F1A), // 6: deep
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
    (AvatarType.cat, Icons.cruelty_free, 'Cat'),
  ];

  static const _bodyShapeMeta = [
    (AvatarBodyShape.female, Icons.woman_rounded, 'Female'),
    (AvatarBodyShape.male, Icons.man_rounded, 'Male'),
  ];

  static const _hairStyleKeys = [
    'Tousled',
    'Side Swept',
    'Undercut',
    'Long',
    'Ponytail',
    'Bob',
  ];

  String _localizedAvatarLabel(AppLocalizations? l, String key) =>
      switch (key) {
        'Human' => l?.avatarHuman ?? key,
        'Dog' => l?.avatarDog ?? key,
        'Cat' => l?.avatarCat ?? key,
        _ => key,
      };

  String _localizedBodyShapeLabel(AppLocalizations? l, String key) =>
      switch (key) {
        'Female' => l?.avatarFemale ?? key,
        'Male' => l?.avatarMale ?? key,
        _ => key,
      };

  String _localizedHairStyle(AppLocalizations? l, String key) => switch (key) {
    'Tousled' => l?.avatarHairTousled ?? key,
    'Side Swept' => l?.avatarHairSideSwept ?? key,
    'Undercut' => l?.avatarHairUndercut ?? key,
    'Long' => l?.avatarHairLong ?? key,
    'Ponytail' => l?.avatarHairPonytail ?? key,
    'Bob' => l?.avatarHairBob ?? key,
    _ => key,
  };

  String _localizedHairColor(AppLocalizations? l, String key) => switch (key) {
    'Black' => l?.avatarHairBlack ?? key,
    'Dark' => l?.avatarHairDark ?? key,
    'Brown' => l?.avatarHairBrown ?? key,
    'Blonde' => l?.avatarHairBlonde ?? key,
    'Auburn' => l?.avatarHairAuburn ?? key,
    'Platinum' => l?.avatarHairPlatinum ?? key,
    _ => key,
  };

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final l10n = AppLocalizations.of(context);
    final brand = MmmBrandTheme.of(context);
    final profile = widgetRef.watch(userProfileProvider);
    final skinTone = widgetRef.watch(skinToneIndexProvider);
    final hairColor = widgetRef.watch(hairColorIndexProvider);
    final bodyShape = widgetRef.watch(bodyShapeProvider);
    final hairStyle = widgetRef.watch(hairStyleIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = math.max(
      36.0,
      MediaQuery.viewInsetsOf(context).bottom +
          AppSpacing.lg +
          MediaQuery.paddingOf(context).bottom,
    );

    final sheetBg = isDark
        ? Colors.black.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.82);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: sheetBg,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset),
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
                    l10n?.avatarTitle ?? 'Your Avatar',
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
                        child: _AvatarChoiceTarget(
                          label: _localizedAvatarLabel(l10n, label),
                          selected: selected,
                          onTap: () => widgetRef
                              .read(userProfileProvider.notifier)
                              .updateAvatarType(type),
                          child: AnimatedContainer(
                            duration: AppMotion.duration(
                              context,
                              const Duration(milliseconds: 220),
                            ),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: selected ? brand.primaryGradient : null,
                              color: selected
                                  ? null
                                  : brand.subtleAccentSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: selected
                                  ? null
                                  : Border.all(color: brand.subtleBorder),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: brand
                                            .primaryGradient
                                            .colors
                                            .first
                                            .withValues(alpha: 0.25),
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
                                      : brand.primaryGradient.colors.first
                                            .withValues(alpha: 0.70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _localizedAvatarLabel(l10n, label),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
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

                  // Human-only customization
                  if (profile.avatarType == AvatarType.human) ...[
                    const SizedBox(height: 24),

                    // Body shape
                    _SectionLabel(label: l10n?.avatarBodyShape ?? 'Body Shape'),
                    const SizedBox(height: 10),
                    Row(
                      children: _bodyShapeMeta.map((meta) {
                        final (shape, icon, label) = meta;
                        final sel = bodyShape == shape;
                        return Expanded(
                          child: _AvatarChoiceTarget(
                            label: _localizedBodyShapeLabel(l10n, label),
                            selected: sel,
                            onTap: () {
                              widgetRef.read(bodyShapeProvider.notifier).state =
                                  shape;
                              widgetRef
                                  .read(userProfileProvider.notifier)
                                  .updateBodyShape(shape);
                            },
                            child: AnimatedContainer(
                              duration: AppMotion.duration(
                                context,
                                const Duration(milliseconds: 220),
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: sel ? brand.primaryGradient : null,
                                color: sel ? null : brand.subtleAccentSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: sel
                                    ? null
                                    : Border.all(color: brand.subtleBorder),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: brand
                                              .primaryGradient
                                              .colors
                                              .first
                                              .withValues(alpha: 0.25),
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
                                    color: sel
                                        ? Colors.white
                                        : brand.primaryGradient.colors.first
                                              .withValues(alpha: 0.70),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _localizedBodyShapeLabel(l10n, label),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (sel) ...[
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
                    const SizedBox(height: 22),

                    // Hair style
                    _SectionLabel(label: l10n?.avatarHairStyle ?? 'Hair Style'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_hairStyleKeys.length, (i) {
                        final sel = hairStyle == i;
                        return _AvatarChoiceTarget(
                          label: _localizedHairStyle(l10n, _hairStyleKeys[i]),
                          selected: sel,
                          onTap: () {
                            widgetRef
                                    .read(hairStyleIndexProvider.notifier)
                                    .state =
                                i;
                            widgetRef
                                .read(userProfileProvider.notifier)
                                .updateHairStyleIndex(i);
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.duration(
                              context,
                              const Duration(milliseconds: 200),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: sel ? brand.primaryGradient : null,
                              color: sel ? null : brand.subtleAccentSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: sel
                                  ? null
                                  : Border.all(color: brand.subtleBorder),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: brand
                                            .primaryGradient
                                            .colors
                                            .first
                                            .withValues(alpha: 0.20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _localizedHairStyle(l10n, _hairStyleKeys[i]),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    _SectionLabel(label: l10n?.avatarSkinTone ?? 'Skin Tone'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_skinTones.length, (i) {
                        final sel = skinTone == i;
                        return _AvatarChoiceTarget(
                          label:
                              '${l10n?.avatarSkinTone ?? 'Skin tone'} ${i + 1}',
                          selected: sel,
                          onTap: () {
                            widgetRef
                                    .read(skinToneIndexProvider.notifier)
                                    .state =
                                i;
                            widgetRef
                                .read(userProfileProvider.notifier)
                                .updateSkinToneIndex(i);
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.duration(
                              context,
                              const Duration(milliseconds: 200),
                            ),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _skinTones[i],
                              border: sel
                                  ? Border.all(
                                      color: brand.primaryGradient.colors.first,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: brand.subtleBorder,
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
                    _SectionLabel(label: l10n?.avatarHair ?? 'Hair'),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: List.generate(_hairColors.length, (i) {
                        final sel = hairColor == i;
                        return _AvatarChoiceTarget(
                          label: _localizedHairColor(l10n, _hairLabels[i]),
                          selected: sel,
                          onTap: () {
                            widgetRef
                                    .read(hairColorIndexProvider.notifier)
                                    .state =
                                i;
                            widgetRef
                                .read(userProfileProvider.notifier)
                                .updateHairColorIndex(i);
                          },
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: AppMotion.duration(
                                  context,
                                  const Duration(milliseconds: 200),
                                ),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hairColors[i],
                                  border: sel
                                      ? Border.all(
                                          color: brand
                                              .primaryGradient
                                              .colors
                                              .first,
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: brand.subtleBorder,
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
                                _localizedHairColor(l10n, _hairLabels[i]),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: sel
                                      ? brand.primaryGradient.colors.first
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                    child: MmmGradientButton(
                      label: l10n?.avatarDone ?? 'Done',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChoiceTarget extends StatelessWidget {
  const _AvatarChoiceTarget({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    onTap: onTap,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.controlBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(child: ExcludeSemantics(child: child)),
        ),
      ),
    ),
  );
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
