import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Programas de fidelización que el negocio activa desde su panel.
/// Puede combinar los tres. Se guarda en businesses/{id}.programs.
class LoyaltyPrograms extends Equatable {
  // Tarjeta de sellos: cada visita aprobada suma un sello
  final bool stampsEnabled;
  final int stampsRequired;
  final String stampReward;

  // Cashback: % de la compra que vuelve como saldo en esa tienda
  final bool cashbackEnabled;
  final double cashbackPercent;

  // Puntos: por cada S/ 1 de compra
  final bool pointsEnabled;
  final int pointsPerSol;

  const LoyaltyPrograms({
    this.stampsEnabled = false,
    this.stampsRequired = 10,
    this.stampReward = '',
    this.cashbackEnabled = false,
    this.cashbackPercent = 2,
    this.pointsEnabled = true,
    this.pointsPerSol = 1,
  });

  /// Negocios creados antes de los programas solo tenían `pointsPerSol`.
  factory LoyaltyPrograms.fromMap(Map<String, dynamic>? m,
      {int legacyPointsPerSol = 1}) {
    if (m == null) return LoyaltyPrograms(pointsPerSol: legacyPointsPerSol);
    Map<String, dynamic> sub(String k) =>
        (m[k] as Map?)?.cast<String, dynamic>() ?? const {};
    final stamps = sub('stamps');
    final cashback = sub('cashback');
    final points = sub('points');
    return LoyaltyPrograms(
      stampsEnabled: stamps['enabled'] as bool? ?? false,
      stampsRequired: (stamps['required'] as num?)?.toInt() ?? 10,
      stampReward: stamps['reward'] as String? ?? '',
      cashbackEnabled: cashback['enabled'] as bool? ?? false,
      cashbackPercent: (cashback['percent'] as num?)?.toDouble() ?? 2,
      pointsEnabled: points['enabled'] as bool? ?? false,
      pointsPerSol: (points['perSol'] as num?)?.toInt() ?? legacyPointsPerSol,
    );
  }

  Map<String, dynamic> toMap() => {
        'stamps': {
          'enabled': stampsEnabled,
          'required': stampsRequired,
          'reward': stampReward,
        },
        'cashback': {'enabled': cashbackEnabled, 'percent': cashbackPercent},
        'points': {'enabled': pointsEnabled, 'perSol': pointsPerSol},
      };

  bool get anyEnabled => stampsEnabled || cashbackEnabled || pointsEnabled;

  /// Puntos y cashback se calculan sobre el monto; los sellos no lo necesitan.
  bool get needsAmount => cashbackEnabled || pointsEnabled;

  int pointsFor(int amountCents) =>
      pointsEnabled ? (amountCents / 100 * pointsPerSol).floor() : 0;

  int cashbackFor(int amountCents) =>
      cashbackEnabled ? (amountCents * cashbackPercent / 100).round() : 0;

  LoyaltyPrograms copyWith({
    bool? stampsEnabled,
    int? stampsRequired,
    String? stampReward,
    bool? cashbackEnabled,
    double? cashbackPercent,
    bool? pointsEnabled,
    int? pointsPerSol,
  }) =>
      LoyaltyPrograms(
        stampsEnabled: stampsEnabled ?? this.stampsEnabled,
        stampsRequired: stampsRequired ?? this.stampsRequired,
        stampReward: stampReward ?? this.stampReward,
        cashbackEnabled: cashbackEnabled ?? this.cashbackEnabled,
        cashbackPercent: cashbackPercent ?? this.cashbackPercent,
        pointsEnabled: pointsEnabled ?? this.pointsEnabled,
        pointsPerSol: pointsPerSol ?? this.pointsPerSol,
      );

  @override
  List<Object?> get props => [
        stampsEnabled,
        stampsRequired,
        stampReward,
        cashbackEnabled,
        cashbackPercent,
        pointsEnabled,
        pointsPerSol,
      ];
}

/// Saldos de un cliente en UNA tienda (businesses/{id}/members/{uid}).
class Membership extends Equatable {
  final String businessId;
  final String userId;
  final String userName;
  final int points;
  final int stamps;

  /// Regalos de la tarjeta de sellos ganados y aún no entregados.
  final int stampRewards;
  final int cashbackCents;
  final int visits;
  final DateTime? lastVisit;

  const Membership({
    required this.businessId,
    required this.userId,
    this.userName = '',
    this.points = 0,
    this.stamps = 0,
    this.stampRewards = 0,
    this.cashbackCents = 0,
    this.visits = 0,
    this.lastVisit,
  });

  factory Membership.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Membership(
      businessId: doc.reference.parent.parent!.id,
      userId: doc.id,
      userName: d['userName'] as String? ?? '',
      points: (d['points'] as num?)?.toInt() ?? 0,
      stamps: (d['stamps'] as num?)?.toInt() ?? 0,
      stampRewards: (d['stampRewards'] as num?)?.toInt() ?? 0,
      cashbackCents: (d['cashbackCents'] as num?)?.toInt() ?? 0,
      visits: (d['visits'] as num?)?.toInt() ?? 0,
      lastVisit: (d['lastVisit'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        businessId,
        userId,
        points,
        stamps,
        stampRewards,
        cashbackCents,
        visits,
        lastVisit,
      ];
}

enum RequestType {
  /// Compra o visita: suma puntos, cashback y/o un sello.
  purchase,

  /// Canje de un regalo del catálogo por puntos.
  reward,

  /// Canje del regalo de la tarjeta de sellos.
  stampReward,
}

enum RequestStatus { pending, approved, rejected }

/// Solicitud que el cliente envía y el negocio aprueba o rechaza
/// (businesses/{id}/requests/{rid}).
class LoyaltyRequest extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String userId;
  final String userName;
  final RequestType type;
  final RequestStatus status;
  final int amountCents;
  final String rewardId;
  final String rewardTitle;
  final int rewardPoints;
  final DateTime createdAt;
  final int earnedPoints;
  final int earnedStamps;
  final int earnedCashbackCents;

  const LoyaltyRequest({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.createdAt,
    this.amountCents = 0,
    this.rewardId = '',
    this.rewardTitle = '',
    this.rewardPoints = 0,
    this.earnedPoints = 0,
    this.earnedStamps = 0,
    this.earnedCashbackCents = 0,
  });

  factory LoyaltyRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return LoyaltyRequest(
      id: doc.id,
      businessId: doc.reference.parent.parent!.id,
      businessName: d['businessName'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      type: RequestType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => RequestType.purchase,
      ),
      status: RequestStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => RequestStatus.pending,
      ),
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      rewardId: d['rewardId'] as String? ?? '',
      rewardTitle: d['rewardTitle'] as String? ?? '',
      rewardPoints: (d['rewardPoints'] as num?)?.toInt() ?? 0,
      // serverTimestamp llega nulo en el snapshot local antes de confirmarse
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      earnedPoints: (d['earnedPoints'] as num?)?.toInt() ?? 0,
      earnedStamps: (d['earnedStamps'] as num?)?.toInt() ?? 0,
      earnedCashbackCents: (d['earnedCashbackCents'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isPending => status == RequestStatus.pending;

  @override
  List<Object?> get props => [id, businessId, status, earnedPoints];
}

/// Formato de dinero: 12345 → "S/ 123.45"
String formatSoles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';
