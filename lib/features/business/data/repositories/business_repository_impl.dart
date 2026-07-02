import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/business/data/datasources/business_remote_datasource.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource _remote;

  BusinessRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, Business>> createBusiness({
    required String adminId,
    required String name,
    required String description,
    required int pointsPerSol,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final business = await _remote.createBusiness(
        adminId: adminId,
        name: name,
        description: description,
        pointsPerSol: pointsPerSol,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(business);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Business>> getBusiness(String businessId) async {
    try {
      return Right(await _remote.getBusiness(businessId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusinessStats>> getBusinessStats(String businessId) async {
    try {
      return Right(await _remote.getBusinessStats(businessId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClientSummary>>> getBusinessClients(String businessId) async {
    try {
      return Right(await _remote.getBusinessClients(businessId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePointsPerSol({
    required String businessId,
    required int pointsPerSol,
  }) async {
    try {
      await _remote.updatePointsPerSol(
        businessId: businessId,
        pointsPerSol: pointsPerSol,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateBannerBase64({
    required String businessId,
    required String bannerBase64,
  }) async {
    try {
      await _remote.updateBannerBase64(businessId: businessId, bannerBase64: bannerBase64);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLogoBase64({
    required String businessId,
    required String logoBase64,
  }) async {
    try {
      await _remote.updateLogoBase64(businessId: businessId, logoBase64: logoBase64);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
