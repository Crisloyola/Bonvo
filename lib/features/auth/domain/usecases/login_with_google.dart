import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/no_params.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';

class LoginWithGoogle implements UseCase<AuthUser, NoParams> {
  final AuthRepository repository;

  LoginWithGoogle(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) {
    return repository.loginWithGoogle();
  }
}
