import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Programa al que el cliente elige sumar una compra.
enum LoyaltyProgram {
  stamps('Sello'),
  cashback('Cashback'),
  points('Puntos');

  final String label;
  const LoyaltyProgram(this.label);
}

/// Lo que gana el cliente con una compra aprobada.
class Earning {
  final int points;
  final int cashbackCents;
  final int stamps;
  const Earning({this.points = 0, this.cashbackCents = 0, this.stamps = 0});

  /// "+10 pts · +S/ 1.50 cashback · +1 sello"
  String describe() => [
        if (points > 0) '+$points pts',
        if (cashbackCents > 0) '+${formatSoles(cashbackCents)} cashback',
        if (stamps > 0) '+$stamps sello',
      ].join(' · ');
}

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

  // Puntos: [pointsPerSol] puntos por cada S/ [pointsEverySoles] de compra
  // (ej.: 2 pts por cada S/ 100). El nombre pointsPerSol es heredado.
  final bool pointsEnabled;
  final int pointsPerSol;
  final int pointsEverySoles;

  const LoyaltyPrograms({
    this.stampsEnabled = false,
    this.stampsRequired = 10,
    this.stampReward = '',
    this.cashbackEnabled = false,
    this.cashbackPercent = 2,
    this.pointsEnabled = true,
    this.pointsPerSol = 1,
    this.pointsEverySoles = 1,
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
      pointsEverySoles: (points['everySoles'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'stamps': {
          'enabled': stampsEnabled,
          'required': stampsRequired,
          'reward': stampReward,
        },
        'cashback': {'enabled': cashbackEnabled, 'percent': cashbackPercent},
        'points': {
          'enabled': pointsEnabled,
          'perSol': pointsPerSol,
          'everySoles': pointsEverySoles,
        },
      };

  bool get anyEnabled => stampsEnabled || cashbackEnabled || pointsEnabled;

  /// Puntos y cashback se calculan sobre el monto; los sellos no lo necesitan.
  bool get needsAmount => cashbackEnabled || pointsEnabled;

  /// Solo cuentan los tramos completos: con 2 pts por cada S/ 100,
  /// una compra de S/ 250 da 4 pts.
  int pointsFor(int amountCents) => pointsEnabled
      ? (amountCents ~/ (pointsEverySoles * 100)) * pointsPerSol
      : 0;

  /// "2 pts por cada S/ 100" · "1 pt por cada S/ 1"
  String get pointsRule =>
      '$pointsPerSol pt${pointsPerSol == 1 ? '' : 's'} por cada S/ $pointsEverySoles';

  int cashbackFor(int amountCents) =>
      cashbackEnabled ? (amountCents * cashbackPercent / 100).round() : 0;

  /// Programas activos, en el orden en que se le ofrecen al cliente.
  List<LoyaltyProgram> get enabledPrograms => [
        if (stampsEnabled) LoyaltyProgram.stamps,
        if (cashbackEnabled) LoyaltyProgram.cashback,
        if (pointsEnabled) LoyaltyProgram.points,
      ];

  /// Lo que gana una compra. [only] es el programa que eligió el cliente;
  /// null (solicitudes anteriores a la elección) suma todos los activos.
  Earning earnFor(int amountCents, {LoyaltyProgram? only}) {
    bool uses(LoyaltyProgram p) => only == null || only == p;
    return Earning(
      points: uses(LoyaltyProgram.points) ? pointsFor(amountCents) : 0,
      cashbackCents:
          uses(LoyaltyProgram.cashback) ? cashbackFor(amountCents) : 0,
      stamps: uses(LoyaltyProgram.stamps) && stampsEnabled ? 1 : 0,
    );
  }

  /// Descripción corta de cada programa para mostrar al elegir.
  String describeProgram(LoyaltyProgram p) => switch (p) {
        LoyaltyProgram.stamps => stampReward.isEmpty
            ? '1 sello por visita · $stampsRequired para tu regalo'
            : '1 sello por visita · $stampsRequired → $stampReward',
        LoyaltyProgram.cashback =>
          '${cashbackPercent == cashbackPercent.roundToDouble() ? cashbackPercent.toInt() : cashbackPercent}% de tu compra como saldo',
        LoyaltyProgram.points => pointsRule,
      };

  LoyaltyPrograms copyWith({
    bool? stampsEnabled,
    int? stampsRequired,
    String? stampReward,
    bool? cashbackEnabled,
    double? cashbackPercent,
    bool? pointsEnabled,
    int? pointsPerSol,
    int? pointsEverySoles,
  }) =>
      LoyaltyPrograms(
        stampsEnabled: stampsEnabled ?? this.stampsEnabled,
        stampsRequired: stampsRequired ?? this.stampsRequired,
        stampReward: stampReward ?? this.stampReward,
        cashbackEnabled: cashbackEnabled ?? this.cashbackEnabled,
        cashbackPercent: cashbackPercent ?? this.cashbackPercent,
        pointsEnabled: pointsEnabled ?? this.pointsEnabled,
        pointsPerSol: pointsPerSol ?? this.pointsPerSol,
        pointsEverySoles: pointsEverySoles ?? this.pointsEverySoles,
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
        pointsEverySoles,
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

  /// Programa elegido por el cliente (null en solicitudes antiguas).
  final LoyaltyProgram? program;

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
    this.program,
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
      program: LoyaltyProgram.values
          .where((p) => p.name == d['program'])
          .firstOrNull,
    );
  }

  bool get isPending => status == RequestStatus.pending;

  @override
  List<Object?> get props => [id, businessId, status, earnedPoints];
}

/// Formato de dinero: 12345 → "S/ 123.45"
String formatSoles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';
