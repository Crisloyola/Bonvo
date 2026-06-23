import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Stream<AuthUser?> watchAuthState() => _remote.watchAuthState();

  @override
  Future<Either<Failure, AuthUser>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.loginWithEmail(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> loginWithGoogle() async {
    try {
      final user = await _remote.loginWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _remote.logout();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> refreshCurrentUser() async {
    try {
      final user = await _remote.refreshCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
