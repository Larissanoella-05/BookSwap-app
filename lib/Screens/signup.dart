import 'package:flutter/material.dart';
import 'package:bookswap/Firebase/auth_service.dart';
import 'package:bookswap/routes/routes.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      // Try to send verification email, but don't fail signup if it fails
      try {
        await _authService.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account created! Verification email sent to ${_emailController.text.trim()}\n'
                'Please check your inbox (and spam folder) and click the verification link.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (verificationError) {
        // Account was created successfully, but verification email failed
        // This can happen due to rate limiting - user can resend later
        String errorMessage = verificationError.toString();
        String userMessage = 'Account created successfully!';
        
        if (errorMessage.contains('too-many-requests')) {
          userMessage = 'Account created! Verification email was blocked due to too many requests. '
              'Please try again in a few minutes. You can resend it from the email verification screen after logging in.';
        } else {
          userMessage = 'Account created successfully! However, we couldn\'t send the verification email right now. '
              'You can resend it from the email verification screen after logging in.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
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
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
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
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.login);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Sign In',
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