import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class ReloadUserUseCase {
  final AuthRepository repository;

  ReloadUserUseCase(this.repository);

  Future<void> call() {
    return repository.reloadUser();
  }
}