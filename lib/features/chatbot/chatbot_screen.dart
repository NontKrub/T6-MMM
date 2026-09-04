import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ai_consent_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_brand_theme.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/auth_entry.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/widgets/mmm_brand_mark.dart';
import '../../shared/widgets/mmm_choice_chip.dart';
import '../../shared/widgets/mmm_gradient_button.dart';
import '../../shared/widgets/mmm_loading_indicator.dart';
import '../../shared/widgets/mmm_surface_card.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});
  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _quickPrompts(AppLocalizations? l) => [
    l?.chatPrompt1 ?? 'What’s my color season?',
    l?.chatPrompt2 ?? 'Name this style',
    l?.chatPrompt3 ?? 'Build a capsule wardrobe',
    l?.chatPrompt4 ?? 'Streetwear basics',
    l?.chatPrompt5 ?? 'Quiet luxury look',
  ];

  void _send([String? text]) {
    final message = text ?? _controller.text.trim();
    if (message.isEmpty) return;
    final scrollDuration = AppMotion.duration(context, AppMotion.transition);
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(message);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: scrollDuration,
          curve: AppMotion.curve,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(chatTypingProvider);
    final pendingTurn = ref.watch(chatPendingRetryProvider);
    final session = ref
        .watch(sessionProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final signedIn = session?.isSupabaseAuthenticated ?? false;
    final consentGranted = ref
        .watch(aiConsentProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);
    final consentLocked = signedIn && !consentGranted;
    final locked = !signedIn || consentLocked;
    final brand = MmmBrandTheme.of(context);
    final promptHeight = AppBreakpoints.veryLargeText(context)
        ? 112.0
        : AppBreakpoints.largeText(context)
        ? 88.0
        : 64.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  const MmmBrandMark(size: 72),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.chatTitle ?? 'MMM Stylist',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          !signedIn
                              ? (l10n?.chatStatusLocked ?? 'Sign in required')
                              : consentLocked
                              ? (l10n?.chatStatusConsentRequired ??
                                    'Consent required')
                              : (l10n?.chatStatusUnlocked ??
                                    'Your fashion assistant'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Expanded(
                child: _LockedAiState(
                  title: consentLocked
                      ? (l10n?.chatConsentTitle ??
                            'Fashion AI needs your consent')
                      : (l10n?.chatLockedTitle ?? 'Sign in to use MMM Stylist'),
                  message: consentLocked
                      ? (l10n?.chatConsentMessage ??
                            'Review AI permissions to continue.')
                      : (l10n?.chatLockedMessage ??
                            'Chat uses your saved wardrobe and backend AI.'),
                  actionLabel: consentLocked
                      ? (l10n?.chatReviewConsent ?? 'Review AI permissions')
                      : (l10n?.chatSignIn ?? 'Sign in'),
                  onAction: () => consentLocked
                      ? context.go('/settings')
                      : context.push(
                          '/auth',
                          extra: const AuthEntry(
                            intent: AuthIntent.unlockAi,
                            returnLocation: '/chat',
                          ),
                        ),
                ),
              )
            else ...[
              if (messages.length <= 1)
                SizedBox(
                  height: promptHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    itemCount: _quickPrompts(l10n).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (_, i) => MmmChoiceChip(
                      label: _quickPrompts(l10n)[i],
                      selected: false,
                      onSelected: (_) => _send(_quickPrompts(l10n)[i]),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (_, i) => i == messages.length
                      ? const _TypingBubble()
                      : _MessageBubble(message: messages[i]),
                ),
              ),
              if (pendingTurn != null)
                _RetryChatTurn(
                  message: pendingTurn.userMessage,
                  onRetry: () =>
                      ref.read(chatProvider.notifier).retryPendingTurn(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SafeArea(
                  top: false,
                  child: MmmSurfaceCard(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _send(),
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText:
                                  l10n?.chatInputHint ??
                                  'Ask about your wardrobe…',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: brand.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: IconButton(
                            tooltip: l10n?.chatSend ?? 'Send message',
                            onPressed: _send,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetryChatTurn extends StatelessWidget {
  const _RetryChatTurn({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: MmmSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)?.chatRetry ?? 'Retry'),
          ),
        ],
      ),
    ),
  );
}

class _LockedAiState extends StatelessWidget {
  const _LockedAiState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: MmmSurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: MmmBrandTheme.of(context).primaryGradient.colors.first,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: MmmGradientButton(label: actionLabel, onPressed: onAction),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final brand = MmmBrandTheme.of(context);
    final bubble = user
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: brand.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: AppRadii.control,
                topRight: AppRadii.control,
                bottomLeft: AppRadii.control,
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          )
        : MmmSurfaceCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          );
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: bubble,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: MmmLoadingIndicator(
      label: AppLocalizations.of(context)?.chatThinking ?? 'MMM is thinking…',
    ),
  );
}
