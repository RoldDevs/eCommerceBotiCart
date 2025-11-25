import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boticart/features/auth/presentation/providers/auth_providers.dart';
import 'package:boticart/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:boticart/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:boticart/features/auth/presentation/widgets/terms_and_privacy_modal.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TermsAndPrivacyModal(
        onAccept: () {
          setState(() {
            _termsAccepted = true;
          });
          Navigator.of(context).pop();
          _signUp();
        },
        onDecline: () {
          Navigator.of(context).pop();
          setState(() {
            _termsAccepted = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF8ECAE6),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8ECAE6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Empty SizedBox to balance the row
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 30),

                // First Name Field
                CustomTextField(
                  controller: _firstNameController,
                  hintText: 'First Name',
                  hasError: _hasError && _firstNameController.text.isEmpty,
                ),
                const SizedBox(height: 16),

                // Last Name Field
                CustomTextField(
                  controller: _lastNameController,
                  hintText: 'Last Name',
                  hasError: _hasError && _lastNameController.text.isEmpty,
                ),
                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  hasError: _hasError && _emailController.text.isEmpty,
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  hasError: _hasError && _passwordController.text.isEmpty,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 30),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_validateInputs()) {
                            _showTermsModal();
                          }
                        },
                  style:
                      ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return const Color(0xFF8ECAE6).withAlpha(128);
                              }
                              return const Color(0xFF8ECAE6);
                            }),
                      ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please fill in all required fields';
      });
      return false;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a valid email address';
      });
      return false;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must be at least 6 characters';
      });
      return false;
    }

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    return true;
  }

  Future<void> _signUp() async {
    if (!_termsAccepted) {
      return;
    }

    // If validation passes, proceed with sign up
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final signUpUseCase = ref.read(signUpUseCaseProvider);

      final user = await signUpUseCase(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        contact: '', // Empty - can be filled later in account screen
        address: '', // Empty - can be filled later in account screen
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: user.email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for this email';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid';
      }

      setState(() {
        _hasError = true;
        _errorMessage = errorMessage;
        _termsAccepted = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _termsAccepted = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
