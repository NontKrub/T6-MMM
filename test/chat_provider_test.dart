import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/providers/chat_provider.dart';
import 'package:mix_match_mood/core/services/chat_repository.dart';
import 'package:mix_match_mood/shared/models/chat_message.dart';

void main() {
  test('keeps the returned thread for the next chat message', () async {
    final repository = _ChatRepositoryFake();
    final notifier = ChatNotifier(repository: repository);

    await notifier.sendMessage('First question');
    await notifier.sendMessage('Second question');

    expect(repository.calls, hasLength(2));
    expect(repository.calls.first.threadId, isNull);
    expect(repository.calls.last.threadId, 'thread-a');
    expect(repository.calls.map((call) => call.turnId).toSet(), hasLength(2));
  });

  test('retries the same failed chat turn and always clears typing', () async {
    final repository = _ChatRepositoryFake(failFirst: true);
    final typingStates = <bool>[];
    PendingChatTurn? pending;
    final notifier = ChatNotifier(
      repository: repository,
      onTypingChanged: typingStates.add,
      onPendingTurnChanged: (value) => pending = value,
    );

    await notifier.sendMessage('What should I wear?');
    expect(pending, isNotNull);
    final failedTurnId = pending!.turnId;

    await notifier.retryPendingTurn();

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.turnId, failedTurnId);
    expect(pending, isNull);
    expect(typingStates.last, isFalse);
  });
}

class _ChatRepositoryFake extends ChatRepository {
  _ChatRepositoryFake({this.failFirst = false});

  final bool failFirst;
  final calls = <({String message, String turnId, String? threadId})>[];

  @override
  Future<ChatSendResult> sendMessage({
    required String message,
    required String turnId,
    String? threadId,
  }) async {
    calls.add((message: message, turnId: turnId, threadId: threadId));
    if (failFirst && calls.length == 1) {
      throw const ChatRepositoryException(ChatFailureKind.temporary);
    }
    return ChatSendResult(
      threadId: 'thread-a',
      message: ChatMessage(
        id: 'assistant-${calls.length}',
        text: 'Try the navy top.',
        isUser: false,
        timestamp: DateTime.utc(2026, 9, 4),
      ),
    );
  }
}
