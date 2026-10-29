import 'package:dartz/dartz.dart';
import 'package:bonvo/core/errors/failure.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}
