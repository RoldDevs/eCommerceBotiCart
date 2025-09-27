import 'package:boticart/features/auth/domain/entities/user.dart';
import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.signInWithGoogle();
  }
}