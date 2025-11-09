import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class FirestoreService {
  final CollectionReference _booksCollection = FirebaseFirestore.instance
      .collection('books');

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Adding new book to Firestore
  Future<String> addBook({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    String? imageUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not logged in');

      final bookData = {
        'title': title,
        'author': author,
        'condition': condition,
        'swapFor': swapFor,
        'ownerId': user.uid,
        'ownerEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available',
        'imageUrl': imageUrl,
      };

      DocumentReference docRef = await _booksCollection.add(bookData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  // Getting all books for browse listings
  Stream<List<Book>> getAllBooks() {
    return _booksCollection.snapshots().map((snapshot) {
      final books = snapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .toList();
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return books;
    });
  }

  // Getting only my books
  Stream<List<Book>> getMyBooks() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _booksCollection
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final books = snapshot.docs
              .map((doc) => Book.fromFirestore(doc))
              .toList();
          books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return books;
        });
  }

  // Updating book details
  Future<void> updateBook({
    required String bookId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _booksCollection.doc(bookId).update(updates);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Deleting book
  Future<void> deleteBook(String bookId) async {
    try {
      await _booksCollection.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Getting single book by ID
  Future<Book?> getBookById(String bookId) async {
    try {
      DocumentSnapshot doc = await _booksCollection.doc(bookId).get();

      if (doc.exists) {
        return Book.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
  }

  // Updating book status
  Future<void> updateBookStatus(String bookId, String newStatus) async {
    try {
      await _booksCollection.doc(bookId).update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
