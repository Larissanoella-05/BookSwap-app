import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:bookswap/Models/book.dart';

/// Service class for managing book listings (CRUD operations)
class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Initialize Storage with explicit bucket URL from config
  // This ensures we're connecting to the correct bucket
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'bookswap-fec4c.firebasestorage.app',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name in Firestore
  static const String _collectionName = 'books';

  /// CREATE: Add a new book listing
  /// 
  /// Steps:
  /// 1. Get current user
  /// 2. Upload cover image to Firebase Storage
  /// 3. Get download URL for the image
  /// 4. Create book document in Firestore with all book data
  Future<Book> createBook({
    required String title,
    required String author,
    required BookCondition condition,
    required File coverImageFile,  // The image file from device
  }) async {
    // Check if user is authenticated
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to create a book listing';
    }

    try {
      // Verify Storage is accessible
      debugPrint(' Starting image upload to Firebase Storage...');
      debugPrint(' Storage bucket: bookswap-fec4c.firebasestorage.app');
      debugPrint(' User ID: ${user.uid}');
      
      // Step 1: Upload image to Firebase Storage
      // Create a unique filename to avoid conflicts
      final String fileName = 'book_covers/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('📁 File path: $fileName');
      
      final Reference storageRef = _storage.ref().child(fileName);
      
      // Upload metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint(' Uploading file...');
      // Upload the file with metadata
      final UploadTask uploadTask = storageRef.putFile(
        coverImageFile,
        metadata,
      );
      
      // Wait for upload to complete with progress tracking
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {
        debugPrint(' Upload task completed');
      });
      
      debugPrint(' Image uploaded successfully. Bytes: ${snapshot.bytesTransferred}');
      
      // Step 2: Get download URL
      debugPrint(' Getting download URL...');
      final String coverImageUrl = await storageRef.getDownloadURL();
      debugPrint(' Image URL: $coverImageUrl');

      // Step 3: Create book data
      final now = DateTime.now();
      final bookData = {
        'title': title,
        'author': author,
        'condition': condition.displayName,
        'coverImageUrl': coverImageUrl,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Step 4: Add document to Firestore
      final DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(bookData);

      // Step 5: Return Book object with the generated ID
      final doc = await docRef.get();
      return Book.fromFirestore(doc);
    } on FirebaseException catch (e) {
      // Handle specific Firebase Storage errors
      String errorMessage = 'Failed to create book listing';
      
      if (e.code == 'object-not-found' || e.code == '-13010') {
        errorMessage = 'Firebase Storage is not enabled or not configured. '
            'Please enable Firebase Storage in your Firebase Console.';
      } else if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please check Firebase Storage security rules.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication required. Please log in again.';
      } else {
        errorMessage = 'Failed to create book listing: ${e.message ?? e.code}';
      }
      
      debugPrint(' Firebase Error: ${e.code} - ${e.message}');
      throw errorMessage;
    } catch (e) {
      debugPrint(' Unexpected error: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  /// READ: Get all book listings (for Browse feed)
  /// 
  /// Returns a stream that listens to real-time changes in the books collection
  /// When a book is added, updated, or deleted, the stream automatically updates
  Stream<List<Book>> getAllBooks() {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)  // Newest first
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw 'Failed to fetch books: $e';
    }
  }

  /// READ: Get a single book by ID
  Future<Book> getBookById(String bookId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .get();

      if (!doc.exists) {
        throw 'Book not found';
      }

      return Book.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw 'Failed to fetch book: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// READ: Get all books by a specific user
  Stream<List<Book>> getBooksByUser(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw 'Failed to fetch user books: $e';
    }
  }

  /// UPDATE: Edit an existing book listing
  /// 
  /// Only the owner of the book can update it
  /// If a new cover image is provided, upload it and update the URL
  Future<Book> updateBook({
    required String bookId,
    String? title,
    String? author,
    BookCondition? condition,
    File? coverImageFile,  // Optional: only if user wants to change the image
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to update a book listing';
    }

    try {
      // Step 1: Get the existing book to verify ownership
      final bookDoc = await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .get();

      if (!bookDoc.exists) {
        throw 'Book not found';
      }

      final existingBook = Book.fromFirestore(bookDoc);

      // Step 2: Check if user owns this book
      if (existingBook.userId != user.uid) {
        throw 'You can only edit your own book listings';
      }

      // Step 3: Prepare update data
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (author != null) updateData['author'] = author;
      if (condition != null) updateData['condition'] = condition.displayName;

      // Step 4: If new image provided, upload it
      String? newImageUrl;
      if (coverImageFile != null) {
        // Delete old image from storage
        try {
          final oldImageRef = _storage.refFromURL(existingBook.coverImageUrl);
          await oldImageRef.delete();
        } catch (e) {
          // If deletion fails, continue anyway
          debugPrint('Warning: Could not delete old image: $e');
        }

        // Upload new image
        final String fileName = 'book_covers/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = _storage.ref().child(fileName);
        
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );
        
        await storageRef.putFile(coverImageFile, metadata);
        newImageUrl = await storageRef.getDownloadURL();
        updateData['coverImageUrl'] = newImageUrl;
      }

      // Step 5: Update Firestore document
      await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .update(updateData);

      // Step 6: Return updated book
      final updatedDoc = await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .get();
      return Book.fromFirestore(updatedDoc);
    } on FirebaseException catch (e) {
      throw 'Failed to update book: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// DELETE: Remove a book listing
  /// 
  /// Only the owner of the book can delete it
  /// Also deletes the associated cover image from Firebase Storage
  Future<void> deleteBook(String bookId) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to delete a book listing';
    }

    try {
      // Step 1: Get the book to verify ownership and get image URL
      final bookDoc = await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .get();

      if (!bookDoc.exists) {
        throw 'Book not found';
      }

      final book = Book.fromFirestore(bookDoc);

      // Step 2: Check if user owns this book
      if (book.userId != user.uid) {
        throw 'You can only delete your own book listings';
      }

      // Step 3: Delete image from Firebase Storage
      try {
        final imageRef = _storage.refFromURL(book.coverImageUrl);
        await imageRef.delete();
      } catch (e) {
        // If deletion fails, continue anyway (orphaned files aren't critical)
        debugPrint('Warning: Could not delete image from storage: $e');
      }

      // Step 4: Delete document from Firestore
      await _firestore
          .collection(_collectionName)
          .doc(bookId)
          .delete();
    } on FirebaseException catch (e) {
      throw 'Failed to delete book: ${e.message}';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }
}

