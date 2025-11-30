import 'package:boticart/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp({
    required String firstName,
    required String lastName,
    required String email,
    String contact = '',
    String address = '',
    required String password,
  });

  Future<UserEntity?> login({required String email, required String password});

  Future<void> sendEmailVerification();

  Future<bool> isEmailVerified();

  Future<void> updateUserVerificationStatus({required String userId});

  Future<void> updateUserStatus({
    required String userId,
    required String status,
  });

  Future<void> resetPassword({required String email});

  Future<void> reloadUser();

  Future<UserEntity?> signInWithGoogle();

  Future<bool> checkEmailExists({required String email});
}
