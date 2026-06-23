import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';

class CreateBusiness implements UseCase<Business, CreateBusinessParams> {
  final BusinessRepository repository;
  CreateBusiness(this.repository);

  @override
  Future<Either<Failure, Business>> call(CreateBusinessParams params) {
    return repository.createBusiness(
      adminId: params.adminId,
      name: params.name,
      description: params.description,
      pointsPerSol: params.pointsPerSol,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class CreateBusinessParams extends Equatable {
  final String adminId;
  final String name;
  final String description;
  final int pointsPerSol;
  final double? latitude;
  final double? longitude;

  const CreateBusinessParams({
    required this.adminId,
    required this.name,
    this.description = '',
    this.pointsPerSol = 1,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [adminId, name, description, pointsPerSol, latitude, longitude];
}
