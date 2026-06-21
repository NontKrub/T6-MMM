import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/wardrobe_image.dart';

class InARushModal extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const InARushModal({super.key, required this.ref});

  @override
  ConsumerState<InARushModal> createState() => _InARushModalState();
}

class _InARushModalState extends ConsumerState<InARushModal> {
  Outfit? _outfit;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOutfit();
  }

  Future<void> _loadOutfit() async {
    setState(() => _loading = true);
    try {
      final outfit = await ref
          .read(outfitsProvider.notifier)
          .rushBackendOutfit(widget.ref);
      if (!mounted) return;
      setState(() {
        _outfit = outfit;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _outfit = null;
        _error = _friendlyRushError(error, l10n);
        _loading = false;
      });
    }
  }

  String _friendlyRushError(Object error, AppLocalizations? l) {
    final text = error.toString();
    if (text.contains('Add at least one top')) {
      return l?.rushErrorNeedWardrobe ??
          'Rush outfits need a complete wardrobe first. Add at least one top, one bottom, and one pair of shoes.';
    }
    if (text.contains('Sign in') || text.contains('signed-in')) {
      return l?.rushErrorSignIn ??
          'Rush outfit uses your saved backend wardrobe. Sign in to use it.';
    }
    if (text.contains('NOT_FOUND') || text.contains('status: 404')) {
      return l?.rushErrorNotDeployed ??
          'Rush outfit is not deployed yet. Please try again after the backend is updated.';
    }
    return l?.rushErrorGeneric ??
        'Could not pick a rush outfit right now. Check your wardrobe and try again.';
  }

  void _reshuffle() {
    _loadOutfit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wardrobe = ref.watch(wardrobeProvider);
    final locked = ref
        .watch(sessionProvider)
        .maybeWhen(
          data: (session) => session.requiresLoginForAi,
          orElse: () => true,
        );
    final outfit = _outfit;
    final hasError = _error != null;
    final items = outfit == null
        ? <ClothingItem>[]
        : outfit.itemIds
              .map((id) => wardrobe.where((i) => i.id == id).firstOrNull)
              .whereType<ClothingItem>()
              .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1628), Color(0xFF0F0E1A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.rushTitle ?? 'In a Rush',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      locked
                          ? (l10n?.rushStatusSignInRequired ??
                              'Sign in required')
                          : hasError
                          ? (l10n?.rushStatusNeedsSetup ??
                              'Needs a little setup')
                          : (l10n?.rushStatusReady ?? 'Your outfit is ready'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            // Outfit items row
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  locked
                      ? (l10n?.rushLockedMessage ??
                          'Rush outfit uses backend AI. Sign in with Supabase to use it.')
                      : _error!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: items.asMap().entries.map((e) {
                      final item = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child:
                            Column(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: WardrobeImage(item: item),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 72,
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                )
                                .animate(delay: (e.key * 80).ms)
                                .scale(
                                  duration: 300.ms,
                                  curve: Curves.elasticOut,
                                )
                                .fadeIn(duration: 200.ms),
                      );
                    }).toList(),
                  ),
                  if (outfit != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      outfit.reason ??
                          (l10n?.rushDefaultReason ??
                              'Fast practical pick from your wardrobe.'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (outfit.score != null ||
                        outfit.selectionFactors.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (outfit.score != null)
                            _RushChip('${outfit.score!.round()} score'),
                          ...outfit.selectionFactors
                              .take(3)
                              .map(
                                (factor) =>
                                    _RushChip(factor.replaceAll('_', ' ')),
                              ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locked || _loading ? null : _reshuffle,
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: Text(l10n?.rushReshuffle ?? 'Reshuffle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: locked
                        ? () {
                            Navigator.pop(context);
                            context.go('/auth');
                          }
                        : () {
                            if (_outfit != null) {
                              ref
                                  .read(outfitsProvider.notifier)
                                  .selectOutfit(_outfit!, ref);
                            }
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      locked
                          ? (l10n?.rushSignIn ?? 'Sign In')
                          : _outfit == null
                          ? (l10n?.rushGotIt ?? 'Got It')
                          : (l10n?.rushWearThis ?? 'Wear This'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RushChip extends StatelessWidget {
  final String label;
  const _RushChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 11,
        ),
      ),
    );
  }
}
