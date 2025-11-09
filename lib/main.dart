import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/routes/routes.dart';
import 'package:bookswap/Services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } else {
      debugPrint(' Firebase already initialized');
    }
  } catch (e, stackTrace) {
    debugPrint(' Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint(
      'Note: The google-services.json plugin may not have processed correctly.',
    );
    debugPrint('Try: flutter clean, then flutter pub get, then full rebuild');
  }

  try {
    await NotificationService().initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 29, 78, 255),
        ),
      ),

      initialRoute: AppRoutes.login,

      onGenerateRoute: generateRoute,
    );
  }
}
