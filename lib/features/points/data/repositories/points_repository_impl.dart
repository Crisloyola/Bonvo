import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/points/data/datasources/points_remote_datasource.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  final PointsRemoteDataSource _remote;

  PointsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, int>> earnPoints({
    required String userId,
    required String businessId,
    required String businessName,
    required double purchaseAmount,
    required int pointsPerSol,
  }) async {
    try {
      final total = await _remote.earnPoints(
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        purchaseAmount: purchaseAmount,
        pointsPerSol: pointsPerSol,
      );
      return Right(total);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> redeemPromotion({
    required String userId,
    required String businessId,
    required String businessName,
    required String promotionTitle,
    required int pointsCost,
  }) async {
    try {
      final total = await _remote.redeemPromotion(
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        promotionTitle: promotionTitle,
        pointsCost: pointsCost,
      );
      return Right(total);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getUserTransactions(String userId) async {
    try {
      final txs = await _remote.getUserTransactions(userId);
      return Right(txs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<int> watchUserPoints(String userId) => _remote.watchUserPoints(userId);
}
