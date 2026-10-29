import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';

class LoyaltyException implements Exception {
  final String message;
  const LoyaltyException(this.message);
  @override
  String toString() => message;
}

/// Programas, saldos por tienda y solicitudes (compra, canje) que el
/// negocio aprueba o rechaza.
class LoyaltyRepository {
  final FirebaseFirestore _db;
  LoyaltyRepository(this._db);

  DocumentReference<Map<String, dynamic>> _business(String id) =>
      _db.collection('businesses').doc(id);

  DocumentReference<Map<String, dynamic>> _member(String bid, String uid) =>
      _business(bid).collection('members').doc(uid);

  CollectionReference<Map<String, dynamic>> _requests(String bid) =>
      _business(bid).collection('requests');

  // ── Programas ────────────────────────────────────────────────

  Future<void> savePrograms(String businessId, LoyaltyPrograms programs) =>
      _business(businessId).update({
        'programs': programs.toMap(),
        // Se mantiene por compatibilidad con pantallas que aún lo leen
        'pointsPerSol': programs.pointsPerSol,
      });

  // ── Saldos ───────────────────────────────────────────────────

  Stream<Membership?> watchMembership(String businessId, String userId) =>
      _member(businessId, userId)
          .snapshots()
          .map((s) => s.exists ? Membership.fromDoc(s) : null);

  Stream<List<Membership>> watchMembers(String businessId) =>
      _business(businessId)
          .collection('members')
          .snapshots()
          .map((q) => q.docs.map(Membership.fromDoc).toList());

  /// Suma de puntos del cliente en todas sus tiendas.
  Stream<int> watchTotalPoints(String userId, List<String> businessIds) {
    if (businessIds.isEmpty) return Stream.value(0);
    final latest = <String, int>{};
    late final StreamController<int> controller;
    final subs = <StreamSubscription>[];
    controller = StreamController<int>(
      onListen: () {
        for (final bid in businessIds) {
          subs.add(watchMembership(bid, userId).listen((m) {
            latest[bid] = m?.points ?? 0;
            controller.add(latest.values.fold(0, (a, b) => a + b));
          }));
        }
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );
    return controller.stream;
  }

  // ── Solicitudes del cliente ──────────────────────────────────

  Stream<List<LoyaltyRequest>> watchUserRequests(
      String businessId, String userId) {
    // Sin orderBy para no requerir índice compuesto: se ordena en memoria
    return _requests(businessId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((q) => q.docs.map(LoyaltyRequest.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> requestPurchase({
    required String businessId,
    required String businessName,
    required String userId,
    required String userName,
    required int amountCents,
  }) =>
      _create(businessId, {
        'businessName': businessName,
        'userId': userId,
        'userName': userName,
        'type': RequestType.purchase.name,
        'amountCents': amountCents,
      });

  Future<void> requestReward({
    required String businessId,
    required String businessName,
    required String userId,
    required String userName,
    required String rewardId,
    required String rewardTitle,
    required int rewardPoints,
  }) =>
      _create(businessId, {
        'businessName': businessName,
        'userId': userId,
        'userName': userName,
        'type': RequestType.reward.name,
        'rewardId': rewardId,
        'rewardTitle': rewardTitle,
        'rewardPoints': rewardPoints,
      });

  Future<void> requestStampReward({
    required String businessId,
    required String businessName,
    required String userId,
    required String userName,
    required String rewardTitle,
  }) =>
      _create(businessId, {
        'businessName': businessName,
        'userId': userId,
        'userName': userName,
        'type': RequestType.stampReward.name,
        'rewardTitle': rewardTitle,
      });

  Future<void> _create(String businessId, Map<String, dynamic> data) =>
      _requests(businessId).add({
        ...data,
        'status': RequestStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ── Panel del negocio ────────────────────────────────────────

  Stream<List<LoyaltyRequest>> watchPendingRequests(String businessId) =>
      _requests(businessId)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .snapshots()
          .map((q) => q.docs.map(LoyaltyRequest.fromDoc).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  Future<void> reject(LoyaltyRequest request) =>
      _requests(request.businessId).doc(request.id).update({
        'status': RequestStatus.rejected.name,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

  /// Aprueba la solicitud y actualiza los saldos del cliente en una sola
  /// transacción, para que no se acredite dos veces ni quede a medias.
  Future<void> approve(LoyaltyRequest request) async {
    final reqRef = _requests(request.businessId).doc(request.id);
    final bizRef = _business(request.businessId);
    final memberRef = _member(request.businessId, request.userId);
    final txRef = _db.collection('transactions').doc();

    await _precheck(request, reqRef, memberRef);
    await _guard(() => _db.runTransaction((tx) async {
          final reqSnap = await tx.get(reqRef);
          final bizSnap = await tx.get(bizRef);
          final memberSnap = await tx.get(memberRef);

          if (reqSnap.data()?['status'] != RequestStatus.pending.name) {
            throw const LoyaltyException('Esta solicitud ya fue atendida.');
          }
          final biz = bizSnap.data() ?? const {};
          final programs = LoyaltyPrograms.fromMap(
            (biz['programs'] as Map?)?.cast<String, dynamic>(),
            legacyPointsPerSol: (biz['pointsPerSol'] as num?)?.toInt() ?? 1,
          );
          final m = memberSnap.exists
              ? Membership.fromDoc(memberSnap)
              : Membership(
                  businessId: request.businessId, userId: request.userId);

          final memberUpdate = <String, dynamic>{
            'userId': request.userId,
            'userName': request.userName,
          };
          final requestUpdate = <String, dynamic>{
            'status': RequestStatus.approved.name,
            'resolvedAt': FieldValue.serverTimestamp(),
          };
          final log = <String, dynamic>{
            'userId': request.userId,
            'businessId': request.businessId,
            'businessName': request.businessName,
            'requestId': request.id,
            'timestamp': Timestamp.now(),
          };

          switch (request.type) {
            case RequestType.purchase:
              final points = programs.pointsFor(request.amountCents);
              final cashback = programs.cashbackFor(request.amountCents);
              var stamps = m.stamps;
              var stampRewards = m.stampRewards;
              var earnedStamps = 0;
              if (programs.stampsEnabled) {
                earnedStamps = 1;
                stamps += 1;
                // Al completar la tarjeta se gana el regalo y se reinicia
                if (stamps >= programs.stampsRequired) {
                  stampRewards += stamps ~/ programs.stampsRequired;
                  stamps = stamps % programs.stampsRequired;
                }
              }
              memberUpdate.addAll({
                'points': m.points + points,
                'cashbackCents': m.cashbackCents + cashback,
                'stamps': stamps,
                'stampRewards': stampRewards,
                'visits': m.visits + 1,
                'lastVisit': FieldValue.serverTimestamp(),
              });
              requestUpdate.addAll({
                'earnedPoints': points,
                'earnedStamps': earnedStamps,
                'earnedCashbackCents': cashback,
              });
              log.addAll({
                'type': 'earn',
                'amount': request.amountCents / 100,
                'points': points,
                'cashbackCents': cashback,
                'stamps': earnedStamps,
              });

            case RequestType.reward:
              if (m.points < request.rewardPoints) {
                throw LoyaltyException(
                    'El cliente tiene ${m.points} pts y el regalo cuesta '
                    '${request.rewardPoints}.');
              }
              memberUpdate['points'] = m.points - request.rewardPoints;
              log.addAll({
                'type': 'redeem',
                'amount': 0,
                'points': request.rewardPoints,
                'rewardTitle': request.rewardTitle,
              });

            case RequestType.stampReward:
              if (m.stampRewards < 1) {
                throw const LoyaltyException(
                    'El cliente no tiene regalos de sellos por recibir.');
              }
              memberUpdate['stampRewards'] = m.stampRewards - 1;
              log.addAll({
                'type': 'stampReward',
                'amount': 0,
                'points': 0,
                'rewardTitle': request.rewardTitle,
              });
          }

          tx.set(memberRef, memberUpdate, SetOptions(merge: true));
          tx.update(reqRef, requestUpdate);
          tx.set(txRef, log);
        }));
  }

  /// Mismas validaciones que dentro de la transacción, pero fuera de ella
  /// para poder mostrar un mensaje claro.
  Future<void> _precheck(
    LoyaltyRequest request,
    DocumentReference<Map<String, dynamic>> reqRef,
    DocumentReference<Map<String, dynamic>> memberRef,
  ) async {
    final reqSnap = await reqRef.get();
    if (reqSnap.data()?['status'] != RequestStatus.pending.name) {
      throw const LoyaltyException('Esta solicitud ya fue atendida.');
    }
    if (request.type == RequestType.purchase) return;
    final memberSnap = await memberRef.get();
    final m = memberSnap.exists
        ? Membership.fromDoc(memberSnap)
        : Membership(businessId: request.businessId, userId: request.userId);
    if (request.type == RequestType.reward && m.points < request.rewardPoints) {
      throw LoyaltyException('El cliente tiene ${m.points} pts y el regalo '
          'cuesta ${request.rewardPoints}. Rechaza la solicitud.');
    }
    if (request.type == RequestType.stampReward && m.stampRewards < 1) {
      throw const LoyaltyException(
          'El cliente no tiene regalos de sellos por recibir.');
    }
  }

  /// Convierte errores de Firestore en un mensaje entendible.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on LoyaltyException {
      rethrow;
    } catch (_) {
      throw const LoyaltyException(
          'No se pudo completar. Revisa tu conexión e inténtalo de nuevo.');
    }
  }

  /// El negocio descuenta saldo de cashback cuando el cliente lo usa.
  Future<void> applyCashback({
    required String businessId,
    required String businessName,
    required String userId,
    required int amountCents,
  }) async {
    if (amountCents <= 0) throw const LoyaltyException('Monto inválido.');
    final memberRef = _member(businessId, userId);
    final txRef = _db.collection('transactions').doc();
    final current =
        (await memberRef.get()).data()?['cashbackCents'] as num? ?? 0;
    if (amountCents > current) {
      throw LoyaltyException(
          'El saldo de cashback es ${formatSoles(current.toInt())}.');
    }
    await _guard(() => _db.runTransaction((tx) async {
          final snap = await tx.get(memberRef);
          final balance = (snap.data()?['cashbackCents'] as num?)?.toInt() ?? 0;
          if (amountCents > balance) {
            throw LoyaltyException(
                'El saldo de cashback es ${formatSoles(balance)}.');
          }
          tx.update(memberRef, {'cashbackCents': balance - amountCents});
          tx.set(txRef, {
            'userId': userId,
            'businessId': businessId,
            'businessName': businessName,
            'type': 'cashbackUse',
            'amount': 0,
            'points': 0,
            'cashbackCents': amountCents,
            'timestamp': Timestamp.now(),
          });
        }));
  }
}
