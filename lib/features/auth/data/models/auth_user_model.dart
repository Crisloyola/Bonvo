import 'package:bonvo/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.points,
    super.businessIds,
    super.photoBase64,
  });

  factory AuthUserModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return AuthUserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.client,
      ),
      points: (data['points'] as num?)?.toInt() ?? 0,
      businessIds: List<String>.from(data['businessIds'] as List? ?? []),
      photoBase64: data['photoBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.name,
        'points': points,
        'businessIds': businessIds,
        if (photoBase64 != null) 'photoBase64': photoBase64,
        'createdAt': DateTime.now().toIso8601String(),
      };
}
