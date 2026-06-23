import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bonvo/features/points/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required String id,
    required String userId,
    required String businessId,
    required String businessName,
    required TransactionType type,
    required double amount,
    required int points,
    required DateTime timestamp,
  }) : super(
          id: id,
          userId: userId,
          businessId: businessId,
          businessName: businessName,
          type: type,
          amount: amount,
          points: points,
          timestamp: timestamp,
        );

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      businessId: data['businessId'] as String,
      businessName: data['businessName'] as String? ?? '',
      type: data['type'] == 'redeem' ? TransactionType.redeem : TransactionType.earn,
      amount: (data['amount'] as num).toDouble(),
      points: (data['points'] as num).toInt(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'businessId': businessId,
        'businessName': businessName,
        'type': type.name,
        'amount': amount,
        'points': points,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
