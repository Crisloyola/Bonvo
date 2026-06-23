import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/features/auth/data/models/auth_user_model.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthUserModel?> watchAuthState();
  Future<AuthUserModel> loginWithEmail({required String email, required String password});
  Future<AuthUserModel> registerWithEmail({required String name, required String email, required String password});
  Future<AuthUserModel> loginWithGoogle();
  Future<void> logout();
  Future<AuthUserModel> refreshCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Stream<AuthUserModel?> watchAuthState() {
    // Escucha el documento Firestore del usuario en tiempo real.
    // Así cualquier cambio (businessIds, puntos, etc.) se refleja
    // inmediatamente sin necesidad de re-login.
    final controller = StreamController<AuthUserModel?>();
    StreamSubscription? firestoreSub;

    final authSub = _firebaseAuth.authStateChanges().listen((firebaseUser) {
      firestoreSub?.cancel();
      if (firebaseUser == null) {
        controller.add(null);
        return;
      }
      firestoreSub = _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen((snap) {
        if (!snap.exists || snap.data() == null) {
          controller.add(null);
          return;
        }
        try {
          controller.add(AuthUserModel.fromFirestore(snap.data()!, firebaseUser.uid));
        } catch (_) {
          controller.add(null);
        }
      });
    });

    controller.onCancel = () {
      authSub.cancel();
      firestoreSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<AuthUserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fetchUserModel(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  @override
  Future<AuthUserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final model = AuthUserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.client,
      );
      await _firestore.collection('users').doc(uid).set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    }
  }

  @override
  Future<AuthUserModel> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Inicio con Google cancelado.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Si el usuario es nuevo, crear documento en Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        final model = AuthUserModel(
          uid: uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? '',
          role: UserRole.client,
        );
        await _firestore.collection('users').doc(uid).set(model.toMap());
        return model;
      }
      return AuthUserModel.fromFirestore(doc.data()!, uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<AuthUserModel> refreshCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AuthException('No hay usuario autenticado.');
    return _fetchUserModel(user.uid);
  }

  Future<AuthUserModel> _fetchUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw const AuthException('Usuario no encontrado en la base de datos.');
    }
    return AuthUserModel.fromFirestore(doc.data()!, uid);
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intente más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error de autenticación: $code';
    }
  }
}
