import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/features/points/data/models/transaction_model.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';

abstract class PointsRemoteDataSource {
  Future<int> earnPoints({
    required String userId,
    required String businessId,
    required String businessName,
    required double purchaseAmount,
    required int pointsPerSol,
  });

  Future<int> redeemPromotion({
    required String userId,
    required String businessId,
    required String businessName,
    required String promotionTitle,
    required String promotionId,
    required int pointsCost,
  });

  Future<List<TransactionModel>> getUserTransactions(String userId);
  Stream<int> watchUserPoints(String userId);
}

class PointsRemoteDataSourceImpl implements PointsRemoteDataSource {
  final FirebaseFirestore _firestore;

  PointsRemoteDataSourceImpl(this._firestore);

  @override
  Future<int> earnPoints({
    required String userId,
    required String businessId,
    required String businessName,
    required double purchaseAmount,
    required int pointsPerSol,
  }) async {
    final pointsEarned = (purchaseAmount * pointsPerSol).floor();
    if (pointsEarned <= 0) throw const ServerException('Monto inválido para acreditar puntos.');

    final userRef = _firestore.collection('users').doc(userId);
    final txRef = _firestore.collection('transactions').doc();

    late int newTotal;

    // Transacción atómica: registrar movimiento + actualizar puntos
    await _firestore.runTransaction((firestoreTx) async {
      final userSnap = await firestoreTx.get(userRef);
      if (!userSnap.exists) throw const ServerException('Usuario no encontrado.');

      final currentPoints = (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
      newTotal = currentPoints + pointsEarned;

      final txModel = TransactionModel(
        id: txRef.id,
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        type: TransactionType.earn,
        amount: purchaseAmount,
        points: pointsEarned,
        timestamp: DateTime.now(),
      );

      firestoreTx.set(txRef, txModel.toMap());
      firestoreTx.update(userRef, {'points': newTotal});
    });

    return newTotal;
  }

  @override
  Future<int> redeemPromotion({
    required String userId,
    required String businessId,
    required String businessName,
    required String promotionTitle,
    required String promotionId,
    required int pointsCost,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final txRef = _firestore.collection('transactions').doc();

    late int newTotal;

    await _firestore.runTransaction((firestoreTx) async {
      final userSnap = await firestoreTx.get(userRef);
      if (!userSnap.exists) throw const ServerException('Usuario no encontrado.');

      final currentPoints = (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
      if (currentPoints < pointsCost) {
        throw const ServerException('Puntos insuficientes para canjear.');
      }

      newTotal = currentPoints - pointsCost;

      final txModel = TransactionModel(
        id: txRef.id,
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        type: TransactionType.redeem,
        amount: 0,
        points: pointsCost,
        timestamp: DateTime.now(),
      );

      firestoreTx.set(txRef, txModel.toMap());
      firestoreTx.update(userRef, {
        'points': newTotal,
        'redeemedPromoIds': FieldValue.arrayUnion([promotionId]),
      });
    });

    return newTotal;
  }

  @override
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final snap = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snap.docs.map(TransactionModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<int> watchUserPoints(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) => (snap.data()?['points'] as num?)?.toInt() ?? 0);
  }
}
