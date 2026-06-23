import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/no_params.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';

class Logout implements UseCase<Unit, NoParams> {
  final AuthRepository repository;

  Logout(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return repository.logout();
  }
}
