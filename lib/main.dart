import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/homepage.dart';
import 'screens/email_verification_screen.dart';
import 'providers/book_provider.dart';
import 'providers/swap_provider.dart';
import 'providers/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookSwap());
}

class BookSwap extends StatelessWidget {
  const BookSwap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SwapProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'BookSwap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2C2855),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C2855)),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Checking if user is logged in or not
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2C2855)),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (!user.emailVerified) {
            return const EmailVerificationScreen();
          }
          return const Homepage();
        }

        return const WelcomeScreen();
      },
    );
  }
}
