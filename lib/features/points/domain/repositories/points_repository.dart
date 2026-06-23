import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';

abstract class PointsRepository {
  /// Acredita puntos al usuario y registra la transacción.
  /// Retorna los puntos totales del usuario tras la operación.
  Future<Either<Failure, int>> earnPoints({
    required String userId,
    required String businessId,
    required String businessName,
    required double purchaseAmount,
    required int pointsPerSol, // regla: N puntos por cada S/1
  });

  /// Canjea una promoción descontando puntos atómicamente.
  Future<Either<Failure, int>> redeemPromotion({
    required String userId,
    required String businessId,
    required String businessName,
    required String promotionTitle,
    required int pointsCost,
  });

  /// Obtiene el historial de transacciones del usuario.
  Future<Either<Failure, List<Transaction>>> getUserTransactions(String userId);

  /// Stream de puntos del usuario en tiempo real.
  Stream<int> watchUserPoints(String userId);
}
