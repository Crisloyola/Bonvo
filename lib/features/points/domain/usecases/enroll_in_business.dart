import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:bonvo/core/errors/exceptions.dart';
import 'package:bonvo/core/errors/failure.dart';
import 'package:bonvo/core/usecases/usecase.dart';

/// Inscribe al cliente en el programa de fidelización de una tienda.
class EnrollInBusiness implements UseCase<Unit, EnrollParams> {
  final FirebaseFirestore _firestore;
  EnrollInBusiness(this._firestore);

  @override
  Future<Either<Failure, Unit>> call(EnrollParams params) async {
    try {
      final batch = _firestore.batch();

      // 1. Agrega el negocio al perfil del cliente
      batch.update(
        _firestore.collection('users').doc(params.userId),
        {'businessIds': FieldValue.arrayUnion([params.businessId])},
      );

      // 2. Crea o actualiza el doc de membresía en la subcolección del negocio
      batch.set(
        _firestore
            .collection('businesses')
            .doc(params.businessId)
            .collection('members')
            .doc(params.userId),
        {
          'userId': params.userId,
          'enrolledAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

class EnrollParams extends Equatable {
  final String userId;
  final String businessId;
  const EnrollParams({required this.userId, required this.businessId});
  @override
  List<Object?> get props => [userId, businessId];
}
