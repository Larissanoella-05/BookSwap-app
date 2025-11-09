//
// BOOK MODEL
//
//
// Data model representing a book listing in the app.
//
// STORAGE:
// - Stored in Cloud Firestore collection: 'books'
// - Cover images stored in Firebase Storage: 'book_covers/{userId}/{timestamp}.jpg'
//
// USAGE:
// - Created when user adds a new book listing
// - Displayed in Browse screen (all books) and My Listings screen (user's books)
// - Used in swap requests (users can request to swap for a book)
//
//

import 'package:cloud_firestore/cloud_firestore.dart';

// Book condition enum
//
// Represents the physical condition of a book.
// Used when creating/editing book listings.
enum BookCondition {
  newBook, // New - book is brand new
  likeNew, // Like New - barely used, looks new
  good, // Good - some wear but still in good condition
  used, // Used - noticeable wear but functional
}

/// Extension to convert enum to/from string
extension BookConditionExtension on BookCondition {
  String get displayName {
    switch (this) {
      case BookCondition.newBook:
        return 'New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.used:
        return 'Used';
    }
  }

  static BookCondition fromString(String value) {
    switch (value) {
      case 'New':
        return BookCondition.newBook;
      case 'Like New':
        return BookCondition.likeNew;
      case 'Good':
        return BookCondition.good;
      case 'Used':
        return BookCondition.used;
      default:
        return BookCondition.good;
    }
  }
}

// Book model representing a book listing
//
// This is the main data model for books in the app.
// Each book listing belongs to a user and can be swapped with other users.
class Book {
  // Document ID from Firestore (unique identifier)
  final String id;

  // Book title (e.g., "The Great Gatsby")
  final String title;

  // Book author (e.g., "F. Scott Fitzgerald")
  final String author;

  // Physical condition of the book (New, Like New, Good, Used)
  final BookCondition condition;

  // URL to the cover image (stored in Firebase Storage)
  // Format: book_covers/{userId}/{timestamp}.jpg
  final String coverImageUrl;

  // ID of the user who created this listing (Firebase Auth UID)
  final String userId;

  // Email of the user who created the listing (for display purposes)
  final String userEmail;

  // Swap status of the book:
  // - null: Available for swapping
  // - 'pending': Has a pending swap request
  // - 'swapped': Already swapped with another user
  final String? swapStatus;

  // Timestamp when the listing was created
  final DateTime createdAt;

  // Timestamp when the listing was last updated
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.coverImageUrl,
    required this.userId,
    required this.userEmail,
    this.swapStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Book from a Firestore document
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: BookConditionExtension.fromString(data['condition'] ?? 'Good'),
      coverImageUrl: data['coverImageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      swapStatus: data['swapStatus'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Book to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'condition': condition.displayName,
      'coverImageUrl': coverImageUrl,
      'userId': userId,
      'userEmail': userEmail,
      'swapStatus': swapStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of this Book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    BookCondition? condition,
    String? coverImageUrl,
    String? userId,
    String? userEmail,
    String? swapStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      swapStatus: swapStatus ?? this.swapStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
