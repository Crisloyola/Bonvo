import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bonvo/core/usecases/no_params.dart';
import 'package:bonvo/features/auth/domain/repositories/auth_repository.dart';
import 'package:bonvo/features/auth/domain/usecases/login_with_email.dart';
import 'package:bonvo/features/auth/domain/usecases/login_with_google.dart';
import 'package:bonvo/features/auth/domain/usecases/logout.dart';
import 'package:bonvo/features/auth/domain/usecases/register_with_email.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final LoginWithEmail _loginWithEmail;
  final LoginWithGoogle _loginWithGoogle;
  final RegisterWithEmail _registerWithEmail;
  final Logout _logout;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required AuthRepository repository,
    required LoginWithEmail loginWithEmail,
    required LoginWithGoogle loginWithGoogle,
    required RegisterWithEmail registerWithEmail,
    required Logout logout,
  })  : _repository = repository,
        _loginWithEmail = loginWithEmail,
        _loginWithGoogle = loginWithGoogle,
        _registerWithEmail = registerWithEmail,
        _logout = logout,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginWithEmailRequested>(_onLoginWithEmail);
    on<AuthLoginWithGoogleRequested>(_onLoginWithGoogle);
    on<AuthRegisterWithEmailRequested>(_onRegisterWithEmail);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserRefreshRequested>(_onUserRefresh);
  }

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _repository.watchAuthState().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginWithEmail(
    AuthLoginWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginWithEmail(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLoginWithGoogle(
    AuthLoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginWithGoogle(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRegisterWithEmail(
    AuthRegisterWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _registerWithEmail(
      RegisterParams(name: event.name, email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _logout(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onUserRefresh(
    AuthUserRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Refresco en segundo plano: no pasa por AuthLoading (las pantallas
    // abiertas quedarían en blanco) y si falla se conserva la sesión actual.
    final result = await _repository.refreshCurrentUser();
    result.fold(
      (_) {},
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
