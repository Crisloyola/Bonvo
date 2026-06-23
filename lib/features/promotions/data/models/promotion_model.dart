import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';

class PromotionModel extends Promotion {
  const PromotionModel({
    required super.id,
    required super.businessId,
    required super.businessName,
    required super.title,
    required super.description,
    required super.pointsCost,
    required super.active,
    required super.createdAt,
  });

  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotionModel(
      id: doc.id,
      businessId: data['businessId'] as String? ?? '',
      businessName: data['businessName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pointsCost: (data['pointsCost'] as num?)?.toInt() ?? 0,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'businessId': businessId,
        'businessName': businessName,
        'title': title,
        'description': description,
        'pointsCost': pointsCost,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
