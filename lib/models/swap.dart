import 'package:cloud_firestore/cloud_firestore.dart';

/// Swap Status enum
enum SwapStatus {
  pending,
  accepted,
  rejected;

  String get displayName {
    switch (this) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
    }
  }

  static SwapStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SwapStatus.pending;
      case 'accepted':
        return SwapStatus.accepted;
      case 'rejected':
        return SwapStatus.rejected;
      default:
        return SwapStatus.pending;
    }
  }
}

/// Swap Model representing a swap offer
class Swap {
  final String id;                    // Document ID from Firestore
  final String bookId;                // ID of the book being swapped
  final String requesterId;           // ID of user initiating the swap
  final String requesterEmail;        // Email of requester
  final String ownerId;               // ID of book owner
  final String ownerEmail;            // Email of book owner
  final SwapStatus status;            // Status: pending, accepted, rejected
  final DateTime createdAt;           // When the swap was created
  final DateTime updatedAt;           // When the swap was last updated

  Swap({
    required this.id,
    required this.bookId,
    required this.requesterId,
    required this.requesterEmail,
    required this.ownerId,
    required this.ownerEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a Swap from a Firestore document
  factory Swap.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Swap(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterEmail: data['requesterEmail'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      status: SwapStatusExtension.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Swap to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'requesterId': requesterId,
      'requesterEmail': requesterEmail,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'status': status.displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of this Swap with updated fields
  Swap copyWith({
    String? id,
    String? bookId,
    String? requesterId,
    String? requesterEmail,
    String? ownerId,
    String? ownerEmail,
    SwapStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Swap(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      requesterId: requesterId ?? this.requesterId,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Extension for SwapStatus enum
extension SwapStatusExtension on SwapStatus {
  static SwapStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SwapStatus.pending;
      case 'accepted':
        return SwapStatus.accepted;
      case 'rejected':
        return SwapStatus.rejected;
      default:
        return SwapStatus.pending;
    }
  }
}

