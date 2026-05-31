import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_profile.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final steps = [
      _BodyTypeStep(onSelect: notifier.setBodyType, selected: state.bodyType),
      _StyleStep(onToggle: notifier.toggleStyle, selected: state.styles),
      _ColorSeasonStep(
        onSelect: notifier.setColorSeason,
        selected: state.colorSeason,
      ),
      _BrandTierStep(value: state.brandTier, onChanged: notifier.setBrandTier),
      _OccasionStep(
        onToggle: notifier.toggleOccasion,
        selected: state.occasions,
      ),
    ];

    final isLastStep = state.step == steps.length - 1;

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
                      '${state.step + 1} / ${steps.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
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
                    backgroundColor: Colors.white.withOpacity(0.1),
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
                    onPressed: () {
                      if (isLastStep) {
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
                                  : colorSeasonFromString(state.colorSeason!),
                              brandTier: state.brandTier,
                            );
                        ref
                            .read(userProfileProvider.notifier)
                            .completeOnboarding();
                        context.go('/home');
                      } else {
                        notifier.nextStep();
                      }
                    },
                    child: Text(isLastStep ? 'Enter MMM' : 'Continue'),
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

// ─── Step 1: Body Type ────────────────────────────────────────────────────────

class _BodyTypeStep extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final String? selected;

  const _BodyTypeStep({required this.onSelect, this.selected});

  static const _types = ['Straight', 'Hourglass', 'Pear', 'Apple', 'Athletic'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your body type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helps us suggest cuts that flatter you.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.map((type) {
              final sel = selected == type;
              return GestureDetector(
                onTap: () => onSelect(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
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

// ─── Step 2: Style Keywords ───────────────────────────────────────────────────

class _StyleStep extends StatelessWidget {
  final ValueChanged<String> onToggle;
  final List<String> selected;

  const _StyleStep({required this.onToggle, required this.selected});

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your style vibes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick everything that resonates. No wrong answers.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _styles.map((style) {
              final sel = selected.contains(style);
              return GestureDetector(
                onTap: () => onToggle(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    style,
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
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Step 3: Color Season ─────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your color season',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Determines which color palette flatters you most.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                      ? AppColors.seedColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sel
                        ? AppColors.seedColor
                        : Colors.white.withOpacity(0.12),
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

// ─── Step 4: Brand Tier ───────────────────────────────────────────────────────

class _BrandTierStep extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _BrandTierStep({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tiers = ['Fast Fashion', 'High Street', 'Contemporary', 'Luxury'];
    final idx = (value * (tiers.length - 1)).round();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Brand preference',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your typical shopping tier.',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              tiers[idx],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.seedColor,
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: AppColors.seedColor,
              overlayColor: AppColors.seedColor.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiers
                .map(
                  (t) => Text(
                    t.split(' ').first,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─── Step 5: Occasions ────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Your lifestyle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What occasions do you dress for?',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel
                          ? AppColors.seedColor
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(o.icon, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        o.label,
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
