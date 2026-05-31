import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/outfit_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_colors.dart';
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
      setState(() {
        _outfit = null;
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _reshuffle() {
    _loadOutfit();
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = ref.watch(wardrobeProvider);
    final locked = ref
        .watch(sessionProvider)
        .maybeWhen(
          data: (session) => session.requiresLoginForAi,
          orElse: () => true,
        );
    final outfit = _outfit;
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    const Text(
                      'In a Rush',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      locked ? 'Sign in required' : 'Your outfit is ready',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
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
                      ? 'Rush outfit uses backend AI. Sign in with Supabase to use it.'
                      : _error!,
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  textAlign: TextAlign.center,
                ),
              )
            else
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
                                      color: Colors.white.withOpacity(0.15),
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
                                      color: Colors.white.withOpacity(0.7),
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
                            .scale(duration: 300.ms, curve: Curves.elasticOut)
                            .fadeIn(duration: 200.ms),
                  );
                }).toList(),
              ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locked ? null : _reshuffle,
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('Reshuffle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _outfit == null
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
                    label: Text(_outfit == null ? 'Sign In' : 'Wear This'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.seedColor,
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
