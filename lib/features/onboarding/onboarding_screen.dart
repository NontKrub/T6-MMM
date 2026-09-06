import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_progress_indicator.dart';
import '../../shared/widgets/mmm_surface_card.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({
    super.key,
    this.isGuest = false,
    this.returnLocation,
  });

  final bool isGuest;
  final String? returnLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final steps = <Widget>[
      if (isGuest)
        _AboutYouStep(
          name: state.name,
          birthDate: state.birthDate,
          onNameChanged: notifier.setName,
          onBirthDateChanged: notifier.setBirthDate,
        ),
      _StyleStep(selected: state.styles, onToggle: notifier.toggleStyle),
      _FitStep(selected: state.bodyType, onSelect: notifier.setBodyType),
      _ColorSeasonStep(
        selected: state.colorSeason,
        onSelect: notifier.setColorSeason,
      ),
      _OccasionStep(
        selected: state.occasions,
        onToggle: notifier.toggleOccasion,
      ),
    ];
    final step = state.step.clamp(0, steps.length - 1);
    final isLastStep = step == steps.length - 1;
    final canContinue = !(isGuest && step == 0 && state.name.trim().isEmpty);

    void continueFlow() {
      if (!isLastStep) {
        notifier.nextStep();
        return;
      }
      if (isGuest) {
        if (state.name.trim().isNotEmpty) {
          ref.read(userProfileProvider.notifier).updateName(state.name.trim());
        }
        if (state.birthDate != null) {
          ref
              .read(userProfileProvider.notifier)
              .updateBirthDate(state.birthDate!);
        }
      }
      final profile = ref.read(userProfileProvider.notifier);
      profile.updateStylePreferences(state.styles);
      profile.updateOccasions(state.occasions);
      profile.updateOnboardingDetails(
        bodyType: state.bodyType,
        colorSeason: state.colorSeason == null
            ? null
            : colorSeasonFromString(state.colorSeason!),
      );
      profile.completeOnboarding();
      context.go(returnLocation ?? '/home');
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: step > 0
                        ? IconButton(
                            tooltip: l10n?.onboardingBack ?? 'Back',
                            onPressed: notifier.prevStep,
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    l10n?.onboardingStep(step + 1, steps.length) ??
                        '${step + 1} of ${steps.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: MmmProgressIndicator(
                value: (step + 1) / steps.length,
                label: l10n?.onboardingProgress ?? 'Onboarding progress',
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.transition),
                switchInCurve: AppMotion.curve,
                child: KeyedSubtree(key: ValueKey(step), child: steps[step]),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: MmmGradientButton(
                  label: isLastStep
                      ? (l10n?.onboardingEnter ?? 'Enter MMM')
                      : (l10n?.onboardingContinue ?? 'Continue'),
                  onPressed: canContinue ? continueFlow : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xl,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        child,
      ],
    ),
  );
}

class _AboutYouStep extends StatefulWidget {
  const _AboutYouStep({
    required this.name,
    required this.birthDate,
    required this.onNameChanged,
    required this.onBirthDateChanged,
  });

  final String name;
  final DateTime? birthDate;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<DateTime> onBirthDateChanged;

  @override
  State<_AboutYouStep> createState() => _AboutYouStepState();
}

class _AboutYouStepState extends State<_AboutYouStep> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 5),
    );
    if (picked != null) widget.onBirthDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = widget.birthDate;
    return _StepLayout(
      title: l10n?.onboardingUserInfoTitle ?? 'Tell us about you',
      subtitle:
          l10n?.onboardingUserInfoSubtitle ??
          'We use this to personalise your experience.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.onboardingYourName ?? 'Your name'),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _nameController,
            onChanged: widget.onNameChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n?.onboardingNameHint ?? 'e.g. Alex',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n?.onboardingDateOfBirth ?? 'Date of birth'),
          const SizedBox(height: AppSpacing.xs),
          MmmSurfaceCard(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    date == null
                        ? (l10n?.onboardingSelectDate ?? 'Select date')
                        : '${date.day}/${date.month}/${date.year}',
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n?.onboardingDobHint ??
                'Optional — helps us tailor lucky colour predictions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleStep extends StatelessWidget {
  const _StyleStep({required this.selected, required this.onToggle});

  final List<String> selected;
  final ValueChanged<String> onToggle;

  static const _styles = [
    'Casual',
    'Minimalist',
    'Streetwear',
    'Formal',
    'Vintage',
    'Y2K',
    'Cottagecore',
    'Preppy',
    'Bohemian',
    'Athleisure',
    'Dark Academia',
    'Clean Girl',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepLayout(
      title: l10n?.onboardingStyleTitle ?? 'Your style',
      subtitle:
          l10n?.onboardingStyleVibesHint ?? 'Pick everything that resonates.',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final style in _styles)
            MmmChoiceChip(
              label: _styleLabel(l10n, style),
              selected: selected.contains(style),
              onSelected: (_) => onToggle(style),
            ),
        ],
      ),
    );
  }
}

class _FitStep extends StatelessWidget {
  const _FitStep({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  static const _bodyTypes = [
    'Straight',
    'Hourglass',
    'Pear',
    'Apple',
    'Athletic',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepLayout(
      title: l10n?.onboardingBodyType ?? 'Your fit',
      subtitle:
          l10n?.onboardingStyleSubtitle ??
          'Choose the fit that feels most like you.',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final type in _bodyTypes)
            MmmChoiceChip(
              label: _bodyTypeLabel(l10n, type),
              selected: selected == type,
              onSelected: (_) => onSelect(type),
            ),
        ],
      ),
    );
  }
}

class _ColorSeasonStep extends StatelessWidget {
  const _ColorSeasonStep({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  static const _seasons = <_SeasonData>[
    _SeasonData('Spring', [
      Color(0xFFFF9A76),
      Color(0xFFFFD166),
      Color(0xFF95E1D3),
    ]),
    _SeasonData('Summer', [
      Color(0xFF7EC8E3),
      Color(0xFFB5C9E5),
      Color(0xFFD4A5C9),
    ]),
    _SeasonData('Autumn', [
      Color(0xFFBF5942),
      Color(0xFFD4845A),
      Color(0xFF8B6635),
    ]),
    _SeasonData('Winter', [
      Color(0xFF2C3E7A),
      Color(0xFF9B2335),
      Color(0xFF1A1A2E),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepLayout(
      title: l10n?.onboardingColorSeasonTitle ?? 'Your color season',
      subtitle:
          l10n?.onboardingColorSeasonSubtitle ??
          'A starting point for colours that may suit you.',
      child: Column(
        children: [
          for (final season in _seasons) ...[
            MmmSurfaceCard(
              onTap: () => onSelect(season.name),
              child: Row(
                children: [
                  for (final color in season.colors)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_seasonLabel(l10n, season.name))),
                  if (selected == season.name)
                    const Icon(Icons.check_circle_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SeasonData {
  const _SeasonData(this.name, this.colors);

  final String name;
  final List<Color> colors;
}

class _OccasionStep extends StatelessWidget {
  const _OccasionStep({required this.selected, required this.onToggle});

  final List<String> selected;
  final ValueChanged<String> onToggle;

  static const _occasions = [
    'Work',
    'Weekend',
    'Dates',
    'Sports',
    'Events',
    'Travel',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _StepLayout(
      title: l10n?.onboardingLifestyleTitle ?? 'Your occasions',
      subtitle:
          l10n?.onboardingLifestyleSubtitle ??
          'What occasions do you dress for?',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final occasion in _occasions)
            MmmChoiceChip(
              label: _occasionLabel(l10n, occasion),
              selected: selected.contains(occasion),
              onSelected: (_) => onToggle(occasion),
            ),
        ],
      ),
    );
  }
}

String _bodyTypeLabel(AppLocalizations? l10n, String type) => switch (type) {
  'Straight' => l10n?.bodyTypeStraight ?? type,
  'Hourglass' => l10n?.bodyTypeHourglass ?? type,
  'Pear' => l10n?.bodyTypePear ?? type,
  'Apple' => l10n?.bodyTypeApple ?? type,
  'Athletic' => l10n?.bodyTypeAthletic ?? type,
  _ => type,
};

String _styleLabel(AppLocalizations? l10n, String style) => switch (style) {
  'Casual' => l10n?.styleVibesCasual ?? style,
  'Minimalist' => l10n?.styleVibesMinimalist ?? style,
  'Streetwear' => l10n?.styleVibesStreetwear ?? style,
  'Formal' => l10n?.styleVibesFormal ?? style,
  'Vintage' => l10n?.styleVibesVintage ?? style,
  'Y2K' => l10n?.styleVibesY2K ?? style,
  'Cottagecore' => l10n?.styleVibesCottagecore ?? style,
  'Preppy' => l10n?.styleVibesPreppy ?? style,
  'Bohemian' => l10n?.styleVibesBohemian ?? style,
  'Athleisure' => l10n?.styleVibesAthleisure ?? style,
  'Dark Academia' => l10n?.styleVibesDarkAcademia ?? style,
  'Clean Girl' => l10n?.styleVibesCleanGirl ?? style,
  _ => style,
};

String _seasonLabel(AppLocalizations? l10n, String season) => switch (season) {
  'Spring' => l10n?.seasonSpring ?? season,
  'Summer' => l10n?.seasonSummer ?? season,
  'Autumn' => l10n?.seasonAutumn ?? season,
  'Winter' => l10n?.seasonWinter ?? season,
  _ => season,
};

String _occasionLabel(AppLocalizations? l10n, String occasion) =>
    switch (occasion) {
      'Work' => l10n?.occasionWork ?? occasion,
      'Weekend' => l10n?.occasionWeekend ?? occasion,
      'Dates' => l10n?.occasionDates ?? occasion,
      'Sports' => l10n?.occasionSports ?? occasion,
      'Events' => l10n?.occasionEvents ?? occasion,
      'Travel' => l10n?.occasionTravel ?? occasion,
      _ => occasion,
    };
