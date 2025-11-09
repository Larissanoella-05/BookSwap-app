//
// NAVIGATION ROUTES
//
// 
// This file defines all named routes in the application.
// 
// NAVIGATION SYSTEM:
// - Uses Flutter's named routes (MaterialApp.onGenerateRoute)
// - Routes are defined as constants in AppRoutes class
// - generateRoute() function maps route names to screen widgets
// 
// USAGE:
//   Navigator.pushNamed(context, AppRoutes.home);
//   Navigator.pushNamed(context, AppRoutes.addBook, arguments: book);
// 
// ROUTES:
// - / (login) - Login screen (initial route)
// - /signup - User registration screen
// - /home - Main app screen with bottom navigation
// - /add-book - Add/edit book listing screen
// - /chat-detail - Individual chat conversation screen
// 
// ============================================================================

import 'package:flutter/material.dart';
import 'package:bookswap/Screens/login.dart';
import 'package:bookswap/Screens/signup.dart';
import 'package:bookswap/Screens/home.dart';
import 'package:bookswap/Screens/add_book.dart';
import 'package:bookswap/Screens/chat_detail.dart';
import 'package:bookswap/Models/chat.dart';
import 'package:bookswap/Models/book.dart';

// Route name constants
// 
// All route paths are defined here as static constants.
// This makes it easy to reference routes throughout the app
// and prevents typos in route names.
class AppRoutes {
  // Login screen - initial route when app starts
  static const String login = '/';
  
  // User registration screen
  static const String signup = '/signup';
  
  // Main app screen with bottom navigation (Browse, My Listings, Chats, Settings)
  static const String home = '/home';
  
  // Add or edit a book listing
  // Arguments: Book? (null for new book, Book object for editing)
  static const String addBook = '/add-book';
  
  // Individual chat conversation screen
  // Arguments: Chat (required - the chat to display)
  static const String chatDetail = '/chat-detail';
}

// Route generator function
// 
// Maps route names to their corresponding screen widgets.
// Called automatically by MaterialApp when using Navigator.pushNamed().
// 
// Parameters:
// - settings.name: The route name (e.g., AppRoutes.home)
// - settings.arguments: Optional data to pass to the screen
// 
// Returns a MaterialPageRoute that will be pushed onto the navigation stack.
Route generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const Login());
      
    case AppRoutes.signup:
      return MaterialPageRoute(builder: (_) => const Signup());
      
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const Home());
      
    case AppRoutes.addBook:
      // Extract Book argument (null for new book, Book for editing)
      final book = settings.arguments as Book?;
      return MaterialPageRoute(builder: (_) => AddBook(book: book));
      
    case AppRoutes.chatDetail:
      // Extract Chat argument (required)
      final chat = settings.arguments as Chat;
      return MaterialPageRoute(
        builder: (_) => ChatDetailScreen(chat: chat),
      );
      
    default:
      // Fallback for unknown routes (shouldn't happen in production)
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}

