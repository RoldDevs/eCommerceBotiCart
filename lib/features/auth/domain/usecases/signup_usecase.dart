import 'package:boticart/features/auth/domain/entities/user.dart';
import 'package:boticart/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> call({
    required String firstName,
    required String lastName,
    required String email,
    String contact = '',
    String address = '',
    required String password,
  }) {
    return repository.signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      contact: contact,
      address: address,
      password: password,
    );
  }
}
