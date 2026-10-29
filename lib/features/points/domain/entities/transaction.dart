import 'package:equatable/equatable.dart';

enum TransactionType {
  earn,
  redeem,

  /// Entrega del regalo de la tarjeta de sellos
  stampReward,

  /// El negocio descontó saldo de cashback
  cashbackUse,
}

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String businessId;
  final String businessName;
  final TransactionType type;
  final double amount;   // monto de compra en S/
  final int points;      // puntos acreditados o canjeados
  final DateTime timestamp;

  const Transaction({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.businessName,
    required this.type,
    required this.amount,
    required this.points,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userId, businessId, type, amount, points, timestamp];
}
