import 'package:cloud_firestore/cloud_firestore.dart';
// Model of the swap offer 
class SwapOffer {
  final String id;
  final String senderId;
  final String senderEmail;
  final String recipientId;
  final String recipientEmail;
  final String offeredBookId;
  final String offeredBookTitle;
  final String requestedBookId;
  final String requestedBookTitle;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  SwapOffer({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.recipientId,
    required this.recipientEmail,
    required this.offeredBookId,
    required this.offeredBookTitle,
    required this.requestedBookId,
    required this.requestedBookTitle,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory SwapOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwapOffer(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      offeredBookId: data['offeredBookId'] ?? '',
      offeredBookTitle: data['offeredBookTitle'] ?? '',
      requestedBookId: data['requestedBookId'] ?? '',
      requestedBookTitle: data['requestedBookTitle'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'offeredBookId': offeredBookId,
      'offeredBookTitle': offeredBookTitle,
      'requestedBookId': requestedBookId,
      'requestedBookTitle': requestedBookTitle,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  SwapOffer copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? recipientId,
    String? recipientEmail,
    String? offeredBookId,
    String? offeredBookTitle,
    String? requestedBookId,
    String? requestedBookTitle,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return SwapOffer(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientId: recipientId ?? this.recipientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      offeredBookId: offeredBookId ?? this.offeredBookId,
      offeredBookTitle: offeredBookTitle ?? this.offeredBookTitle,
      requestedBookId: requestedBookId ?? this.requestedBookId,
      requestedBookTitle: requestedBookTitle ?? this.requestedBookTitle,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
