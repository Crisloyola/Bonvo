import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/injection/injection.dart';

/// Resumen de saldos de un cliente en la tienda ("120 pts · S/ 2.00 · 3/10 sellos").
String memberBalances(LoyaltyPrograms p, Membership? m) {
  if (m == null) return 'Sin movimientos';
  return [
    if (p.pointsEnabled) '${m.points} pts',
    if (p.cashbackEnabled) '${formatSoles(m.cashbackCents)} cashback',
    if (p.stampsEnabled) '${m.stamps}/${p.stampsRequired} sellos',
  ].join(' · ');
}

/// Detalle del cliente para el negocio: saldos y aplicar cashback.
Future<void> showMemberSheet(
  BuildContext context, {
  required Business business,
  required String userId,
  required String userName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MemberSheet(
      business: business,
      userId: userId,
      userName: userName,
    ),
  );
}

class _MemberSheet extends StatefulWidget {
  final Business business;
  final String userId;
  final String userName;
  const _MemberSheet({
    required this.business,
    required this.userId,
    required this.userName,
  });

  @override
  State<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends State<_MemberSheet> {
  final _repo = getIt<LoyaltyRepository>();
  late final Stream<Membership?> _stream =
      _repo.watchMembership(widget.business.id, widget.userId);
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final value = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
    final cents = (value * 100).round();
    setState(() => _saving = true);
    try {
      await _repo.applyCashback(
        businessId: widget.business.id,
        businessName: widget.business.name,
        userId: widget.userId,
        amountCents: cents,
      );
      _ctrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Se aplicaron ${formatSoles(cents)} de cashback'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.business.programs;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: StreamBuilder<Membership?>(
        stream: _stream,
        builder: (context, snap) {
          final m = snap.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.userName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text(
                m == null
                    ? 'Aún sin compras aprobadas'
                    : '${m.visits} compras aprobadas',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (p.pointsEnabled)
                    _Pill(label: 'Puntos', value: '${m?.points ?? 0}'),
                  if (p.cashbackEnabled)
                    _Pill(
                        label: 'Cashback',
                        value: formatSoles(m?.cashbackCents ?? 0)),
                  if (p.stampsEnabled)
                    _Pill(
                        label: 'Sellos',
                        value: '${m?.stamps ?? 0}/${p.stampsRequired}'),
                  if (p.stampsEnabled && (m?.stampRewards ?? 0) > 0)
                    _Pill(
                        label: 'Regalos por entregar',
                        value: '${m!.stampRewards}'),
                ],
              ),
              if (p.cashbackEnabled) ...[
                const SizedBox(height: 20),
                const Text('Aplicar cashback en esta compra',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          prefixText: 'S/ ',
                          hintText: (m?.cashbackCents ?? 0) > 0
                              ? 'Máx. ${((m!.cashbackCents) / 100).toStringAsFixed(2)}'
                              : 'Sin saldo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(110, 52)),
                            onPressed: (m?.cashbackCents ?? 0) > 0
                                ? _apply
                                : null,
                            child: const Text('Aplicar'),
                          ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Se descuenta del saldo del cliente. Úsalo cuando pague '
                  'con su cashback.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
