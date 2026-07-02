import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bonvo/config/routes/app_router.dart';
import 'package:bonvo/core/services/notification_service.dart';
import 'package:bonvo/injection/injection.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'business_channel',
    'Notificaciones de negocios',
    description: 'Promociones y avisos de tus tiendas',
    importance: Importance.high,
  );

  Future<void> init(String userId) async {
    // Pide permiso en iOS/Android 13+
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Canal para notificaciones de alta prioridad
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Inicializar plugin local
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => _navigateToPromotions(),
    );

    // Guardar token en Firestore para que el admin pueda rastrear
    final token = await _messaging.getToken();
    if (token != null && userId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }

    // Refrescar token automáticamente
    _messaging.onTokenRefresh.listen((newToken) {
      if (userId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': newToken});
      }
    });

    // Notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Cuando el usuario toca la notificación con la app en background/cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _navigateToPromotions());
  }

  void _navigateToPromotions() {
    final ids = getIt<NotificationService>().businessIds;
    if (ids.isEmpty) return;
    getIt<AppRouter>().router.push('/client/promotions', extra: ids);
  }

  Future<void> subscribeToBusinessTopic(String businessId) async {
    await _messaging.subscribeToTopic('biz_$businessId');
  }

  Future<void> unsubscribeFromBusinessTopic(String businessId) async {
    await _messaging.unsubscribeFromTopic('biz_$businessId');
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
