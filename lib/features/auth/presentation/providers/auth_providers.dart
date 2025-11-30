import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boticart/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';
import 'package:boticart/features/auth/domain/usecases/signup_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/login_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/update_user_verification_status_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/is_email_verified_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/reload_user_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:boticart/features/auth/domain/usecases/check_email_exists_usecase.dart';

// Firebase providers
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

// Use case providers
final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final updateUserVerificationStatusUseCaseProvider =
    Provider<UpdateUserVerificationStatusUseCase>((ref) {
      return UpdateUserVerificationStatusUseCase(
        ref.watch(authRepositoryProvider),
      );
    });

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

// Email verification providers
final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
      return SendEmailVerificationUseCase(ref.watch(authRepositoryProvider));
    });

final isEmailVerifiedUseCaseProvider = Provider<IsEmailVerifiedUseCase>((ref) {
  return IsEmailVerifiedUseCase(ref.watch(authRepositoryProvider));
});

final reloadUserUseCaseProvider = Provider<ReloadUserUseCase>((ref) {
  return ReloadUserUseCase(ref.watch(authRepositoryProvider));
});

// Google Sign-In provider
final googleSignInUseCaseProvider = Provider<GoogleSignInUseCase>((ref) {
  return GoogleSignInUseCase(ref.watch(authRepositoryProvider));
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final checkEmailExistsUseCaseProvider = Provider<CheckEmailExistsUseCase>((
  ref,
) {
  return CheckEmailExistsUseCase(ref.watch(authRepositoryProvider));
});
