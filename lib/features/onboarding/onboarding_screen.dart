import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/user_profile.dart';

class OnboardingScreen extends ConsumerWidget {
  final bool isGuest;
  const OnboardingScreen({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final steps = [
      if (isGuest)
        _UserInfoStep(
          name: state.name,
          birthDate: state.birthDate,
          onNameChanged: notifier.setName,
          onBirthDateChanged: notifier.setBirthDate,
        ),
      _StyleAndBodyStep(
        onToggleStyle: notifier.toggleStyle,
        onSelectBodyType: notifier.setBodyType,
        selectedStyles: state.styles,
        selectedBodyType: state.bodyType,
      ),
      _ColorSeasonStep(
        onSelect: notifier.setColorSeason,
        selected: state.colorSeason,
      ),
      _OccasionStep(
        onToggle: notifier.toggleOccasion,
        selected: state.occasions,
      ),
    ];

    final isLastStep = state.step == steps.length - 1;

    // Continue is disabled on the Name+DOB step until name is filled
    final canContinue =
        !(isGuest && state.step == 0 && state.name.trim().isEmpty);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0E1A), Color(0xFF1A0E2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    if (state.step > 0)
                      GestureDetector(
                        onTap: notifier.prevStep,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 24),
                    const Spacer(),
                    Text(
                      l10n?.onboardingStep(state.step + 1, steps.length) ??
                          '${state.step + 1} / ${steps.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (state.step + 1) / steps.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.seedColor,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              // Step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: steps[state.step],
                  ),
                ),
              ),
              // CTA button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canContinue
                        ? () {
                            if (isLastStep) {
                              if (isGuest) {
                                if (state.name.trim().isNotEmpty) {
                                  ref
                                      .read(userProfileProvider.notifier)
                                      .updateName(state.name.trim());
                                }
                                if (state.birthDate != null) {
                                  ref
                                      .read(userProfileProvider.notifier)
                                      .updateBirthDate(state.birthDate!);
                                }
                              }
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateStylePreferences(state.styles);
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateOccasions(state.occasions);
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateOnboardingDetails(
                                    bodyType: state.bodyType,
                                    colorSeason: state.colorSeason == null
                                        ? null
                                        : colorSeasonFromString(
                                            state.colorSeason!,
                                          ),
                                  );
                              ref
                                  .read(userProfileProvider.notifier)
                                  .completeOnboarding();
                              context.go('/home');
                            } else {
                              notifier.nextStep();
                            }
                          }
                        : null,
                    child: Text(
                      isLastStep
                          ? (l10n?.onboardingEnter ?? 'Enter MMM')
                          : (l10n?.onboardingContinue ?? 'Continue'),
                    ),
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

// ─── Step: Name + Date of Birth (guest only) ──────────────────────────────────

class _UserInfoStep extends StatefulWidget {
  final String name;
  final DateTime? birthDate;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<DateTime> onBirthDateChanged;

  const _UserInfoStep({
    required this.name,
    required this.birthDate,
    required this.onNameChanged,
    required this.onBirthDateChanged,
  });

  @override
  State<_UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<_UserInfoStep> {
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.seedColor,
            onPrimary: Colors.white,
            surface: Color(0xFF1A0E2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) widget.onBirthDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasDob = widget.birthDate != null;
    final dob = widget.birthDate;
    final dobLabel = hasDob
        ? '${dob!.day}/${dob.month}/${dob.year}'
        : (l10n?.onboardingSelectDate ?? 'Select date');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n?.onboardingUserInfoTitle ?? 'Tell us about you',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingUserInfoSubtitle ??
                'We use this to personalise your experience.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 40),
          // Name field
          Text(
            l10n?.onboardingYourName ?? 'Your name',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            onChanged: widget.onNameChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n?.onboardingNameHint ?? 'e.g. Alex',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.seedColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // DOB picker
          Text(
            l10n?.onboardingDateOfBirth ?? 'Date of birth',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasDob
                      ? AppColors.seedColor
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: hasDob
                        ? AppColors.seedColor
                        : Colors.white.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dobLabel,
                    style: TextStyle(
                      color: hasDob
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingDobHint ??
                'Optional — helps us tailor lucky colour predictions.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Localized label helpers ─────────────────────────────────────────────────

String _bodyTypeLabel(AppLocalizations? l, String type) {
  return switch (type) {
    'Straight' => l?.bodyTypeStraight ?? type,
    'Hourglass' => l?.bodyTypeHourglass ?? type,
    'Pear' => l?.bodyTypePear ?? type,
    'Apple' => l?.bodyTypeApple ?? type,
    'Athletic' => l?.bodyTypeAthletic ?? type,
    _ => type,
  };
}

String _styleLabel(AppLocalizations? l, String style) {
  return switch (style) {
    'Casual' => l?.styleVibesCasual ?? style,
    'Minimalist' => l?.styleVibesMinimalist ?? style,
    'Streetwear' => l?.styleVibesStreetwear ?? style,
    'Formal' => l?.styleVibesFormal ?? style,
    'Vintage' => l?.styleVibesVintage ?? style,
    'Y2K' => l?.styleVibesY2K ?? style,
    'Cottagecore' => l?.styleVibesCottagecore ?? style,
    'Preppy' => l?.styleVibesPreppy ?? style,
    'Bohemian' => l?.styleVibesBohemian ?? style,
    'Athleisure' => l?.styleVibesAthleisure ?? style,
    'Dark Academia' => l?.styleVibesDarkAcademia ?? style,
    'Clean Girl' => l?.styleVibesCleanGirl ?? style,
    _ => style,
  };
}

String _occasionLabel(AppLocalizations? l, String occasion) {
  return switch (occasion) {
    'Work' => l?.occasionWork ?? occasion,
    'Weekend' => l?.occasionWeekend ?? occasion,
    'Dates' => l?.occasionDates ?? occasion,
    'Sports' => l?.occasionSports ?? occasion,
    'Events' => l?.occasionEvents ?? occasion,
    'Travel' => l?.occasionTravel ?? occasion,
    _ => occasion,
  };
}

// ─── Step: Style & Body Type (combined) ──────────────────────────────────────

class _StyleAndBodyStep extends StatelessWidget {
  final ValueChanged<String> onToggleStyle;
  final ValueChanged<String> onSelectBodyType;
  final List<String> selectedStyles;
  final String? selectedBodyType;

  const _StyleAndBodyStep({
    required this.onToggleStyle,
    required this.onSelectBodyType,
    required this.selectedStyles,
    this.selectedBodyType,
  });

  static const _bodyTypes = [
    'Straight',
    'Hourglass',
    'Pear',
    'Apple',
    'Athletic',
  ];

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n?.onboardingStyleTitle ?? 'Your style & build',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingStyleSubtitle ??
                'Pick your body type and the vibes that resonate.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 32),
          // Body type section
          Text(
            l10n?.onboardingBodyType ?? 'BODY TYPE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _bodyTypes.map((type) {
              final sel = selectedBodyType == type;
              return GestureDetector(
                onTap: () => onSelectBodyType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    _bodyTypeLabel(l10n, type),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Style section
          Text(
            l10n?.onboardingStyleVibes ?? 'STYLE VIBES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.onboardingStyleVibesHint ?? 'Pick everything that resonates.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _styles.map((style) {
              final sel = selectedStyles.contains(style);
              return GestureDetector(
                onTap: () => onToggleStyle(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    _styleLabel(l10n, style),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Step: Color Season ───────────────────────────────────────────────────────

class _ColorSeasonStep extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final String? selected;

  const _ColorSeasonStep({required this.onSelect, this.selected});

  static const _seasons = [
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n?.onboardingColorSeasonTitle ?? 'Your color season',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingColorSeasonSubtitle ??
                'Determines which color palette flatters you most.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 32),
          ...(_seasons.map((s) {
            final sel = selected == s.name;
            return GestureDetector(
              onTap: () => onSelect(s.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.seedColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withValues(alpha: 0.12),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: s.colors
                          .map(
                            (c) => Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      s.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                    if (sel) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.seedColor,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          })),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _SeasonData {
  final String name;
  final List<Color> colors;
  const _SeasonData(this.name, this.colors);
}

// ─── Step: Occasions ──────────────────────────────────────────────────────────

class _OccasionStep extends StatelessWidget {
  final ValueChanged<String> onToggle;
  final List<String> selected;

  const _OccasionStep({required this.onToggle, required this.selected});

  static const _occasions = [
    _OccasionData('Work', Icons.work_rounded),
    _OccasionData('Weekend', Icons.weekend_rounded),
    _OccasionData('Dates', Icons.favorite_rounded),
    _OccasionData('Sports', Icons.sports_rounded),
    _OccasionData('Events', Icons.celebration_rounded),
    _OccasionData('Travel', Icons.flight_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n?.onboardingLifestyleTitle ?? 'Your lifestyle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingLifestyleSubtitle ??
                'What occasions do you dress for?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: _occasions.map((o) {
              final sel = selected.contains(o.label);
              return GestureDetector(
                onTap: () => onToggle(o.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(o.icon, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        _occasionLabel(l10n, o.label),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _OccasionData {
  final String label;
  final IconData icon;
  const _OccasionData(this.label, this.icon);
}
