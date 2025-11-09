// Core Flutter and Firebase imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// App configuration and screens
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/homepage.dart';
import 'screens/email_verification_screen.dart';

// State management providers
import 'providers/book_provider.dart';
import 'providers/swap_provider.dart';
import 'providers/chat_provider.dart';

/// Main entry point of the BookSwap application
/// Initializes Firebase and sets up the app with Provider state management
Future<void> main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Launch the app
  runApp(const BookSwap());
}

/// Root widget of the BookSwap application
/// Sets up Provider state management and app theme
class BookSwap extends StatelessWidget {
  const BookSwap({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the entire app to provide state management
    return MultiProvider(
      providers: [
        // BookProvider: Manages book listings and CRUD operations
        ChangeNotifierProvider(create: (_) => BookProvider()),
        // SwapProvider: Handles swap offers and their states
        ChangeNotifierProvider(create: (_) => SwapProvider()),
        // ChatProvider: Manages chat messages and unread counts
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'BookSwap',
        debugShowCheckedModeBanner: false,
        // App theme with custom purple color scheme
        theme: ThemeData(
          primaryColor: const Color(0xFF2C2855), // Dark purple
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C2855)),
        ),
        // AuthWrapper determines which screen to show based on auth state
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Authentication wrapper that determines which screen to display
/// based on the user's authentication and verification status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to Firebase auth state changes in real-time
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2C2855),
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Check if email is verified - if not, show verification screen
          if (!user.emailVerified) {
            return const EmailVerificationScreen();
          }

          // User is authenticated and verified - show main app
          return const Homepage();
        }

        // User is not logged in - show welcome/login screen
        return const WelcomeScreen();
      },
    );
  }
}
