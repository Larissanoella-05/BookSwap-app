import 'package:cloud_firestore/cloud_firestore.dart';

enum BookCondition { newCondition, likeNew, good, used }

enum SwapStatus { available, pending, swapped }

class Book {
  final String id;
  final String title;
  final String author;
  final BookCondition condition;
  final String? imageUrl;
  final String ownerId;
  final String ownerEmail;
  final SwapStatus status;
  final DateTime createdAt;
  final String? swapRequesterId;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    this.imageUrl,
    required this.ownerId,
    required this.ownerEmail,
    this.status = SwapStatus.available,
    required this.createdAt,
    this.swapRequesterId,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: BookCondition.values[data['condition'] ?? 0],
      imageUrl: data['imageUrl'],
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      status: SwapStatus.values[data['status'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      swapRequesterId: data['swapRequesterId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'condition': condition.index,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'swapRequesterId': swapRequesterId,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    BookCondition? condition,
    String? imageUrl,
    String? ownerId,
    String? ownerEmail,
    SwapStatus? status,
    DateTime? createdAt,
    String? swapRequesterId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      swapRequesterId: swapRequesterId ?? this.swapRequesterId,
    );
  }
}