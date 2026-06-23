import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';

class EarnPoints implements UseCase<int, EarnPointsParams> {
  final PointsRepository repository;
  EarnPoints(this.repository);

  @override
  Future<Either<Failure, int>> call(EarnPointsParams params) {
    return repository.earnPoints(
      userId: params.userId,
      businessId: params.businessId,
      businessName: params.businessName,
      purchaseAmount: params.purchaseAmount,
      pointsPerSol: params.pointsPerSol,
    );
  }
}

class EarnPointsParams extends Equatable {
  final String userId;
  final String businessId;
  final String businessName;
  final double purchaseAmount;
  final int pointsPerSol;

  const EarnPointsParams({
    required this.userId,
    required this.businessId,
    required this.businessName,
    required this.purchaseAmount,
    this.pointsPerSol = 1,
  });

  @override
  List<Object?> get props => [userId, businessId, purchaseAmount, pointsPerSol];
}
