import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/core/services/fcm_service.dart';
import 'package:bonvo/features/points/domain/usecases/enroll_in_business.dart';
import 'package:bonvo/injection/injection.dart';

/// Pantalla que aparece tras escanear el QR de una tienda.
/// Muestra el nombre del negocio y confirma la inscripción al programa.
class JoinBusinessPage extends StatefulWidget {
  final String businessId;
  const JoinBusinessPage({super.key, required this.businessId});

  @override
  State<JoinBusinessPage> createState() => _JoinBusinessPageState();
}

class _JoinBusinessPageState extends State<JoinBusinessPage> {
  String? _businessName;
  int? _pointsPerSol;
  bool _loading = true;
  bool _enrolling = false;
  bool _enrolled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final doc = await getIt<FirebaseFirestore>()
          .collection('businesses')
          .doc(widget.businessId)
          .get();
      if (!doc.exists) {
        setState(() {
          _error = 'Negocio no encontrado.';
          _loading = false;
        });
        return;
      }
      final data = doc.data()!;
      setState(() {
        _businessName = data['name'] as String? ?? 'Sin nombre';
        _pointsPerSol = (data['pointsPerSol'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el negocio.';
        _loading = false;
      });
    }
  }

  Future<void> _enroll(String userId) async {
    setState(() => _enrolling = true);
    final result = await getIt<EnrollInBusiness>()(
      EnrollParams(userId: userId, businessId: widget.businessId),
    );
    result.fold(
      (failure) {
        setState(() => _enrolling = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
          );
        }
      },
      (_) {
        setState(() {
          _enrolling = false;
          _enrolled = true;
        });
        // Suscribirse al topic FCM para recibir push de esta tienda
        getIt<FcmService>().subscribeToBusinessTopic(widget.businessId);
        // Refresca el perfil del usuario para que tenga el nuevo businessId
        context.read<AuthBloc>().add(const AuthUserRefreshRequested());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirme al programa')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userId =
              authState is AuthAuthenticated ? authState.user.uid : null;

          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          if (_enrolled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      '¡Te uniste a $_businessName!',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ahora acumulas $_pointsPerSol pt por cada S/ 1.00 de compra.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => context.go('/client/home'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: const Text('Ir a mi tarjeta'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.store, size: 72, color: Colors.indigo),
                const SizedBox(height: 20),
                Text(
                  _businessName ?? '',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Programa de fidelización',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        '$_pointsPerSol punto${_pointsPerSol != 1 ? 's' : ''} por cada S/ 1.00',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_enrolling)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton.icon(
                    onPressed:
                        userId != null ? () => _enroll(userId) : null,
                    icon: const Icon(Icons.card_membership),
                    label: const Text('Unirme al programa'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/client/home'),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
