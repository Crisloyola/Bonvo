import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/presentation/widgets/business_web_shell.dart';
import 'package:bonvo/features/loyalty/data/loyalty_repository.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';
import 'package:bonvo/features/loyalty/presentation/widgets/loyalty_widgets.dart';
import 'package:bonvo/injection/injection.dart';

/// El negocio activa y configura sus programas: sellos, cashback y puntos.
class BusinessProgramsPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessProgramsPage({
    super.key,
    required this.businessId,
    this.businessName = '',
  });

  @override
  State<BusinessProgramsPage> createState() => _BusinessProgramsPageState();
}

class _BusinessProgramsPageState extends State<BusinessProgramsPage> {
  Business? _business;
  LoyaltyPrograms _programs = const LoyaltyPrograms();
  final _rewardCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    getIt<BusinessRepository>().getBusiness(widget.businessId).then((r) {
      if (!mounted) return;
      r.fold((_) {}, (b) {
        setState(() {
          _business = b;
          _programs = b.programs;
          _rewardCtrl.text = b.programs.stampReward;
          _percentCtrl.text = formatPercent(b.programs.cashbackPercent)
              .replaceAll('%', '');
        });
      });
    });
  }

  @override
  void dispose() {
    _rewardCtrl.dispose();
    _percentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final percent =
        double.tryParse(_percentCtrl.text.replaceAll(',', '.')) ?? 0;
    final programs = _programs.copyWith(
      stampReward: _rewardCtrl.text.trim(),
      cashbackPercent: percent,
    );
    if (programs.cashbackEnabled && (percent <= 0 || percent > 100)) {
      _snack('El cashback debe estar entre 0.1% y 100%.', error: true);
      return;
    }
    if (programs.stampsEnabled && programs.stampReward.isEmpty) {
      _snack('Escribe qué regalas al completar la tarjeta de sellos.',
          error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await getIt<LoyaltyRepository>()
          .savePrograms(widget.businessId, programs);
      setState(() => _programs = programs);
      _snack('Programas guardados');
    } catch (e) {
      _snack('No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.textPrimary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final p = _programs;

    final form = _business == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                wide ? 32 : 16, wide ? 28 : 16, wide ? 32 : 16, 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide) ...[
                      const Text('Programas de fidelización',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                    ],
                    const Text(
                      'Activa uno o varios. Tus clientes ganan según lo que '
                      'actives aquí cuando apruebas su compra.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // ── Sellos ──
                    _ProgramCard(
                      icon: Icons.verified_outlined,
                      title: 'Tarjeta de sellos',
                      subtitle: 'Cada visita aprobada suma un sello. '
                          'Ej.: barbería, cafetería.',
                      enabled: p.stampsEnabled,
                      onToggle: (v) => setState(
                          () => _programs = p.copyWith(stampsEnabled: v)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Stepper(
                            label: 'Visitas para el regalo',
                            value: p.stampsRequired,
                            min: 2,
                            max: 20,
                            onChanged: (v) => setState(() =>
                                _programs = p.copyWith(stampsRequired: v)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rewardCtrl,
                            decoration: const InputDecoration(
                              labelText: '¿Qué regalas al completarla?',
                              hintText: 'Ej.: 1 corte gratis',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Cashback ──
                    _ProgramCard(
                      icon: AppIcons.coins,
                      title: 'Cashback',
                      subtitle: 'Devuelves un % de la compra como saldo que '
                          'tú aplicas en su próxima compra. Ej.: tienda de ropa.',
                      enabled: p.cashbackEnabled,
                      onToggle: (v) => setState(
                          () => _programs = p.copyWith(cashbackEnabled: v)),
                      child: TextField(
                        controller: _percentCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje que devuelves',
                          suffixText: '%',
                          helperText: 'Ej.: 2 → en una compra de S/ 100 '
                              'el cliente recibe S/ 2.00',
                        ),
                      ),
                    ),

                    // ── Puntos ──
                    _ProgramCard(
                      icon: AppIcons.star,
                      title: 'Puntos',
                      subtitle: 'Puntos por cada sol de compra, canjeables '
                          'por los regalos que publiques.',
                      enabled: p.pointsEnabled,
                      onToggle: (v) => setState(
                          () => _programs = p.copyWith(pointsEnabled: v)),
                      child: _Stepper(
                        label: 'Puntos por cada S/ 1',
                        value: p.pointsPerSol,
                        min: 1,
                        max: 100,
                        onChanged: (v) => setState(
                            () => _programs = p.copyWith(pointsPerSol: v)),
                      ),
                    ),

                    const SizedBox(height: 8),
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: _save,
                            child: const Text('Guardar programas'),
                          ),
                  ],
                ),
              ),
            ),
          );

    if (wide) {
      return BusinessWebShell(
        current: BusinessSection.programs,
        businessId: widget.businessId,
        businessName: _business?.name ?? widget.businessName,
        logoBase64: _business?.logoBase64,
        child: form,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Programas de fidelización')),
      body: form,
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const _ProgramCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: enabled ? AppColors.primary : AppColors.border,
            width: enabled ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.primary : AppColors.amberTint,
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                child: Icon(icon,
                    color: enabled ? Colors.white : AppColors.textSecondary,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(AppIcons.minusCircle, color: AppColors.primary),
        ),
        SizedBox(
          width: 40,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(AppIcons.plusCircle, color: AppColors.primary),
        ),
      ],
    );
  }
}
