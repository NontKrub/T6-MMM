import 'package:flutter_riverpod/legacy.dart';

class OnboardingState {
  final int step;
  final String name;
  final DateTime? birthDate;
  final String? bodyType;
  final List<String> styles;
  final String? colorSeason;
  final List<String> occasions;

  const OnboardingState({
    this.step = 0,
    this.name = '',
    this.birthDate,
    this.bodyType,
    this.styles = const [],
    this.colorSeason,
    this.occasions = const [],
  });

  OnboardingState copyWith({
    int? step,
    String? name,
    DateTime? birthDate,
    String? bodyType,
    List<String>? styles,
    String? colorSeason,
    List<String>? occasions,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      bodyType: bodyType ?? this.bodyType,
      styles: styles ?? this.styles,
      colorSeason: colorSeason ?? this.colorSeason,
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
  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setBirthDate(DateTime date) => state = state.copyWith(birthDate: date);
  void setBodyType(String type) => state = state.copyWith(bodyType: type);
  void toggleStyle(String style) {
    final updated = List<String>.from(state.styles);
    updated.contains(style) ? updated.remove(style) : updated.add(style);
    state = state.copyWith(styles: updated);
  }

  void setColorSeason(String season) =>
      state = state.copyWith(colorSeason: season);
  void toggleOccasion(String occasion) {
    final updated = List<String>.from(state.occasions);
    updated.contains(occasion)
        ? updated.remove(occasion)
        : updated.add(occasion);
    state = state.copyWith(occasions: updated);
  }
}
