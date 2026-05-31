import '../../shared/models/chat_message.dart';
import 'supabase_service.dart';

class ChatRepository {
  Future<ChatMessage?> sendMessage(String message, {String? threadId}) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) return null;

    final body = <String, dynamic>{'message': message};
    if (threadId != null && threadId.isNotEmpty) {
      body['thread_id'] = threadId;
    }

    try {
      final response = await client.functions.invoke(
        'fashion-chat',
        body: body,
      );
      if (response.data is! Map) return null;

      final data = Map<String, dynamic>.from(response.data as Map);
      final messageRow = data['message'];
      if (messageRow is! Map) return null;
      return ChatMessage.fromJson(Map<String, dynamic>.from(messageRow));
    } catch (_) {
      return null;
    }
  }
}
