import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bookswap/Models/chat.dart';
import 'package:bookswap/Models/message.dart' as msg;
import 'package:bookswap/Services/notification_service.dart';

/// Service class for managing chat conversations and messages
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection names in Firestore
  static const String _chatsCollection = 'chats';
  static const String _messagesCollection = 'messages';

  /// CREATE: Create a new chat between two users
  /// 
  /// If a chat already exists between these users, returns the existing chat
  Future<Chat> createChat({
    required String userId1,
    required String userId2,
    String? swapId,
    String? user1Email,
    String? user2Email,
    String? user1Name,
    String? user2Name,
    String? user1PhotoURL,
    String? user2PhotoURL,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to create a chat';
    }

    // Ensure user is one of the participants
    if (user.uid != userId1 && user.uid != userId2) {
      throw 'You can only create chats you are part of';
    }

    try {
      // Get info for participant 1 (current user if they match)
      String email1 = user1Email ?? '';
      String name1 = user1Name ?? '';
      String photoURL1 = user1PhotoURL ?? '';
      
      if (user.uid == userId1) {
        email1 = user.email ?? '';
        name1 = user.displayName ?? '';
        photoURL1 = user.photoURL ?? '';
      }

      // Get info for participant 2
      String email2 = user2Email ?? '';
      String name2 = user2Name ?? '';
      String photoURL2 = user2PhotoURL ?? '';
      
      if (user.uid == userId2) {
        email2 = user.email ?? '';
        name2 = user.displayName ?? '';
        photoURL2 = user.photoURL ?? '';
      }

      // Check if chat already exists
      final existingChats = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingChats.docs) {
        final chat = Chat.fromFirestore(doc);
        if (chat.participants.contains(userId1) && 
            chat.participants.contains(userId2) &&
            chat.participants.length == 2) {
          // Update existing chat with current user's info if missing
          final needsUpdate = 
              (user.uid == userId1 && (!chat.participantNames.containsKey(userId1) || chat.participantNames[userId1] != name1)) ||
              (user.uid == userId2 && (!chat.participantNames.containsKey(userId2) || chat.participantNames[userId2] != name2));
          
          if (needsUpdate) {
            final updatedEmails = Map<String, String>.from(chat.participantEmails);
            final updatedNames = Map<String, String>.from(chat.participantNames);
            final updatedPhotoURLs = Map<String, String>.from(chat.participantPhotoURLs);
            
            if (user.uid == userId1) {
              updatedEmails[userId1] = email1;
              if (name1.isNotEmpty) updatedNames[userId1] = name1;
              if (photoURL1.isNotEmpty) updatedPhotoURLs[userId1] = photoURL1;
            } else {
              updatedEmails[userId2] = email2;
              if (name2.isNotEmpty) updatedNames[userId2] = name2;
              if (photoURL2.isNotEmpty) updatedPhotoURLs[userId2] = photoURL2;
            }
            
            await _firestore.collection(_chatsCollection).doc(chat.id).update({
              'participantEmails': updatedEmails,
              'participantNames': updatedNames,
              'participantPhotoURLs': updatedPhotoURLs,
            });
            
            // Return updated chat
            final updatedDoc = await _firestore.collection(_chatsCollection).doc(chat.id).get();
            return Chat.fromFirestore(updatedDoc);
          }
          
          return chat; // Return existing chat
        }
      }

      // Create new chat
      final now = DateTime.now();
      final participantEmails = <String, String>{
        userId1: email1,
        userId2: email2,
      };
      final participantNames = <String, String>{
        if (name1.isNotEmpty) userId1: name1,
        if (name2.isNotEmpty) userId2: name2,
      };
      final participantPhotoURLs = <String, String>{
        if (photoURL1.isNotEmpty) userId1: photoURL1,
        if (photoURL2.isNotEmpty) userId2: photoURL2,
      };
      
      final chatData = {
        'participants': [userId1, userId2],
        'participantEmails': participantEmails,
        'participantNames': participantNames,
        'participantPhotoURLs': participantPhotoURLs,
        'swapId': swapId,
        'lastMessage': null,
        'lastMessageTime': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final DocumentReference docRef = await _firestore
          .collection(_chatsCollection)
          .add(chatData);

      final doc = await docRef.get();
      return Chat.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw 'Failed to create chat: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Helper method to enrich chat with participant info from swaps
  Future<void> _enrichChatWithSwapInfo(Chat chat) async {
    if (chat.swapId == null) return;
    
    try {
      final swapDoc = await _firestore.collection('swaps').doc(chat.swapId).get();
      if (!swapDoc.exists) return;
      
      final swapData = swapDoc.data() as Map<String, dynamic>;
      final requesterId = swapData['requesterId'] as String?;
      final requesterEmail = swapData['requesterEmail'] as String?;
      final ownerId = swapData['ownerId'] as String?;
      final ownerEmail = swapData['ownerEmail'] as String?;
      
      final updatedEmails = Map<String, String>.from(chat.participantEmails);
      bool needsUpdate = false;
      
      // Update requester email if missing
      if (requesterId != null && requesterEmail != null && requesterEmail.isNotEmpty) {
        if (!updatedEmails.containsKey(requesterId) || updatedEmails[requesterId] != requesterEmail) {
          updatedEmails[requesterId] = requesterEmail;
          needsUpdate = true;
        }
      }
      
      // Update owner email if missing
      if (ownerId != null && ownerEmail != null && ownerEmail.isNotEmpty) {
        if (!updatedEmails.containsKey(ownerId) || updatedEmails[ownerId] != ownerEmail) {
          updatedEmails[ownerId] = ownerEmail;
          needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        await _firestore.collection(_chatsCollection).doc(chat.id).update({
          'participantEmails': updatedEmails,
        });
      }
    } catch (e) {
      // Silently fail - this is just enrichment
      debugPrint('Failed to enrich chat with swap info: $e');
    }
  }

  /// READ: Get all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    try {
      return _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final chats = snapshot.docs
            .map((doc) => Chat.fromFirestore(doc))
            .toList();
        
        // Enrich chats with swap info in background (don't block)
        for (final chat in chats) {
          if (chat.swapId != null) {
            _enrichChatWithSwapInfo(chat).catchError((e) {
              debugPrint('Failed to enrich chat: $e');
            });
          }
        }
        
        return chats;
      });
    } catch (e) {
      throw 'Failed to fetch chats: $e';
    }
  }

  /// READ: Get a single chat by ID
  Future<Chat> getChatById(String chatId) async {
    try {
      final doc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .get();

      if (!doc.exists) {
        throw 'Chat not found';
      }

      return Chat.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw 'Failed to fetch chat: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// READ: Get all messages for a chat
  Stream<List<msg.Message>> getMessages(String chatId) {
    try {
      return _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => msg.Message.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw 'Failed to fetch messages: $e';
    }
  }

  /// CREATE: Send a message in a chat
  Future<msg.Message> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to send a message';
    }

    if (text.trim().isEmpty) {
      throw 'Message cannot be empty';
    }

    try {
      // Verify user is part of the chat
      final chatDoc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw 'Chat not found';
      }

      final chat = Chat.fromFirestore(chatDoc);
      if (!chat.participants.contains(user.uid)) {
        throw 'You are not part of this chat';
      }

      final now = DateTime.now();
      final messageData = {
        'chatId': chatId,
        'senderId': user.uid,
        'text': text.trim(),
        'timestamp': Timestamp.fromDate(now),
      };

      // Add message to subcollection
      final DocumentReference messageRef = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(messageData);

      // Update chat's last message and timestamp
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .update({
        'lastMessage': text.trim(),
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Note: Notifications for new messages are handled by NotificationListenerWidget
      // which watches for new messages in the recipient's chats

      final messageDoc = await messageRef.get();
      return msg.Message.fromFirestore(messageDoc);
    } on FirebaseException catch (e) {
      throw 'Failed to send message: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// DELETE: Delete a message (only sender can delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to delete a message';
    }

    try {
      // Get message to verify ownership
      final messageDoc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw 'Message not found';
      }

      final message = msg.Message.fromFirestore(messageDoc);
      if (message.senderId != user.uid) {
        throw 'You can only delete your own messages';
      }

      // Delete message
      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .doc(messageId)
          .delete();
    } on FirebaseException catch (e) {
      throw 'Failed to delete message: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }
}

