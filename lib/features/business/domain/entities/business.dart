import 'package:equatable/equatable.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String adminId;
  final String description;
  final int pointsPerSol;
  final double? latitude;
  final double? longitude;
  final String? bannerBase64;

  const Business({
    required this.id,
    required this.name,
    required this.adminId,
    this.description = '',
    this.pointsPerSol = 1,
    this.latitude,
    this.longitude,
    this.bannerBase64,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [id, name, adminId, pointsPerSol, latitude, longitude, bannerBase64];
}

class BusinessStats extends Equatable {
  final int totalTransactions;
  final int totalPointsIssued;
  final int uniqueClients;
  final int activePromotions;

  const BusinessStats({
    required this.totalTransactions,
    required this.totalPointsIssued,
    required this.uniqueClients,
    this.activePromotions = 0,
  });

  @override
  List<Object?> get props => [totalTransactions, totalPointsIssued, uniqueClients, activePromotions];
}

class ClientSummary extends Equatable {
  final String userId;
  final String name;
  final String email;
  final int transactionCount;
  final DateTime lastVisit;

  const ClientSummary({
    required this.userId,
    required this.name,
    required this.email,
    required this.transactionCount,
    required this.lastVisit,
  });

  @override
  List<Object?> get props => [userId, name, email, transactionCount, lastVisit];
}
