import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class IsEmailVerifiedUseCase {
  final AuthRepository repository;

  IsEmailVerifiedUseCase(this.repository);

  Future<bool> call() {
    return repository.isEmailVerified();
  }
}
