import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bonvo/features/points/domain/usecases/earn_points.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {
  const ScannerInitial();
}

class ScannerLoading extends ScannerState {
  const ScannerLoading();
}

class ScannerSuccess extends ScannerState {
  final int newTotalPoints;
  final int pointsEarned;
  const ScannerSuccess(this.newTotalPoints, this.pointsEarned);
  @override
  List<Object?> get props => [newTotalPoints, pointsEarned];
}

class ScannerError extends ScannerState {
  final String message;
  const ScannerError(this.message);
  @override
  List<Object?> get props => [message];
}

class ScannerCubit extends Cubit<ScannerState> {
  final EarnPoints _earnPoints;

  ScannerCubit(this._earnPoints) : super(const ScannerInitial());

  Future<void> creditPoints({
    required String userId,
    required String businessId,
    required String businessName,
    required double purchaseAmount,
    int pointsPerSol = 1,
  }) async {
    emit(const ScannerLoading());

    final result = await _earnPoints(
      EarnPointsParams(
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        purchaseAmount: purchaseAmount,
        pointsPerSol: pointsPerSol,
      ),
    );

    result.fold(
      (failure) => emit(ScannerError(failure.message)),
      (newTotal) => emit(
          ScannerSuccess(newTotal, (purchaseAmount * pointsPerSol).floor())),
    );
  }

  void reset() => emit(const ScannerInitial());
}
