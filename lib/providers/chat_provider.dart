import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  int _totalUnreadCount = 0;

  int get totalUnreadCount => _totalUnreadCount;

  // Listening to total unread messages count
  void listenToTotalUnreadCount() {
    _chatService.getTotalUnreadCountStream().listen((count) {
      _totalUnreadCount = count;
      notifyListeners();
    });
  }
}
