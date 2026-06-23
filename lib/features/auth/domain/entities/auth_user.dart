import 'package:equatable/equatable.dart';

enum UserRole { client, businessAdmin, employee }

class AuthUser extends Equatable {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final int points;
  final List<String> businessIds;
  final String? photoBase64;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.points = 0,
    this.businessIds = const [],
    this.photoBase64,
  });

  @override
  List<Object?> get props => [uid, email, name, role, points, businessIds, photoBase64];
}
