import 'package:flutter_riverpod/legacy.dart';

class OnboardingState {
  final int step;
  final String? bodyType;
  final List<String> styles;
  final String? colorSeason;
  final double brandTier;
  final List<String> occasions;

  const OnboardingState({
    this.step = 0,
    this.bodyType,
    this.styles = const [],
    this.colorSeason,
    this.brandTier = 0.3,
    this.occasions = const [],
  });

  OnboardingState copyWith({
    int? step,
    String? bodyType,
    List<String>? styles,
    String? colorSeason,
    double? brandTier,
    List<String>? occasions,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      bodyType: bodyType ?? this.bodyType,
      styles: styles ?? this.styles,
      colorSeason: colorSeason ?? this.colorSeason,
      brandTier: brandTier ?? this.brandTier,
      occasions: occasions ?? this.occasions,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier();
    });

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: (state.step - 1).clamp(0, 4));

  void setBodyType(String type) => state = state.copyWith(bodyType: type);
  void toggleStyle(String style) {
    final updated = List<String>.from(state.styles);
    updated.contains(style) ? updated.remove(style) : updated.add(style);
    state = state.copyWith(styles: updated);
  }

  void setColorSeason(String season) =>
      state = state.copyWith(colorSeason: season);
  void setBrandTier(double tier) => state = state.copyWith(brandTier: tier);
  void toggleOccasion(String occasion) {
    final updated = List<String>.from(state.occasions);
    updated.contains(occasion)
        ? updated.remove(occasion)
        : updated.add(occasion);
    state = state.copyWith(occasions: updated);
  }
}
