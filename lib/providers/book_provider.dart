import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/book.dart';

class BookProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Book> _allBooks = [];
  List<Book> _myBooks = [];
  bool _isLoading = false;
  StreamSubscription? _allBooksSubscription;
  StreamSubscription? _myBooksSubscription;

  List<Book> get allBooks => _allBooks;
  List<Book> get myBooks => _myBooks;
  bool get isLoading => _isLoading;

  BookProvider() {
    _listenToBooks();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToMyBooks();
      } else {
        _myBooks = [];
        _myBooksSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _listenToBooks() {
    _allBooksSubscription?.cancel();
    _allBooksSubscription = _firestore.collection('books').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      _allBooks = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  void _listenToMyBooks() {
    _myBooksSubscription?.cancel();
    if (_auth.currentUser != null) {
      _myBooksSubscription = _firestore
          .collection('books')
          .where('ownerId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _myBooks = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
        notifyListeners();
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('book_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> addBook(String title, String author, BookCondition condition, File? imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      User? user = _auth.currentUser;
      if (user == null) return 'User not authenticated';

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      Book newBook = Book(
        id: '',
        title: title,
        author: author,
        condition: condition,
        imageUrl: imageUrl,
        ownerId: user.uid,
        ownerEmail: user.email ?? '',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('books').add(newBook.toFirestore());
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateBook(String bookId, String title, String author, BookCondition condition, String? imageUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('books').doc(bookId).update({
        'title': title,
        'author': author,
        'condition': condition.index,
        'imageUrl': imageUrl,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteBook(String bookId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('books').doc(bookId).delete();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> requestSwap(String bookId) async {
    try {
      _isLoading = true;
      notifyListeners();

      User? user = _auth.currentUser;
      if (user == null) return 'User not authenticated';

      await _firestore.collection('books').doc(bookId).update({
        'status': SwapStatus.pending.index,
        'swapRequesterId': user.uid,
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Book> get availableBooks => _allBooks.where((book) => 
      book.status == SwapStatus.available && 
      book.ownerId != _auth.currentUser?.uid).toList();

  List<Book> get pendingOffers => _allBooks.where((book) => 
      book.swapRequesterId == _auth.currentUser?.uid && 
      book.status == SwapStatus.pending).toList();

  @override
  void dispose() {
    _allBooksSubscription?.cancel();
    _myBooksSubscription?.cancel();
    super.dispose();
  }
}