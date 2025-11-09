import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat Model representing a chat conversation
class Chat {
  final String id; // Document ID from Firestore
  final List<String> participants; // List of user IDs in the chat
  final Map<String, String>
  participantEmails; // Map of userId -> email for display
  final Map<String, String> participantNames; // Map of userId -> display name
  final Map<String, String> participantPhotoURLs; // Map of userId -> photo URL
  final String? swapId; // Optional: ID of related swap
  final String? lastMessage; // Last message text
  final DateTime? lastMessageTime; // When last message was sent
  final DateTime createdAt; // When the chat was created
  final DateTime updatedAt; // When the chat was last updated

  Chat({
    required this.id,
    required this.participants,
    Map<String, String>? participantEmails,
    Map<String, String>? participantNames,
    Map<String, String>? participantPhotoURLs,
    this.swapId,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  }) : participantEmails = participantEmails ?? {},
       participantNames = participantNames ?? {},
       participantPhotoURLs = participantPhotoURLs ?? {};

  /// Create a Chat from a Firestore document
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse participantEmails map
    Map<String, String> emails = {};
    if (data['participantEmails'] != null) {
      final emailsData = data['participantEmails'] as Map<String, dynamic>;
      emails = emailsData.map((key, value) => MapEntry(key, value.toString()));
    }

    // Parse participantNames map
    Map<String, String> names = {};
    if (data['participantNames'] != null) {
      final namesData = data['participantNames'] as Map<String, dynamic>;
      names = namesData.map((key, value) => MapEntry(key, value.toString()));
    }

    // Parse participantPhotoURLs map
    Map<String, String> photoURLs = {};
    if (data['participantPhotoURLs'] != null) {
      final photoURLsData =
          data['participantPhotoURLs'] as Map<String, dynamic>;
      photoURLs = photoURLsData.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }

    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantEmails: emails,
      participantNames: names,
      participantPhotoURLs: photoURLs,
      swapId: data['swapId'],
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Chat to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantEmails': participantEmails,
      'participantNames': participantNames,
      'participantPhotoURLs': participantPhotoURLs,
      'swapId': swapId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get the other participant's ID
  String? getOtherParticipant(String currentUserId) {
    if (participants.length != 2) return null;
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
  }

  /// Get the other participant's email
  String? getOtherParticipantEmail(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    if (otherId == null) return null;
    return participantEmails[otherId];
  }

  /// Get the other participant's display name
  String? getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    if (otherId == null) return null;
    return participantNames[otherId];
  }

  /// Get the other participant's photo URL
  String? getOtherParticipantPhotoURL(String currentUserId) {
    final otherId = getOtherParticipant(currentUserId);
    if (otherId == null) return null;
    return participantPhotoURLs[otherId];
  }
}

/// Message Model representing a chat message
class Message {
  final String id; // Document ID from Firestore
  final String chatId; // ID of the chat this message belongs to
  final String senderId; // ID of the user who sent the message
  final String text; // Message text
  final DateTime timestamp; // When the message was sent

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  /// Create a Message from a Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Message to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
