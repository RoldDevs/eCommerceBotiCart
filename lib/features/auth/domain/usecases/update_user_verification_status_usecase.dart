import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class UpdateUserVerificationStatusUseCase {
  final AuthRepository repository;

  UpdateUserVerificationStatusUseCase(this.repository);

  Future<void> call({
    required String userId,
  }) {
    return repository.updateUserVerificationStatus(
      userId: userId,
    );
  }
}