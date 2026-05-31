import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient + orbs
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
          // Decorative blobs
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.seedColor.withOpacity(0.3),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GlowOrb(
              color: AppColors.gradientEnd.withOpacity(0.2),
              size: 320,
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.1),
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 28),
                  Text(
                        'Your wardrobe,\nreimagined.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                      )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'AI-powered outfit suggestions,\npersonalized just for you.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
                  const Spacer(),
                  // Auth buttons
                  GlassContainer(
                        borderRadius: 28,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Get started',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label: 'Continue with Google',
                              onTap: () => _handleOAuth(
                                context,
                                AuthService().signInWithGoogle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SocialButton(
                              icon: Icons.facebook_rounded,
                              label: 'Continue with Facebook',
                              onTap: () => _handleOAuth(
                                context,
                                AuthService().signInWithFacebook,
                              ),
                              color: const Color(0xFF1877F2),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => _handleLogin(context),
                              child: Text(
                                'Continue as guest',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    context.go('/onboarding');
  }

  Future<void> _handleOAuth(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    if (!AppConfig.isSupabaseConfigured) {
      _handleLogin(context);
      return;
    }
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
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
