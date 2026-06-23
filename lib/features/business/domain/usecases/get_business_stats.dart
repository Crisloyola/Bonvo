import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';

class GetBusinessStats implements UseCase<BusinessStats, String> {
  final BusinessRepository repository;
  GetBusinessStats(this.repository);

  @override
  Future<Either<Failure, BusinessStats>> call(String businessId) {
    return repository.getBusinessStats(businessId);
  }
}
