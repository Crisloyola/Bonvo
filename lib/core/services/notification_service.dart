import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bonvo/config/routes/app_router.dart';
import 'package:bonvo/injection/injection.dart';

class NotifItem {
  final String title;
  final String body;
  final String businessId;
  final String businessName;
  final String? logoBase64;
  final DateTime at;

  const NotifItem({
    required this.title,
    required this.body,
    required this.businessId,
    required this.businessName,
    this.logoBase64,
    required this.at,
  });
}

class NotificationService {
  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final List<NotifItem> items = [];

  List<String> _businessIds = [];
  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'promo_channel';
  static const _channelName = 'Promociones';

  void setBusinessIds(List<String> ids) => _businessIds = List.of(ids);
  List<String> get businessIds => List.unmodifiable(_businessIds);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Nuevas promociones de tus tiendas inscritas',
          importance: Importance.high,
        ));

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        getIt<AppRouter>().router.push(
          '/client/promotions',
          extra: getIt<NotificationService>().businessIds,
        );
      },
    );
  }

  Future<void> show(NotifItem item) async {
    items.insert(0, item);
    if (items.length > 20) items.removeLast();
    unreadCount.value++;

    AndroidBitmap<Object>? largeIcon;
    if (item.logoBase64 != null) {
      try {
        largeIcon = ByteArrayAndroidBitmap(base64Decode(item.logoBase64!));
      } catch (_) {}
    }

    await _local.show(
      item.title.hashCode ^ item.at.millisecondsSinceEpoch,
      item.title,
      item.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: largeIcon,
          styleInformation: BigTextStyleInformation(item.body),
        ),
      ),
      payload: item.businessId,
    );
  }

  void clearCount() => unreadCount.value = 0;
}
