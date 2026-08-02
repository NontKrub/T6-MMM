import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_container.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/chat_message.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _quickPrompts(AppLocalizations? l) => [
    l?.chatPrompt1 ?? 'What\'s my color season?',
    l?.chatPrompt2 ?? 'Name this style',
    l?.chatPrompt3 ?? 'Build a capsule wardrobe',
    l?.chatPrompt4 ?? 'Streetwear basics',
    l?.chatPrompt5 ?? 'Quiet luxury look',
  ];

  void _send([String? text]) {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(msg, ref);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prompts = _quickPrompts(l10n);
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(chatTypingProvider);
    final locked = ref
        .watch(sessionProvider)
        .maybeWhen(
          data: (session) => session.requiresLoginForAi,
          orElse: () => true,
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.chatTitle ?? 'Fashion AI',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        locked
                            ? (l10n?.chatStatusLocked ?? 'Sign in required')
                            : (l10n?.chatStatusUnlocked ?? 'Always styled'),
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            // Quick prompts
            if (locked)
              Expanded(
                child: _LockedAiState(
                  title: l10n?.chatLockedTitle ?? 'Fashion AI needs a login',
                  message: l10n?.chatLockedMessage ??
                      'Chat uses your saved wardrobe and backend AI. Continue with Google after Supabase is configured.',
                ),
              )
            else if (messages.length <= 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: prompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _send(prompts[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.seedColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.seedColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        prompts[i],
                        style: TextStyle(
                          color: AppColors.seedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Messages
            if (!locked)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == messages.length && isTyping) {
                      return _TypingBubble();
                    }
                    return _MessageBubble(message: messages[i])
                        .animate(delay: 50.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
            // Input bar
            if (!locked)
              Container(
                color: isDark
                    ? const Color(0xFF0F0E1A)
                    : const Color(0xFFF8F7FF),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l10n?.chatInputHint ?? 'Ask about fashion…',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.seedColor,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedAiState extends StatelessWidget {
  final String title;
  final String message;

  const _LockedAiState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.seedColor,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: isUser
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.seedColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              )
            : GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  message.text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) =>
                Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.seedColor,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      delay: (i * 150).ms,
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    ),
          ),
        ),
      ),
    );
  }
}
