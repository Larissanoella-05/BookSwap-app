import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

class BookProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Book> _allBooks = [];
  List<Book> _myBooks = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get allBooks => _allBooks;
  List<Book> get myBooks => _myBooks;
  bool get isLoading => _isLoading;
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

  // Listening to books in real time
  void listenToAllBooks() {
    _firestoreService.getAllBooks().listen(
      (books) {
        _allBooks = books;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load books: $error';
        notifyListeners();
      },
    );
  }

  void listenToMyBooks() {
    _firestoreService.getMyBooks().listen(
      (books) {
        _myBooks = books;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load your books: $error';
        notifyListeners();
      },
    );
  }

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

  Future<void> deleteBook(String bookId) async {
    try {
      await _firestoreService.deleteBook(bookId);
    } catch (e) {
      _error = 'Failed to delete book: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
