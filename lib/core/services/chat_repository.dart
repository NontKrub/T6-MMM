import '../../shared/models/chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum ChatFailureKind { consentRequired, notSignedIn, invalidRequest, temporary }

class ChatRepositoryException implements Exception {
  const ChatRepositoryException(this.kind);

  final ChatFailureKind kind;
}

class ChatSendResult {
  const ChatSendResult({required this.threadId, required this.message});

  final String threadId;
  final ChatMessage message;
}

class ChatRepository {
  Future<ChatSendResult> sendMessage({
    required String message,
    required String turnId,
    String? threadId,
  }) async {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw const ChatRepositoryException(ChatFailureKind.notSignedIn);
    }

    final body = <String, dynamic>{'message': message, 'turn_id': turnId};
    if (threadId != null && threadId.isNotEmpty) body['thread_id'] = threadId;

    try {
      final response = await client.functions.invoke(
        'fashion-chat',
        body: body,
      );
      if (response.data is! Map) {
        throw const ChatRepositoryException(ChatFailureKind.temporary);
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      final returnedThreadId = data['thread_id'];
      final messageRow = data['message'];
      if (returnedThreadId is! String ||
          returnedThreadId.isEmpty ||
          messageRow is! Map) {
        throw const ChatRepositoryException(ChatFailureKind.temporary);
      }
      return ChatSendResult(
        threadId: returnedThreadId,
        message: ChatMessage.fromJson(Map<String, dynamic>.from(messageRow)),
      );
    } on ChatRepositoryException {
      rethrow;
    } on FunctionException catch (error) {
      final code = _functionErrorCode(error.details);
      throw ChatRepositoryException(switch (code) {
        'ai_consent_required' => ChatFailureKind.consentRequired,
        'chat_turn_invalid' ||
        'chat_turn_conflict' ||
        'chat_thread_not_found' => ChatFailureKind.invalidRequest,
        _ => ChatFailureKind.temporary,
      });
    } catch (_) {
      throw const ChatRepositoryException(ChatFailureKind.temporary);
    }
  }
}

String? _functionErrorCode(Object? details) {
  if (details is Map && details['code'] is String) {
    return details['code'] as String;
  }
  return null;
}
