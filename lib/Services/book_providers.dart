import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/book_service.dart';
import 'package:bookswap/Models/book.dart';

/// Provider for BookService instance (singleton)
final bookServiceProvider = Provider<BookService>((ref) => BookService());

/// StreamProvider for all book listings (Browse feed)
/// 
/// This automatically listens to Firestore and updates the UI
/// whenever books are added, updated, or deleted
final allBooksProvider = StreamProvider<List<Book>>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getAllBooks();
});

/// StreamProvider for books by a specific user
/// 
/// Use this to show a user's own listings
final userBooksProvider = StreamProvider.family<List<Book>, String>((ref, userId) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getBooksByUser(userId);
});

/// Provider for getting a single book by ID
final bookByIdProvider = FutureProvider.family<Book, String>((ref, bookId) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getBookById(bookId);
});


