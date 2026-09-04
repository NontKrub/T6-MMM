import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/chat_message.dart';
import '../services/chat_repository.dart';

const _uuid = Uuid();

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier(
    onTypingChanged: (isTyping) =>
        ref.read(chatTypingProvider.notifier).state = isTyping,
    onPendingTurnChanged: (turn) =>
        ref.read(chatPendingRetryProvider.notifier).state = turn,
  );
});

final chatTypingProvider = StateProvider<bool>((ref) => false);
final chatPendingRetryProvider = StateProvider<PendingChatTurn?>((ref) => null);

class PendingChatTurn {
  const PendingChatTurn({
    required this.message,
    required this.turnId,
    required this.failure,
  });

  final String message;
  final String turnId;
  final ChatFailureKind failure;

  String get userMessage => switch (failure) {
    ChatFailureKind.consentRequired =>
      'Fashion AI needs your consent. You can allow it in Settings.',
    ChatFailureKind.notSignedIn => 'Sign in to use Fashion AI.',
    ChatFailureKind.invalidRequest =>
      'This message cannot be sent. Edit it and try again.',
    ChatFailureKind.temporary =>
      'Fashion Chat is temporarily unavailable. Try again.',
  };
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier({
    ChatRepository? repository,
    void Function(bool)? onTypingChanged,
    void Function(PendingChatTurn?)? onPendingTurnChanged,
  }) : _repository = repository ?? ChatRepository(),
       _onTypingChanged = onTypingChanged ?? _ignoreTyping,
       _onPendingTurnChanged = onPendingTurnChanged ?? _ignorePending,
       super([
         ChatMessage(
           id: _uuid.v4(),
           text:
               'Hi! I\'m your personal fashion AI. Ask me about color seasons, style names, building a capsule wardrobe, or anything fashion-related!',
           isUser: false,
           timestamp: DateTime.now(),
         ),
       ]);

  final ChatRepository _repository;
  final void Function(bool) _onTypingChanged;
  final void Function(PendingChatTurn?) _onPendingTurnChanged;
  String? _threadId;
  PendingChatTurn? _pendingTurn;

  String? get threadId => _threadId;

  Future<void> sendMessage(String text) async {
    final turn = PendingChatTurn(
      message: text,
      turnId: _uuid.v4(),
      failure: ChatFailureKind.temporary,
    );
    state = [
      ...state,
      ChatMessage(
        id: turn.turnId,
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
    await _send(turn);
  }

  Future<void> retryPendingTurn() async {
    final turn = _pendingTurn;
    if (turn == null) return;
    await _send(turn);
  }

  Future<void> _send(PendingChatTurn turn) async {
    _onTypingChanged(true);
    try {
      final result = await _repository.sendMessage(
        message: turn.message,
        turnId: turn.turnId,
        threadId: _threadId,
      );
      _threadId = result.threadId;
      _pendingTurn = null;
      _onPendingTurnChanged(null);
      state = [...state, result.message];
    } on ChatRepositoryException catch (error) {
      _pendingTurn = PendingChatTurn(
        message: turn.message,
        turnId: turn.turnId,
        failure: error.kind,
      );
      _onPendingTurnChanged(_pendingTurn);
    } finally {
      _onTypingChanged(false);
    }
  }
}

void _ignoreTyping(bool _) {}
void _ignorePending(PendingChatTurn? _) {}
