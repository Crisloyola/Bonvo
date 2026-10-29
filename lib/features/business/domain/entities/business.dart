import 'package:equatable/equatable.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String adminId;
  final String description;
  final int pointsPerSol;
  final double? latitude;
  final double? longitude;
  final String? bannerBase64;
  final String? logoBase64;
  final LoyaltyPrograms programs;

  const Business({
    required this.id,
    required this.name,
    required this.adminId,
    this.description = '',
    this.pointsPerSol = 1,
    this.latitude,
    this.longitude,
    this.bannerBase64,
    this.logoBase64,
    this.programs = const LoyaltyPrograms(),
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [id, name, adminId, pointsPerSol, latitude, longitude, bannerBase64, logoBase64, programs];
}

class BusinessStats extends Equatable {
  final int totalTransactions;
  final int totalPointsIssued;
  final int uniqueClients;
  final int activePromotions;
  final int cashbackIssuedCents;

  const BusinessStats({
    required this.totalTransactions,
    required this.totalPointsIssued,
    required this.uniqueClients,
    this.activePromotions = 0,
    this.cashbackIssuedCents = 0,
  });

  @override
  List<Object?> get props => [totalTransactions, totalPointsIssued, uniqueClients, activePromotions, cashbackIssuedCents];
}

class ClientSummary extends Equatable {
  final String userId;
  final String name;
  final String email;
  final int transactionCount;
  final DateTime lastVisit;
  final String? photoBase64;

  const ClientSummary({
    required this.userId,
    required this.name,
    required this.email,
    required this.transactionCount,
    required this.lastVisit,
    this.photoBase64,
  });

  @override
  List<Object?> get props => [userId, name, email, transactionCount, lastVisit, photoBase64];
}
