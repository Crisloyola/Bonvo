import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';

class GetUserTransactions implements UseCase<List<Transaction>, String> {
  final PointsRepository repository;
  GetUserTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(String userId) {
    return repository.getUserTransactions(userId);
  }
}
