import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

/// Provider class that manages book-related state and operations
/// Handles CRUD operations for books and provides real-time updates
class BookProvider with ChangeNotifier {
  // Service for Firestore database operations
  final FirestoreService _firestoreService = FirestoreService();

  // Private state variables
  List<Book> _allBooks = [];      // All books from all users
  List<Book> _myBooks = [];       // Current user's books only
  bool _isLoading = false;        // Loading state for UI
  String? _error;                 // Error message if operations fail

  // Public getters for accessing state from UI
  /// Returns all books from all users (for browse listings)
  List<Book> get allBooks => _allBooks;
  
  /// Returns only the current user's books (for my listings)
  List<Book> get myBooks => _myBooks;
  
  /// Returns current loading state
  bool get isLoading => _isLoading;
  
  /// Returns current error message if any
  String? get error => _error;

  Future<void> fetchAllBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _firestoreService.getAllBooks().first;
      _allBooks = books;
      _error = null;
    } catch (e) {
      _error = 'Failed to load books: $e';
      _allBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _firestoreService.getMyBooks().first;
      _myBooks = books;
      _error = null;
    } catch (e) {
      _error = 'Failed to load your books: $e';
      _myBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets up real-time listener for all books from all users
  /// Used in Browse Listings screen to show live updates
  void listenToAllBooks() {
    _firestoreService.getAllBooks().listen(
      (books) {
        _allBooks = books;
        _error = null;
        // Notify UI to rebuild with new data
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load books: $error';
        notifyListeners();
      },
    );
  }

  /// Sets up real-time listener for current user's books only
  /// Used in My Listings screen to show user's own books
  void listenToMyBooks() {
    _firestoreService.getMyBooks().listen(
      (books) {
        _myBooks = books;
        _error = null;
        // Notify UI to rebuild with updated user books
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load your books: $error';
        notifyListeners();
      },
    );
  }

  /// Adds a new book to Firestore
  /// Called when user posts a new book listing
  Future<void> addBook({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    required String imageUrl,
  }) async {
    try {
      await _firestoreService.addBook(
        title: title,
        author: author,
        condition: condition,
        swapFor: swapFor,
        imageUrl: imageUrl,
      );
    } catch (e) {
      _error = 'Failed to add book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing book in Firestore
  /// Called when user edits their book listing
  Future<void> updateBook({
    required String bookId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestoreService.updateBook(bookId: bookId, updates: updates);
    } catch (e) {
      _error = 'Failed to update book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a book from Firestore
  /// Called when user removes their book listing
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestoreService.deleteBook(bookId);
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clears any existing error state
  /// Used to reset error messages in UI
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
