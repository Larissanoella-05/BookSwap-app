import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/routes/routes.dart';
import 'package:bookswap/Screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _getUserInitial(User? user) {
  if (user == null) return '?';
  
  // Try displayName first
  if (user.displayName != null && user.displayName!.isNotEmpty) {
    return user.displayName!.substring(0, 1).toUpperCase();
  }
  
  // Fall back to email
  if (user.email != null && user.email!.isNotEmpty) {
    return user.email!.substring(0, 1).toUpperCase();
  }
  
  return '?';
}

AppBar topNavigation(BuildContext context, User? user, WidgetRef ref) {
  return AppBar(
    toolbarHeight: 80,
    actionsPadding: EdgeInsets.all(10),
    backgroundColor: const Color.fromARGB(255, 5, 22, 46),
    titleTextStyle: TextStyle(color: Colors.white),
    title: Text('Browse Listings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    centerTitle: true,
    leading: IconButton(
      onPressed: () async {
        if (context.mounted) {
          Navigator.pushNamed(context, AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error logging out'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 250, 174, 22)),
    ),
    actions: [
      GestureDetector(
        onTap: () {
          // Navigate to settings tab (index 3)
          ref.read(selectedTabIndexProvider.notifier).state = 3;
        },
        child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
            child: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                ? Image(
                    image: NetworkImage(user.photoURL!),
                    width: double.infinity,
                    height: double.infinity,
            fit: BoxFit.cover,
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color.fromARGB(255, 190, 190, 190),
                    child: Text(
                      _getUserInitial(user),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ],
  );
}