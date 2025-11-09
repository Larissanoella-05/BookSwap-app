import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a book listing in the BookSwap app
/// Contains all information needed for book display and swap operations
class Book {
  final String id;          // Unique Firestore document ID
  final String title;       // Book title
  final String author;      // Book author
  final String condition;   // Book condition (New, Like New, Good, Used)
  final String swapFor;     // What the owner wants in exchange
  final String ownerId;     // Firebase Auth UID of book owner
  final String ownerEmail;  // Email of book owner
  final DateTime createdAt; // When the book was posted
  final String status;      // Book status (available, pending, swapped)
  final String? imageUrl;   // Base64 encoded book cover image (optional)

  /// Constructor for creating a Book instance
  /// Most fields are required, status defaults to 'available', imageUrl is optional
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.ownerId,
    required this.ownerEmail,
    required this.createdAt,
    this.status = 'available',  // Default status for new books
    this.imageUrl,              // Optional book cover image
  });

  /// Converts Book instance to Map for Firestore storage
  /// Excludes 'id' field as it's handled by Firestore document ID
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      // Convert DateTime to Firestore Timestamp
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  /// Factory constructor to create Book from Firestore document
  /// Handles type conversion and provides default values for missing fields
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id,  // Use Firestore document ID
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? '',
      swapFor: data['swapFor'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      // Convert Firestore Timestamp to DateTime
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'available',
      imageUrl: data['imageUrl'],  // Can be null
    );
  }

  /// Creates a copy of this Book with optionally updated fields
  /// Useful for updating book information while preserving other fields
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
      ownerId: ownerId,        // These fields don't change
      ownerEmail: ownerEmail,  // These fields don't change
      createdAt: createdAt,    // These fields don't change
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
