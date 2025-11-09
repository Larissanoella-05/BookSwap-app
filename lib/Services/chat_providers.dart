import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/chat_service.dart';
import 'package:bookswap/Models/chat.dart';

/// Provider for ChatService instance (singleton)
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// StreamProvider for all chats for a user
final userChatsProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getUserChats(userId);
});

/// FutureProvider for getting a single chat by ID
final chatByIdProvider = FutureProvider.family<Chat, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatById(chatId);
});

/// StreamProvider for messages in a chat
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessages(chatId);
});

