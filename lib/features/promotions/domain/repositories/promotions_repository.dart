import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';

abstract class PromotionsRepository {
  Future<Either<Failure, Unit>> createPromotion(Promotion promotion);
  Future<Either<Failure, List<Promotion>>> getBusinessPromotions(
      String businessId);
  Future<Either<Failure, List<Promotion>>> getClientPromotions(
      List<String> businessIds);
  Future<Either<Failure, Unit>> togglePromotion(
      String businessId, String promoId, bool active);
  Future<Either<Failure, Unit>> deletePromotion(
      String businessId, String promoId);
}
