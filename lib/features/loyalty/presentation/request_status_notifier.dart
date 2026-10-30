import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/services/notification_service.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/features/loyalty/presentation/widgets/loyalty_widgets.dart';
import 'package:bonvo/injection/injection.dart';

/// Messenger global: permite mostrar avisos sobre cualquier pantalla.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Avisa al cliente, esté en la pantalla que esté, cuando una tienda aprueba
/// o rechaza una de sus solicitudes. También queda en la campana.
class RequestStatusNotifier {
  final _subs = <StreamSubscription>[];
  StreamSubscription? _authSub;
  String? _uid;
  List<String> _businessIds = const [];

  /// Estado conocido de cada solicitud (para detectar el cambio).
  final Map<String, RequestStatus> _known = {};

  /// Idempotente: se puede llamar en cada rebuild.
  void start(String uid, List<String> businessIds) {
    if (_uid == uid && _sameIds(businessIds)) return;
    stop();
    _uid = uid;
    _businessIds = List.of(businessIds);
    for (final bid in businessIds) {
      var first = true;
      _subs.add(getIt<LoyaltyRepository>()
          .watchUserRequests(bid, uid)
          .listen((requests) {
        for (final r in requests) {
          final before = _known[r.id];
          _known[r.id] = r.status;
          // La primera lectura solo registra el estado actual
          if (!first && before == RequestStatus.pending && !r.isPending) {
            _notify(r);
          }
        }
        first = false;
      }));
    }
    _authSub = getIt<AuthBloc>().stream.listen((s) {
      if (s is AuthUnauthenticated) stop();
    });
  }

  void stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _authSub?.cancel();
    _authSub = null;
    _known.clear();
    _uid = null;
    _businessIds = const [];
  }

  bool _sameIds(List<String> ids) =>
      ids.length == _businessIds.length && ids.every(_businessIds.contains);

  void _notify(LoyaltyRequest r) {
    final approved = r.status == RequestStatus.approved;
    final String title;
    final String body;
    if (!approved) {
      title = '${r.businessName} rechazó tu solicitud';
      body = describeRequest(r);
    } else if (r.type == RequestType.purchase) {
      title = '${r.businessName} aprobó tu compra';
      final earned = describeEarned(r);
      body = earned.isEmpty ? describeRequest(r) : earned;
    } else {
      title = '${r.businessName} te entregó tu regalo';
      body = r.rewardTitle;
    }

    getIt<NotificationService>().show(NotifItem(
      title: title,
      body: body,
      businessId: r.businessId,
      businessName: r.businessName,
      at: DateTime.now(),
    ));

    rootMessengerKey.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      backgroundColor: approved ? AppColors.textPrimary : AppColors.error,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(
            approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: approved ? AppColors.lilac : Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
                if (body.isNotEmpty)
                  Text(body,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
