import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boticart/features/auth/presentation/providers/auth_providers.dart';
import 'package:boticart/features/auth/presentation/screens/login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isPasswordReset;
  final Function? onVerificationComplete;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
    this.onVerificationComplete,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isVerified = false;
  Timer? _timer;
  Timer? _verificationTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return email;

    final maskedUsername = '${username.substring(0, 2)}***';
    return '$maskedUsername@$domain';
  }

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _startVerificationCheck() {
    // Check immediately first
    _checkEmailVerification();

    // Then set up periodic checks
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isVerified) {
        _checkEmailVerification();
      } else {
        timer.cancel();
      }
    });
  }

  void _checkEmailVerification() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Force reload user before checking verification status
      await ref.read(reloadUserUseCaseProvider).call();
      final isVerified = await ref.read(isEmailVerifiedUseCaseProvider).call();

      if (isVerified && mounted) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });

        // For password reset flow, call the callback
        if (widget.isPasswordReset && widget.onVerificationComplete != null) {
          widget.onVerificationComplete!();
        } else {
          // For regular signup flow, show success message and navigate to login screen
          if (mounted) {
            // Navigate to login screen after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            });
          }
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });

    try {
      final sendEmailVerificationUseCase = ref.read(
        sendEmailVerificationUseCaseProvider,
      );
      await sendEmailVerificationUseCase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent!'),
            backgroundColor: Color(0xFF8ECAE6),
          ),
        );
      }

      _startResendTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _canResend = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Color(0xFF3BBFB2),
            ),
            const SizedBox(height: 24),
            Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 24,
                color: const Color(0xFF3BBFB2),
                fontWeight: FontWeight.bold,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification email to:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _maskEmail(widget.email),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Please check your inbox and click on the verification link to verify your email address.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: GoogleFonts.poppins().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isVerified)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF3BBFB2)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email verified successfully!',
                        style: TextStyle(
                          color: const Color(0xFF3BBFB2),
                          fontWeight: FontWeight.w500,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _canResend ? _resendVerificationEmail : null,
                    child: Text(
                      _canResend
                          ? 'Resend Verification Email'
                          : 'Resend in $_resendSeconds seconds',
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFF3BBFB2)
                            : Colors.grey,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
