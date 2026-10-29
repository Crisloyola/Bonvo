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
      final memberRef = _firestore
          .collection('businesses')
          .doc(params.businessId)
          .collection('members')
          .doc(params.userId);
      // Si ya era miembro no se toca su documento: guarda sus saldos
      final alreadyMember = (await memberRef.get()).exists;

      final batch = _firestore.batch();

      // 1. Agrega el negocio al perfil del cliente
      batch.update(
        _firestore.collection('users').doc(params.userId),
        {'businessIds': FieldValue.arrayUnion([params.businessId])},
      );

      // 2. Crea el doc de membresía (saldos por tienda, empiezan en 0)
      if (!alreadyMember) {
        batch.set(memberRef, {
          'userId': params.userId,
          'userName': params.userName,
          'enrolledAt': FieldValue.serverTimestamp(),
        });
      }

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
  final String userName;
  const EnrollParams({
    required this.userId,
    required this.businessId,
    this.userName = '',
  });
  @override
  List<Object?> get props => [userId, businessId];
}
