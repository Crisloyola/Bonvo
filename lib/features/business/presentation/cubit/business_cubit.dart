import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/domain/usecases/create_business.dart';

// States
abstract class BusinessState extends Equatable {
  const BusinessState();
  @override
  List<Object?> get props => [];
}

class BusinessInitial extends BusinessState {
  const BusinessInitial();
}

class BusinessLoading extends BusinessState {
  const BusinessLoading();
}

class BusinessLoaded extends BusinessState {
  final Business business;
  final BusinessStats stats;
  final List<ClientSummary> clients;
  const BusinessLoaded({
    required this.business,
    required this.stats,
    required this.clients,
  });
  @override
  List<Object?> get props => [business, stats, clients];
}

class BusinessCreating extends BusinessState {
  const BusinessCreating();
}

class BusinessCreated extends BusinessState {
  final Business business;
  const BusinessCreated(this.business);
  @override
  List<Object?> get props => [business];
}

class BusinessError extends BusinessState {
  final String message;
  const BusinessError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class BusinessCubit extends Cubit<BusinessState> {
  final BusinessRepository _repository;
  final CreateBusiness _createBusiness;

  BusinessCubit({
    required BusinessRepository repository,
    required CreateBusiness createBusiness,
  })  : _repository = repository,
        _createBusiness = createBusiness,
        super(const BusinessInitial());

  Future<void> loadBusiness(String businessId) async {
    emit(const BusinessLoading());

    final businessResult = await _repository.getBusiness(businessId);
    businessResult.fold(
      (failure) => emit(BusinessError(failure.message)),
      (business) async {
        final statsResult = await _repository.getBusinessStats(businessId);
        final clientsResult = await _repository.getBusinessClients(businessId);

        final stats = statsResult.fold(
          (_) => const BusinessStats(
              totalTransactions: 0, totalPointsIssued: 0, uniqueClients: 0),
          (s) => s,
        );
        final clients = clientsResult.fold((_) => <ClientSummary>[], (c) => c);

        emit(BusinessLoaded(business: business, stats: stats, clients: clients));
      },
    );
  }

  Future<void> createBusiness({
    required String adminId,
    required String name,
    required String description,
    required int pointsPerSol,
    double? latitude,
    double? longitude,
  }) async {
    emit(const BusinessCreating());

    final result = await _createBusiness(
      CreateBusinessParams(
        adminId: adminId,
        name: name,
        description: description,
        pointsPerSol: pointsPerSol,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    result.fold(
      (failure) => emit(BusinessError(failure.message)),
      (business) => emit(BusinessCreated(business)),
    );
  }

  void reset() => emit(const BusinessInitial());
}
