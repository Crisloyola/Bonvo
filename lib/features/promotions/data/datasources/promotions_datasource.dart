import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/features/promotions/data/models/promotion_model.dart';

abstract class PromotionsDataSource {
  Future<void> createPromotion(PromotionModel promotion);
  Future<List<PromotionModel>> getBusinessPromotions(String businessId);
  Future<List<PromotionModel>> getClientPromotions(List<String> businessIds);
  Future<void> togglePromotion(
      String businessId, String promotionId, bool active);
  Future<void> deletePromotion(String businessId, String promotionId);
}

class PromotionsDataSourceImpl implements PromotionsDataSource {
  final FirebaseFirestore _firestore;
  PromotionsDataSourceImpl(this._firestore);

  CollectionReference _promos(String businessId) => _firestore
      .collection('businesses')
      .doc(businessId)
      .collection('promotions');

  @override
  Future<void> createPromotion(PromotionModel promotion) async {
    await _promos(promotion.businessId).add(promotion.toFirestore());
  }

  @override
  Future<List<PromotionModel>> getBusinessPromotions(
      String businessId) async {
    final snap = await _promos(businessId).get();
    final list = snap.docs.map(PromotionModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<PromotionModel>> getClientPromotions(
      List<String> businessIds) async {
    if (businessIds.isEmpty) return [];
    final results = <PromotionModel>[];
    for (final id in businessIds) {
      // Sin orderBy para evitar índice compuesto — ordenamos en Dart
      final snap = await _promos(id)
          .where('active', isEqualTo: true)
          .get();
      results.addAll(snap.docs.map(PromotionModel.fromFirestore));
    }
    // Ordena por fecha descendente en memoria
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<void> togglePromotion(
      String businessId, String promotionId, bool active) async {
    await _promos(businessId).doc(promotionId).update({'active': active});
  }

  @override
  Future<void> deletePromotion(String businessId, String promotionId) async {
    await _promos(businessId).doc(promotionId).delete();
  }
}
