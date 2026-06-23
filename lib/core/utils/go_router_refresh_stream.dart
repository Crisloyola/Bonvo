import 'dart:async';
import 'package:flutter/foundation.dart';

/// Convierte cualquier Stream en un Listenable que GoRouter puede usar
/// como refreshListenable para recalcular redirects automáticamente.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
