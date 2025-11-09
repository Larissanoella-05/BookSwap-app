import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Firebase/auth_service.dart';
import 'package:bookswap/routes/routes.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      // Reload user to get latest verification status
      await _authService.reloadUser();
      
      // Force refresh token to get latest verification status
      final user = _authService.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force refresh
        await user.reload();
        
        // Invalidate providers to force AuthWrapper to re-check
        ref.invalidate(authStateChangesProvider);
        ref.invalidate(currentUserStreamProvider);
        
        // Wait a bit for the stream to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        final updatedUser = _authService.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          // AuthWrapper will automatically navigate to Home
          // But we can also navigate manually to be safe
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email not verified yet. Please check your inbox and click the verification link.'),
                backgroundColor: Colors.orange,
              ),
            );
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
      setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await _authService.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final email = currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 230, 193),
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(height: 24),
              const Text(
                'Email Verification Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:\n$email',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Please check your inbox (and spam/junk folder) and click the verification link to activate your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 100, 100, 100),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '📧 Email Delivery Tips:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Check your spam/junk folder\n'
                      '• Emails may take 1-5 minutes to arrive\n'
                      '• Make sure the email address is correct\n'
                      '• If blocked due to too many requests, wait 5-10 minutes',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkVerification,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isChecking ? 'Checking...' : 'I\'ve Verified My Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _resendVerification,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend Verification Email'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

