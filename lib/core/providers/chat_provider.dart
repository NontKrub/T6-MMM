import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../services/chat_repository.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/services/mock_data.dart';

const _uuid = Uuid();

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier();
});

final chatTypingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
    : super([
        ChatMessage(
          id: _uuid.v4(),
          text:
              'Hi! I\'m your personal fashion AI. Ask me about color seasons, style names, building a capsule wardrobe, or anything fashion-related!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ]);

  final _repository = ChatRepository();

  Future<void> sendMessage(String text, WidgetRef ref) async {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    ref.read(chatTypingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 1400));
    ref.read(chatTypingProvider.notifier).state = false;

    final backendMessage = await _repository.sendMessage(text);
    if (backendMessage != null) {
      state = [...state, backendMessage];
      return;
    }

    final response = MockData.getChatResponse(text);
    final aiMsg = ChatMessage(
      id: _uuid.v4(),
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = [...state, aiMsg];
  }
}
