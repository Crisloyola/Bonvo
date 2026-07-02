import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/business/presentation/cubit/business_cubit.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/domain/usecases/create_business.dart';
import 'package:bonvo/injection/injection.dart';

class BusinessSetupPage extends StatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _pointsPerSol = 1;
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa el GPS para capturar la ubicación.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado permanentemente.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación. Verifica que el GPS esté activo.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener la ubicación.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusinessCubit(
        repository: getIt<BusinessRepository>(),
        createBusiness: getIt<CreateBusiness>(),
      ),
      child: BlocConsumer<BusinessCubit, BusinessState>(
        listener: (context, state) {
          if (state is BusinessError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is BusinessCreated) {
            context.read<AuthBloc>().add(const AuthUserRefreshRequested());
            context.go('/business/home');
          }
        },
        builder: (context, state) {
          final authState = context.read<AuthBloc>().state;
          final adminId = authState is AuthAuthenticated ? authState.user.uid : '';

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Icon(
                        Icons.store_mall_directory_outlined,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Registra tu negocio',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configura tu programa de fidelización',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del negocio',
                          prefixIcon: Icon(Icons.storefront),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Puntos por sol
                      Text(
                        'Puntos por cada S/ 1.00',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _pointsPerSol > 1
                                ? () => setState(() => _pointsPerSol--)
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              '$_pointsPerSol pt${_pointsPerSol != 1 ? 's' : ''}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _pointsPerSol < 10
                                ? () => setState(() => _pointsPerSol++)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Ubicación de la tienda
                      Text(
                        'Ubicación de la tienda',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loadingLocation ? null : _captureLocation,
                        icon: _loadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _latitude != null
                                    ? Icons.location_on
                                    : Icons.location_off,
                                color: _latitude != null ? Colors.green : null,
                              ),
                        label: Text(
                          _latitude != null
                              ? 'Ubicación capturada ✓ (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                              : 'Capturar ubicación actual',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Necesaria para notificar a clientes cercanos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 36),

                      if (state is BusinessCreating)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton.icon(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            context.read<BusinessCubit>().createBusiness(
                                  adminId: adminId,
                                  name: _nameController.text.trim(),
                                  description: _descController.text.trim(),
                                  pointsPerSol: _pointsPerSol,
                                  latitude: _latitude,
                                  longitude: _longitude,
                                );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Crear negocio'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
