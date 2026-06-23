import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/promotions/data/datasources/promotions_datasource.dart';
import 'package:bonvo/features/promotions/data/models/promotion_model.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';

class PromotionsRepositoryImpl implements PromotionsRepository {
  final PromotionsDataSource _remote;
  PromotionsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, Unit>> createPromotion(Promotion p) async {
    try {
      final model = PromotionModel(
        id: '',
        businessId: p.businessId,
        businessName: p.businessName,
        title: p.title,
        description: p.description,
        pointsCost: p.pointsCost,
        active: p.active,
        createdAt: p.createdAt,
      );
      await _remote.createPromotion(model);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Promotion>>> getBusinessPromotions(
      String businessId) async {
    try {
      return Right(await _remote.getBusinessPromotions(businessId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Promotion>>> getClientPromotions(
      List<String> businessIds) async {
    try {
      return Right(await _remote.getClientPromotions(businessIds));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> togglePromotion(
      String businessId, String promoId, bool active) async {
    try {
      await _remote.togglePromotion(businessId, promoId, active);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePromotion(
      String businessId, String promoId) async {
    try {
      await _remote.deletePromotion(businessId, promoId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
