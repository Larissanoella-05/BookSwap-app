import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String swapFor;
  final String ownerId;
  final String ownerEmail;
  final DateTime createdAt;
  final String status;
  final String? imageUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.ownerId,
    required this.ownerEmail,
    required this.createdAt,
    this.status = 'available',
    this.imageUrl,
  });

  // Converting book to map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  // Creating book from Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? '',
      swapFor: data['swapFor'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'available',
      imageUrl: data['imageUrl'],
    );
  }

  // Creating copy of book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? condition,
    String? swapFor,
    String? status,
    String? imageUrl,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      swapFor: swapFor ?? this.swapFor,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      createdAt: createdAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
