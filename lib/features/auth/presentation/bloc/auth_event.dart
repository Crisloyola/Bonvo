import 'package:equatable/equatable.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Emitido al iniciar la app: suscribe al stream de auth de Firebase.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Emitido cuando Firebase notifica un cambio de sesión (login/logout externo).
class AuthUserChanged extends AuthEvent {
  final AuthUser? user;
  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLoginWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginWithEmailRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLoginWithGoogleRequested extends AuthEvent {
  const AuthLoginWithGoogleRequested();
}

class AuthRegisterWithEmailRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterWithEmailRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Recarga el perfil del usuario desde Firestore (útil tras crear un negocio).
class AuthUserRefreshRequested extends AuthEvent {
  const AuthUserRefreshRequested();
}
