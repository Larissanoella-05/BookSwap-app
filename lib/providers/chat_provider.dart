import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Chat> _chats = [];
  final bool _isLoading = false;
  StreamSubscription? _chatsSubscription;

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToChats();
      } else {
        _chats = [];
        _chatsSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _listenToChats() {
    _chatsSubscription?.cancel();
    if (_auth.currentUser != null) {
      _chatsSubscription = _firestore
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser!.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen((snapshot) {
            _chats = snapshot.docs
                .map((doc) => Chat.fromFirestore(doc))
                .toList();
            notifyListeners();
          });
    }
  }

  Future<String?> createOrGetChat(
    String otherUserId,
    String otherUserEmail,
    String? bookId,
    String? bookTitle,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (var doc in existingChat.docs) {
        final chat = Chat.fromFirestore(doc);
        if (chat.participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat
      final chatData = Chat(
        id: '',
        participants: [currentUser.uid, otherUserId],
        bookId: bookId,
        bookTitle: bookTitle,
      );

      final docRef = await _firestore
          .collection('chats')
          .add(chatData.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Future<String?> sendMessage(String chatId, String text) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'User not authenticated';

      final message = ChatMessage(
        id: '',
        text: text,
        senderId: currentUser.uid,
        senderEmail: currentUser.email ?? '',
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }
}
