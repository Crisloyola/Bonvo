import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmail implements UseCase<AuthUser, RegisterParams> {
  final AuthRepository repository;

  RegisterWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(RegisterParams params) {
    return repository.registerWithEmail(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class RegisterParams {
  final String name;
  final String email;
  final String password;

  RegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });
}
