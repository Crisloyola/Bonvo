import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/features/loyalty/presentation/widgets/loyalty_widgets.dart';
import 'package:bonvo/injection/injection.dart';

/// Solicitudes pendientes del negocio, en vivo, con Aprobar / Rechazar.
class PendingRequestsList extends StatefulWidget {
  final String businessId;
  final LoyaltyPrograms programs;

  /// Si se indica, muestra solo las primeras N (resumen del panel).
  final int? limit;
  final VoidCallback? onSeeAll;

  /// Se llama después de aprobar o rechazar (p. ej. para refrescar métricas).
  final VoidCallback? onResolved;

  const PendingRequestsList({
    super.key,
    required this.businessId,
    required this.programs,
    this.limit,
    this.onSeeAll,
    this.onResolved,
  });

  @override
  State<PendingRequestsList> createState() => _PendingRequestsListState();
}

class _PendingRequestsListState extends State<PendingRequestsList> {
  final _repo = getIt<LoyaltyRepository>();
  late final Stream<List<LoyaltyRequest>> _stream =
      _repo.watchPendingRequests(widget.businessId);
  final Set<String> _busy = {};

  Future<void> _act(LoyaltyRequest r, bool approve) async {
    setState(() => _busy.add(r.id));
    try {
      if (approve) {
        await _repo.approve(r);
      } else {
        await _repo.reject(r);
      }
      widget.onResolved?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? 'Aprobada: ${describeRequest(r)} de ${r.userName}'
              : 'Rechazada: ${describeRequest(r)} de ${r.userName}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LoyaltyRequest>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Empty(text: 'No se pudieron cargar: ${snap.error}');
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return const _Empty(
              text: 'No hay solicitudes pendientes.\n'
                  'Cuando un cliente registre una compra aparecerá aquí.');
        }
        final shown =
            widget.limit == null ? all : all.take(widget.limit!).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in shown)
              _RequestCard(
                request: r,
                preview: _preview(r),
                busy: _busy.contains(r.id),
                onApprove: () => _act(r, true),
                onReject: () => _act(r, false),
              ),
            if (widget.limit != null &&
                all.length > widget.limit! &&
                widget.onSeeAll != null)
              TextButton(
                onPressed: widget.onSeeAll,
                child: Text('Ver las ${all.length} solicitudes'),
              ),
          ],
        );
      },
    );
  }

  /// Lo que recibirá el cliente si se aprueba.
  String _preview(LoyaltyRequest r) {
    final p = widget.programs;
    return switch (r.type) {
      RequestType.purchase =>
        p.earnFor(r.amountCents, only: r.program).describe(),
      RequestType.reward => 'Entregar regalo · −${r.rewardPoints} pts',
      RequestType.stampReward => 'Entregar regalo de la tarjeta de sellos',
    };
  }
}

class _RequestCard extends StatelessWidget {
  final LoyaltyRequest request;
  final String preview;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.preview,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name = request.userName.isEmpty ? 'Cliente' : request.userName;
    final isRedeem = request.type != RequestType.purchase;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: isRedeem ? AppColors.greenBorder : AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    isRedeem ? AppColors.primary : AppColors.textPrimary,
                child: Icon(
                  isRedeem ? Icons.card_giftcard_rounded : Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text(describeRequest(request),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                    if (preview.isNotEmpty)
                      Text(preview,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    Text(_ago(request.createdAt),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botones con ícono y texto para que no se confundan
          if (busy)
            const Center(
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Rechazar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(isRedeem ? 'Entregar' : 'Aprobar'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    );
  }
}
