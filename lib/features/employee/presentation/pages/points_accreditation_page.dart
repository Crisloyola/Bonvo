import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/widgets/app_button.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/employee/presentation/bloc/scanner_cubit.dart';
import 'package:bonvo/features/points/domain/usecases/earn_points.dart';
import 'package:bonvo/injection/injection.dart';

class PointsAccreditationPage extends StatefulWidget {
  final String clientUserId;
  final String homeRoute;

  const PointsAccreditationPage({
    super.key,
    required this.clientUserId,
    this.homeRoute = '/employee/home',
  });

  @override
  State<PointsAccreditationPage> createState() =>
      _PointsAccreditationPageState();
}

class _PointsAccreditationPageState extends State<PointsAccreditationPage> {
  // Datos del cliente y negocio
  String _clientName = '';
  int _clientPoints = 0;
  String _businessId = '';
  String _businessName = '';
  int _pointsPerSol = 1;
  bool _dataLoading = true;

  // Monto ingresado (en centavos)
  int _cents = 0;

  int get _pointsToEarn =>
      ((_cents / 100.0) * _pointsPerSol).floor();

  String get _displayAmount {
    final soles = _cents ~/ 100;
    final centavos = _cents % 100;
    return '$soles.${centavos.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _businessId = authState.user.businessIds.isNotEmpty
          ? authState.user.businessIds.first
          : '';
    }

    // Cargar datos del negocio
    if (_businessId.isNotEmpty) {
      final bizResult =
          await getIt<BusinessRepository>().getBusiness(_businessId);
      bizResult.fold((_) {}, (biz) {
        if (mounted) {
          setState(() {
            _businessName = biz.name;
            _pointsPerSol = biz.pointsPerSol;
          });
        }
      });
    }

    // Cargar datos del cliente desde Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientUserId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _clientName = (data['name'] as String? ?? '').isNotEmpty
              ? data['name'] as String
              : 'Cliente';
          _clientPoints = (data['points'] as int?) ?? 0;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _clientName = 'Cliente');
    }

    if (mounted) setState(() => _dataLoading = false);
  }

  void _addDigit(int d) {
    if (_cents >= 9999999) return; // cap a S/ 99,999.99
    setState(() => _cents = _cents * 10 + d);
  }

  void _backspace() => setState(() => _cents = _cents ~/ 10);
  void _clear() => setState(() => _cents = 0);

  String get _initial =>
      _clientName.isNotEmpty ? _clientName[0].toUpperCase() : '?';

  static const _avatarColors = [
    Color(0xFF2A2A27),
    Color(0xFF9B6BFF),
    Color(0xFF7C3AED),
    Color(0xFFE5484D),
    Color(0xFF9B6BFF),
  ];

  Color get _avatarColor =>
      _avatarColors[_clientName.hashCode.abs() % _avatarColors.length];

  static String _fmtPts(int v) {
    if (v >= 1000) {
      return '${v ~/ 1000},${(v % 1000).toString().padLeft(3, '0')}';
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScannerCubit(getIt<EarnPoints>()),
      child: BlocConsumer<ScannerCubit, ScannerState>(
        listener: (context, state) {
          if (state is ScannerError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        builder: (context, state) {
          if (state is ScannerSuccess) {
            final scannerRoute =
                widget.homeRoute == '/business/home'
                    ? '/business/scanner'
                    : '/employee/scanner';
            return _SuccessView(
              clientName: _clientName,
              pointsEarned: state.pointsEarned,
              newTotal: state.newTotalPoints,
              onScanNext: () {
                context.read<ScannerCubit>().reset();
                context.go(scannerRoute);
              },
              onGoHome: () => context.go(widget.homeRoute),
            );
          }

          final isLoading = state is ScannerLoading;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Container(
                  color: Colors.white,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(AppIcons.back,
                                color: AppColors.textPrimary),
                            onPressed: () {
                              final route = widget.homeRoute ==
                                      '/business/home'
                                  ? '/business/scanner'
                                  : '/employee/scanner';
                              context.go(route);
                            },
                          ),
                          const Text(
                            'Acreditar puntos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenido ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tarjeta de cliente
                        _dataLoading
                            ? _ClientCardSkeleton()
                            : _ClientCard(
                                initial: _initial,
                                avatarColor: _avatarColor,
                                name: _clientName,
                                points: _fmtPts(_clientPoints),
                              ),

                        const SizedBox(height: 24),

                        // Monto
                        Column(
                          children: [
                            const Text(
                              'Monto de la compra',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  'S/ ',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  _displayAmount,
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    color: _cents > 0
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Chip ámbar de puntos
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.amberTint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AppIcons.star,
                                    color: AppColors.amberText,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Acreditará +$_pointsToEarn puntos',
                                  style: const TextStyle(
                                    color: AppColors.amberText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Nota de configuración
                        Text(
                          'Configuración: $_pointsPerSol pts por cada S/ 1.00',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Numpad
                        _Numpad(
                          onDigit: _addDigit,
                          onBackspace: _backspace,
                          onClear: _clear,
                        ),

                        const SizedBox(height: 20),

                        // Botón acreditar
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator())
                            : GestureDetector(
                                onTap: () {
                                  if (_cents == 0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Ingresa el monto de la compra'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ));
                                    return;
                                  }
                                  context
                                      .read<ScannerCubit>()
                                      .creditPoints(
                                        userId: widget.clientUserId,
                                        businessId: _businessId
                                            .isNotEmpty
                                            ? _businessId
                                            : 'demo_negocio',
                                        businessName: _businessName
                                            .isNotEmpty
                                            ? _businessName
                                            : 'Mi Negocio',
                                        purchaseAmount: _cents / 100.0,
                                        pointsPerSol: _pointsPerSol,
                                      );
                                },
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradient,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.button),
                                    boxShadow: AppShadows.button,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Acreditar +$_pointsToEarn puntos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final String initial;
  final Color avatarColor;
  final String name;
  final String points;

  const _ClientCard({
    required this.initial,
    required this.avatarColor,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE5FF), Color(0xFFC4A6FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: AppColors.greenBorder),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(AppIcons.check,
                          color: Colors.white, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Cliente verificado · $points pts',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5FF),
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        border: Border.all(color: AppColors.greenBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFC4A6FF),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4A6FF),
                    borderRadius: BorderRadius.circular(7),
                  )),
              const SizedBox(height: 6),
              Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4A6FF),
                    borderRadius: BorderRadius.circular(5),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _Numpad extends StatelessWidget {
  final void Function(int) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const _Numpad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([_key('1', () => onDigit(1)), _key('2', () => onDigit(2)), _key('3', () => onDigit(3))]),
        const SizedBox(height: 10),
        _row([_key('4', () => onDigit(4)), _key('5', () => onDigit(5)), _key('6', () => onDigit(6))]),
        const SizedBox(height: 10),
        _row([_key('7', () => onDigit(7)), _key('8', () => onDigit(8)), _key('9', () => onDigit(9))]),
        const SizedBox(height: 10),
        _row([
          _keyWidget(
            GestureDetector(
              onTap: onClear,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.card,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'C',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          _key('0', () => onDigit(0)),
          _keyWidget(
            GestureDetector(
              onTap: onBackspace,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.card,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  AppIcons.backspace,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) => Row(
        children: children
            .expand((w) => [w, const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );

  Widget _key(String label, VoidCallback onTap) => _keyWidget(
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );

  Widget _keyWidget(Widget child) => Expanded(child: child);
}

// ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final String clientName;
  final int pointsEarned;
  final int newTotal;
  final VoidCallback onScanNext;
  final VoidCallback onGoHome;

  const _SuccessView({
    required this.clientName,
    required this.pointsEarned,
    required this.newTotal,
    required this.onScanNext,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.button,
                ),
                child: const Icon(AppIcons.check,
                    color: Colors.white, size: 52),
              ),

              const SizedBox(height: 24),

              const Text(
                '¡Puntos acreditados!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              if (clientName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'para $clientName',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius:
                      BorderRadius.circular(AppRadius.cardLg),
                  boxShadow: AppShadows.button,
                ),
                child: Text(
                  '+$pointsEarned puntos',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Total del cliente: $newTotal pts',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
              ),

              const SizedBox(height: 48),

              AppButton(
                label: 'Escanear otro cliente',
                icon: AppIcons.scanner,
                onPressed: onScanNext,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Volver al inicio',
                variant: AppButtonVariant.white,
                onPressed: onGoHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
