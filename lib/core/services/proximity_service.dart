import 'dart:async';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';

/// Monitorea la posición del cliente y envía una notificación local
/// cuando está a menos de [radiusMeters] de una tienda inscrita.
class ProximityService {
  static const double radiusMeters = 300.0;
  static const int _notifId = 1001;

  final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<Position>? _positionSub;
  final Set<String> _alreadyNotified = {};

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(
      const InitializationSettings(android: android),
    );

    // Solicitar permiso de notificaciones (Android 13+)
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Inicia el monitoreo con la lista de negocios que tienen ubicación.
  void startMonitoring(List<Business> businesses) {
    final withLocation = businesses.where((b) => b.hasLocation).toList();
    if (withLocation.isEmpty) return;

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50, // actualiza cada 50m de movimiento
      ),
    ).listen((pos) => _checkProximity(pos, withLocation));
  }

  void stopMonitoring() {
    _positionSub?.cancel();
    _positionSub = null;
    _alreadyNotified.clear();
  }

  void _checkProximity(Position pos, List<Business> businesses) {
    for (final biz in businesses) {
      final dist = _distanceMeters(
        pos.latitude,
        pos.longitude,
        biz.latitude!,
        biz.longitude!,
      );

      if (dist <= radiusMeters && !_alreadyNotified.contains(biz.id)) {
        _alreadyNotified.add(biz.id);
        _sendNotification(biz.name, dist.round());
      } else if (dist > radiusMeters * 2) {
        // Permite volver a notificar si el usuario se aleja y vuelve
        _alreadyNotified.remove(biz.id);
      }
    }
  }

  Future<void> _sendNotification(String businessName, int meters) async {
    const androidDetails = AndroidNotificationDetails(
      'proximity_channel',
      'Negocios cercanos',
      channelDescription: 'Notificaciones cuando estás cerca de una tienda',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notif.show(
      _notifId,
      '¡Estás cerca de $businessName!',
      'A $meters metros. Entra y acumula tus puntos.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Fórmula de Haversine para distancia en metros entre dos coordenadas.
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}
