import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    required String id,
    required String name,
    required String adminId,
    String description = '',
    int pointsPerSol = 1,
    double? latitude,
    double? longitude,
    String? bannerBase64,
  }) : super(
          id: id,
          name: name,
          adminId: adminId,
          description: description,
          pointsPerSol: pointsPerSol,
          latitude: latitude,
          longitude: longitude,
          bannerBase64: bannerBase64,
        );

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pointsPerSol: (data['pointsPerSol'] as num?)?.toInt() ?? 1,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      bannerBase64: data['bannerBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'adminId': adminId,
        'description': description,
        'pointsPerSol': pointsPerSol,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (bannerBase64 != null) 'bannerBase64': bannerBase64,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
