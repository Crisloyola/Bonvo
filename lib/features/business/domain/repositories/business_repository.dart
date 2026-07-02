import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';

abstract class BusinessRepository {
  Future<Either<Failure, Business>> createBusiness({
    required String adminId,
    required String name,
    required String description,
    required int pointsPerSol,
    double? latitude,
    double? longitude,
  });

  Future<Either<Failure, Business>> getBusiness(String businessId);

  Future<Either<Failure, BusinessStats>> getBusinessStats(String businessId);

  Future<Either<Failure, List<ClientSummary>>> getBusinessClients(String businessId);

  Future<Either<Failure, Unit>> updatePointsPerSol({
    required String businessId,
    required int pointsPerSol,
  });

  Future<Either<Failure, Unit>> updateBannerBase64({
    required String businessId,
    required String bannerBase64,
  });

  Future<Either<Failure, Unit>> updateLogoBase64({
    required String businessId,
    required String logoBase64,
  });
}
