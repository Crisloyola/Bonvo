import 'package:equatable/equatable.dart';

class Promotion extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String title;
  final String description;
  final int pointsCost;
  final bool active;
  final DateTime createdAt;

  /// Foto del regalo/promoción (JPEG comprimido en base64).
  final String? imageBase64;

  const Promotion({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.active,
    required this.createdAt,
    this.imageBase64,
  });

  bool get isFree => pointsCost == 0;

  @override
  List<Object?> get props => [id, businessId, title, pointsCost, active];
}
