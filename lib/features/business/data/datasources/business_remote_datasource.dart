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
  Future<void> updateLogoBase64({required String businessId, required String logoBase64});
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final FirebaseFirestore _firestore;

  BusinessRemoteDataSourceImpl(this._firestore);

  /// El dueño y los empleados tienen el negocio en businessIds, pero no
  /// cuentan como clientes.
  static bool _isCustomer(Map<String, dynamic> user) =>
      user['role'] != 'businessAdmin' && user['role'] != 'employee';

  /// Consultas en curso, para que stats y clientes (que se piden a la vez)
  /// compartan la misma descarga en vez de repetirla.
  final Map<String, Future<QuerySnapshot<Map<String, dynamic>>>> _inFlight =
      {};

  Future<QuerySnapshot<Map<String, dynamic>>> _shared(
    String key,
    Query<Map<String, dynamic>> query,
  ) {
    // Ojo: el callback de whenComplete no debe devolver el Future que se
    // quita del mapa (remove lo devuelve); si lo hace, el Future se espera a
    // sí mismo y nunca termina.
    return _inFlight.putIfAbsent(
      key,
      () => query.get().whenComplete(() {
        _inFlight.remove(key);
      }),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _enrolledUsers(
          String businessId) =>
      _shared(
        'users:$businessId',
        _firestore
            .collection('users')
            .where('businessIds', arrayContains: businessId),
      );

  Future<QuerySnapshot<Map<String, dynamic>>> _businessTransactions(
          String businessId) =>
      _shared(
        'tx:$businessId',
        _firestore
            .collection('transactions')
            .where('businessId', isEqualTo: businessId),
      );

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
      // Usuarios inscritos, transacciones y promociones en paralelo
      final enrolledFuture = _enrolledUsers(businessId);
      final txFuture = _businessTransactions(businessId);
      final promoFuture = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('promotions')
          .get();

      final enrolledSnap = await enrolledFuture;
      final txSnap = await txFuture;
      final promoSnap = await promoFuture;

      int totalPoints = 0;
      int cashbackCents = 0;
      for (final doc in txSnap.docs) {
        final data = doc.data();
        if (data['type'] != 'earn') continue;
        totalPoints += (data['points'] as num?)?.toInt() ?? 0;
        cashbackCents += (data['cashbackCents'] as num?)?.toInt() ?? 0;
      }

      final activePromos =
          promoSnap.docs.where((d) => d.data()['active'] == true).length;

      return BusinessStats(
        totalTransactions: txSnap.docs.length,
        totalPointsIssued: totalPoints,
        uniqueClients:
            enrolledSnap.docs.where((d) => _isCustomer(d.data())).length,
        activePromotions: activePromos,
        cashbackIssuedCents: cashbackCents,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ClientSummary>> getBusinessClients(String businessId) async {
    try {
      // Usuarios inscritos (via businessIds) y transacciones en paralelo
      final enrolledFuture = _enrolledUsers(businessId);
      final txFuture = _businessTransactions(businessId);

      final enrolledSnap = await enrolledFuture;
      if (enrolledSnap.docs.isEmpty) return [];

      final txSnap = await txFuture;

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
      for (final doc in enrolledSnap.docs.where((d) => _isCustomer(d.data()))) {
        final uid = doc.id;
        final data = doc.data();
        summaries.add(ClientSummary(
          userId: uid,
          name: data['name'] as String? ?? 'Sin nombre',
          email: data['email'] as String? ?? '',
          transactionCount: txCount[uid] ?? 0,
          lastVisit: lastVisit[uid] ?? DateTime.now(),
          photoBase64: data['photoBase64'] as String?,
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

  @override
  Future<void> updateLogoBase64({
    required String businessId,
    required String logoBase64,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .update({'logoBase64': logoBase64});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
