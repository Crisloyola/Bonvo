import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';

class LoginWithEmail implements UseCase<AuthUser, LoginParams> {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(LoginParams params) {
    return repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}
