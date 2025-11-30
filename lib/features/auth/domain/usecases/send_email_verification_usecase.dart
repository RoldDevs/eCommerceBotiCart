import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class SendEmailVerificationUseCase {
  final AuthRepository repository;

  SendEmailVerificationUseCase(this.repository);

  Future<void> call() {
    return repository.sendEmailVerification();
  }
}
