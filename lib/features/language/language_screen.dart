import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/layout/mmm_entry_layout.dart';
import '../../shared/widgets/mmm_brand_mark.dart';
import '../../shared/widgets/mmm_gradient_button.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.fromSettings) {
      _selected = ref.read(localeProvider).languageCode;
    }
  }

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null) return;
    await ref.read(localeProvider.notifier).setLocale(selected);
    if (!mounted) return;
    if (widget.fromSettings) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: widget.fromSettings ? AppBar(leading: const BackButton()) : null,
      body: MmmEntryLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: MmmBrandMark(size: _markSize(context))),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              l10n?.languageScreenTitle ?? 'Choose your language',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n?.languageScreenSubtitle ?? 'เลือกภาษา',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _LanguageOption(
              asset: 'assets/images/flag_gb.png',
              label: l10n?.languageEnglish ?? 'English',
              selected: _selected == 'en',
              onTap: () => setState(() => _selected = 'en'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _LanguageOption(
              asset: 'assets/images/flag_th.png',
              label: l10n?.languageThai ?? 'ภาษาไทย',
              selected: _selected == 'th',
              onTap: () => setState(() => _selected = 'th'),
            ),
          ],
        ),
        footer: MmmGradientButton(
          label: l10n?.languageContinue ?? 'Continue',
          onPressed: _selected == null ? null : _continue,
        ),
      ),
    );
  }

  double _markSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    if (AppBreakpoints.veryLargeText(context) || height < 650 || width < 360) {
      return 112;
    }
    return 144;
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = MmmBrandTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? brand.subtleAccentSurface : brand.raisedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(
            color: selected
                ? brand.primaryGradient.colors.first
                : brand.subtleBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.compactBorder,
                    child: Image.asset(
                      asset,
                      width: 40,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: brand.primaryGradient.colors.first,
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
