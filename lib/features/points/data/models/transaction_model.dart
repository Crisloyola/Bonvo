import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:bonvo/features/points/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.businessId,
    required super.businessName,
    required super.type,
    required super.amount,
    required super.points,
    required super.timestamp,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      businessId: data['businessId'] as String,
      businessName: data['businessName'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => TransactionType.earn,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
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
