import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Firebase/auth_service.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Services/swap_providers.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Services/notification_listener.dart';
import 'package:bookswap/Layouts/settings-layout.dart';
import 'package:bookswap/Screens/home.dart';
import 'package:bookswap/routes/routes.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Force reload and refresh to ensure latest verification status
      if (userCredential?.user != null) {
        await userCredential!.user!.reload();
        await userCredential.user!.getIdToken(true);
        
        // Invalidate ALL providers to start completely fresh
        // This ensures no cached data from previous sessions or accounts
        ref.invalidate(authStateChangesProvider);
        ref.invalidate(currentUserStreamProvider);
        ref.invalidate(currentUserProvider);
        ref.invalidate(selectedTabIndexProvider);
        ref.invalidate(notificationsEnabledProvider);
        ref.invalidate(emailUpdatesEnabledProvider);
        ref.invalidate(lastSeenSwapIdsProvider);
        ref.invalidate(lastSeenMessageIdsProvider);
        
        // Invalidate all data providers to start fresh
        ref.invalidate(allBooksProvider);
        ref.invalidate(userBooksProvider);
        ref.invalidate(myOffersProvider);
        ref.invalidate(receivedOffersProvider);
        ref.invalidate(userChatsProvider);
        ref.invalidate(chatMessagesProvider);
        
        // Debug: Check verification status
        final isVerified = userCredential.user!.emailVerified;
        debugPrint('Login: User ${userCredential.user!.email} verified: $isVerified');
        
        // Navigate based on verification status
        if (mounted) {
          if (isVerified) {
            // Navigate to home
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            // Navigate to email verification screen
            // First navigate to root to ensure AuthWrapper is in tree, then it will show EmailVerificationScreen
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/books.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 7, 7, 42),
                      Color.fromARGB(255, 7, 7, 42).withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book,
                            size: 100,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'BookSwap',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Swap Your Books With Other Students',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sign in to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(156, 255, 255, 255),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 60),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 250, 174, 22),
                                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // TextButton(
                          //   onPressed: () async {
                          //     // Show dialog to resend verification email
                          //     final email = await showDialog<String>(
                          //       context: context,
                          //       builder: (context) {
                          //         final emailController = TextEditingController();
                          //         return AlertDialog(
                          //           title: const Text('Resend Verification Email'),
                          //           content: Column(
                          //             mainAxisSize: MainAxisSize.min,
                          //             children: [
                          //               const Text('Enter your email address to resend the verification email:'),
                          //               const SizedBox(height: 16),
                          //               TextField(
                          //                 controller: emailController,
                          //                 keyboardType: TextInputType.emailAddress,
                          //                 decoration: const InputDecoration(
                          //                   labelText: 'Email',
                          //                   border: OutlineInputBorder(),
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //           actions: [
                          //             TextButton(
                          //               onPressed: () => Navigator.pop(context),
                          //               child: const Text('Cancel'),
                          //             ),
                          //             ElevatedButton(
                          //               onPressed: () {
                          //                 Navigator.pop(context, emailController.text.trim());
                          //               },
                          //               child: const Text('Send'),
                          //             ),
                          //           ],
                          //         );
                          //       },
                          //     );

                          //     if (email != null && email.isNotEmpty) {
                          //       if (mounted) {
                          //         ScaffoldMessenger.of(context).showSnackBar(
                          //           const SnackBar(
                          //             content: Text(
                          //               'Please try logging in. If your email is not verified, '
                          //               'you\'ll be redirected to the verification screen where you can resend the email.',
                          //             ),
                          //             backgroundColor: Colors.blue,
                          //             duration: Duration(seconds: 4),
                          //           ),
                          //         );
                          //       }
                          //     }
                          //   },
                          //   child: const Text(
                          //     'Resend Verification Email',
                          //     style: TextStyle(
                          //       color: Colors.white70,
                          //       fontSize: 12,
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.signup);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Don\'t have an account?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                color: const Color.fromARGB(255, 250, 174, 22),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
