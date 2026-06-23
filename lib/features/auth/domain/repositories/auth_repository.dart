import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// Stream que emite el usuario actual (o null si no hay sesión).
  /// Se usa en el BLoC para reaccionar automáticamente a cambios de sesión.
  Stream<AuthUser?> watchAuthState();

  Future<Either<Failure, AuthUser>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> loginWithGoogle();

  Future<Either<Failure, Unit>> logout();

  /// Re-lee el perfil del usuario autenticado desde Firestore.
  Future<Either<Failure, AuthUser>> refreshCurrentUser();
}
