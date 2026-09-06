import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/outfit_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/wardrobe_provider.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/clothing_item.dart';
import '../../shared/models/outfit.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_surface_card.dart';
import '../../shared/widgets/wardrobe_image.dart';
import '../outfit_generator/in_a_rush_modal.dart';
import '../outfit_generator/outfit_generator_sheet.dart';
import '../wardrobe/add_item_sheet.dart';
import 'widgets/repetition_insight_card.dart';
import 'widgets/todays_look_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider);
    final wardrobe = ref.watch(wardrobeProvider);
    final currentOutfit = ref.watch(currentOutfitProvider);
    final generated = ref.watch(generatedOutfitsProvider);
    final outfits = _displayOutfits(currentOutfit, generated);
    final name = profile.name.trim();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: l10n?.commonProfile ?? 'Open profile',
                    child: InkWell(
                      onTap: () => context.push('/profile'),
                      borderRadius: AppRadii.compactBorder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          _greeting(l10n, name),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n?.commonSettings ?? 'Settings',
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            Text(
              MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n?.homePrompt ?? 'What are we wearing today?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (wardrobe.isEmpty)
              _EmptyWardrobe(
                title:
                    l10n?.homeEmptyWardrobeTitle ??
                    'Your wardrobe starts here.',
                message:
                    l10n?.homeEmptyWardrobeMessage ??
                    'Add a few pieces and MMM can start building looks.',
                actionLabel: l10n?.homeAddClothing ?? 'Add clothing',
                onAdd: () => _showAddItem(context),
              )
            else
              TodaysLookSection(
                outfits: outfits,
                itemsForOutfit: (outfit) =>
                    _resolveOutfitItems(outfit, wardrobe),
                onGenerate: () => _showOutfitGenerator(context, ref),
                onSelect: (outfit) => ref
                    .read(outfitsProvider.notifier)
                    .selectOutfit(outfit, ref),
                onOpenItem: (item) => context.push('/item/${item.id}'),
                title: l10n?.homeTodaysLook ?? "Today's Look",
                tryAnotherLabel: l10n?.homeTryAnother ?? 'Try another',
                generateLabel:
                    l10n?.homeGenerateTodaysLook ?? "Generate today's look",
                whyThisWorksLabel: l10n?.homeWhyThisWorks ?? 'Why this works',
                wearLabel: l10n?.outfitWear ?? 'Wear',
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n?.homeQuickActions ?? 'Quick actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bolt_outlined,
                    label: l10n?.rushTitle ?? 'In a Rush',
                    onTap: () => _showInARush(context, ref),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_photo_alternate_outlined,
                    label: l10n?.commonAddItem ?? 'Add item',
                    onTap: () => _showAddItem(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n?.homeWardrobePulse ?? 'Wardrobe Pulse',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            const RepetitionInsightCard(),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n?.homeRecentlyAdded ?? 'Recently added',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/wardrobe'),
                  child: Text(l10n?.homeSeeAll ?? 'See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _RecentlyAdded(items: wardrobe),
          ],
        ),
      ),
    );
  }

  static List<Outfit> _displayOutfits(Outfit? current, List<Outfit> generated) {
    final result = <Outfit>[];
    if (current != null) result.add(current);
    result.addAll(generated.where((outfit) => outfit.id != current?.id));
    return result;
  }

  static List<ClothingItem> _resolveOutfitItems(
    Outfit outfit,
    List<ClothingItem> wardrobe,
  ) {
    final byId = {for (final item in wardrobe) item.id: item};
    return outfit.itemIds
        .map((id) => byId[id])
        .whereType<ClothingItem>()
        .toList();
  }

  static String _greeting(AppLocalizations? l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return name.isEmpty
          ? (l10n?.homeGreetingGeneric ?? 'Good morning')
          : (l10n?.homeGreetingMorning(name) ?? 'Good morning, $name');
    }
    if (hour < 18) {
      return name.isEmpty
          ? (l10n?.homeGreetingAfternoonGeneric ?? 'Good afternoon')
          : (l10n?.homeGreetingAfternoon(name) ?? 'Good afternoon, $name');
    }
    return name.isEmpty
        ? (l10n?.homeGreetingEveningGeneric ?? 'Good evening')
        : (l10n?.homeGreetingEvening(name) ?? 'Good evening, $name');
  }

  void _showOutfitGenerator(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OutfitGeneratorSheet(ref: ref),
      );

  void _showInARush(BuildContext context, WidgetRef ref) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .7),
    builder: (_) => InARushModal(ref: ref),
  );

  void _showAddItem(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddItemSheet(),
  );
}

class _EmptyWardrobe extends StatelessWidget {
  const _EmptyWardrobe({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAdd,
  });
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => MmmSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.checkroom_outlined, size: 36),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        MmmGradientButton(
          label: actionLabel,
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MmmSurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    onTap: onTap,
    child: SizedBox(
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class _RecentlyAdded extends StatelessWidget {
  const _RecentlyAdded({required this.items});
  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    final recent = [...items]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    if (recent.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recent.length > 8 ? 8 : recent.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => Semantics(
          button: true,
          label: recent[index].name,
          child: InkWell(
            onTap: () => context.push('/item/${recent[index].id}'),
            borderRadius: AppRadii.compactBorder,
            child: SizedBox(
              width: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadii.compactBorder,
                      child: WardrobeImage(item: recent[index]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    recent[index].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
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
