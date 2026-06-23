import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/features/business/data/models/business_model.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';

abstract class BusinessRemoteDataSource {
  Future<BusinessModel> createBusiness({
    required String adminId,
    required String name,
    required String description,
    required int pointsPerSol,
    double? latitude,
    double? longitude,
  });

  Future<BusinessModel> getBusiness(String businessId);
  Future<BusinessStats> getBusinessStats(String businessId);
  Future<List<ClientSummary>> getBusinessClients(String businessId);
  Future<void> updatePointsPerSol({required String businessId, required int pointsPerSol});
  Future<void> updateBannerBase64({required String businessId, required String bannerBase64});
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final FirebaseFirestore _firestore;

  BusinessRemoteDataSourceImpl(this._firestore);

  @override
  Future<BusinessModel> createBusiness({
    required String adminId,
    required String name,
    required String description,
    required int pointsPerSol,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final businessRef = _firestore.collection('businesses').doc();
      final model = BusinessModel(
        id: businessRef.id,
        name: name,
        adminId: adminId,
        description: description,
        pointsPerSol: pointsPerSol,
        latitude: latitude,
        longitude: longitude,
      );

      final batch = _firestore.batch();
      batch.set(businessRef, model.toMap());
      // Agrega el businessId al array del admin
      batch.update(
        _firestore.collection('users').doc(adminId),
        {'businessIds': FieldValue.arrayUnion([businessRef.id])},
      );
      await batch.commit();

      return model;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BusinessModel> getBusiness(String businessId) async {
    try {
      final doc = await _firestore.collection('businesses').doc(businessId).get();
      if (!doc.exists) throw const ServerException('Negocio no encontrado.');
      return BusinessModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BusinessStats> getBusinessStats(String businessId) async {
    try {
      // Cuenta usuarios que tienen este negocio en su array businessIds
      final enrolledSnap = await _firestore
          .collection('users')
          .where('businessIds', arrayContains: businessId)
          .get();

      final txSnap = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: businessId)
          .get();

      int totalPoints = 0;
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final pts = (data['points'] as num?)?.toInt() ?? 0;
        if (data['type'] == 'earn') totalPoints += pts;
      }

      final promoSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('promotions')
          .get();
      final activePromos =
          promoSnap.docs.where((d) => d.data()['active'] == true).length;

      return BusinessStats(
        totalTransactions: txSnap.docs.length,
        totalPointsIssued: totalPoints,
        uniqueClients: enrolledSnap.docs.length,
        activePromotions: activePromos,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ClientSummary>> getBusinessClients(String businessId) async {
    try {
      // Busca usuarios inscritos via businessIds array
      final enrolledSnap = await _firestore
          .collection('users')
          .where('businessIds', arrayContains: businessId)
          .get();

      if (enrolledSnap.docs.isEmpty) return [];

      final txSnap = await _firestore
          .collection('transactions')
          .where('businessId', isEqualTo: businessId)
          .get();

      final Map<String, int> txCount = {};
      final Map<String, DateTime> lastVisit = {};
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final uid = data['userId'] as String?;
        if (uid == null) continue;
        txCount[uid] = (txCount[uid] ?? 0) + 1;
        final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (!lastVisit.containsKey(uid) || ts.isAfter(lastVisit[uid]!)) {
          lastVisit[uid] = ts;
        }
      }

      final summaries = <ClientSummary>[];
      for (final doc in enrolledSnap.docs) {
        final uid = doc.id;
        final data = doc.data();
        summaries.add(ClientSummary(
          userId: uid,
          name: data['name'] as String? ?? 'Sin nombre',
          email: data['email'] as String? ?? '',
          transactionCount: txCount[uid] ?? 0,
          lastVisit: lastVisit[uid] ?? DateTime.now(),
        ));
      }

      summaries.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
      return summaries;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updatePointsPerSol({
    required String businessId,
    required int pointsPerSol,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .update({'pointsPerSol': pointsPerSol});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateBannerBase64({
    required String businessId,
    required String bannerBase64,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .update({'bannerBase64': bannerBase64});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
