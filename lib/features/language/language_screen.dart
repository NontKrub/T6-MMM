import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  final bool fromSettings;
  const LanguageScreen({super.key, this.fromSettings = false});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Pre-select current locale when opened from settings
    if (widget.fromSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLocale = ref.read(localeProvider);
        setState(() => _selected = currentLocale.languageCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0E1A),
                  Color(0xFF1A0E2E),
                  Color(0xFF0E1A2E),
                ],
              ),
            ),
          ),
          // Glow orbs
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.accentGold.withOpacity(0.3),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GlowOrb(
              color: AppColors.accentGold.withOpacity(0.2),
              size: 320,
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentGold,
                              AppColors.accentGold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 32),
                  // Title (bilingual — always shown in both)
                  Text(
                        'Choose your language',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                        'เลือกภาษา',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 48),
                  // Language cards
                  Row(
                        children: [
                          Expanded(
                            child: _LanguageCard(
                              flag: '🇬🇧',
                              languageName: 'English',
                              nativeName: 'English',
                              code: 'en',
                              selected: _selected == 'en',
                              onTap: () => setState(() => _selected = 'en'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LanguageCard(
                              flag: '🇹🇭',
                              languageName: 'Thai',
                              nativeName: 'ภาษาไทย',
                              code: 'th',
                              selected: _selected == 'th',
                              onTap: () => setState(() => _selected = 'th'),
                            ),
                          ),
                        ],
                      )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  const Spacer(),
                  // Continue button
                  SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _selected == null
                              ? null
                              : () async {
                                  final router = GoRouter.of(context);
                                  final fromSettings = widget.fromSettings;
                                  await ref
                                      .read(localeProvider.notifier)
                                      .setLocale(_selected!);
                                  if (!mounted) return;
                                  if (fromSettings) {
                                    router.pop();
                                  } else {
                                    router.go('/auth');
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            disabledBackgroundColor:
                                Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _selected == 'th'
                                ? 'ดำเนินการต่อ'
                                : 'Continue',
                            style: TextStyle(
                              color: _selected == null
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String languageName;
  final String nativeName;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.languageName,
    required this.nativeName,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentGold.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              nativeName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (selected) ...[
              const SizedBox(height: 10),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
