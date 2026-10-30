import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';

enum BusinessSection { home, requests, clients, promotions, programs }

/// Estructura de escritorio del panel de negocio: menú lateral + contenido.
/// En celular no se usa; cada página mantiene su barra inferior.
class BusinessWebShell extends StatelessWidget {
  final BusinessSection current;
  final String businessId;
  final String businessName;
  final String? logoBase64;

  /// Abre los ajustes del negocio (QR, puntos, logo, banner).
  final VoidCallback? onSettings;
  final Widget child;

  const BusinessWebShell({
    super.key,
    required this.current,
    required this.businessId,
    required this.businessName,
    required this.child,
    this.logoBase64,
    this.onSettings,
  });

  Map<String, String> get _extra =>
      {'businessId': businessId, 'businessName': businessName};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 248,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Brand(name: businessName, logoBase64: logoBase64),
                const SizedBox(height: 28),
                _SideItem(
                  icon: AppIcons.dashboard,
                  label: 'Inicio',
                  active: current == BusinessSection.home,
                  onTap: () => context.go('/business/home'),
                ),
                _SideItem(
                  icon: Icons.inbox_outlined,
                  label: 'Solicitudes',
                  active: current == BusinessSection.requests,
                  onTap: () => context.go('/business/requests', extra: _extra),
                ),
                _SideItem(
                  icon: AppIcons.clients,
                  label: 'Clientes',
                  active: current == BusinessSection.clients,
                  onTap: () => context.go('/business/clients', extra: _extra),
                ),
                _SideItem(
                  icon: AppIcons.gift,
                  label: 'Regalos y promos',
                  active: current == BusinessSection.promotions,
                  onTap: () =>
                      context.go('/business/promotions', extra: _extra),
                ),
                _SideItem(
                  icon: AppIcons.configure,
                  label: 'Programas',
                  active: current == BusinessSection.programs,
                  onTap: () => context.go('/business/programs', extra: _extra),
                ),
                const Spacer(),
                if (onSettings != null)
                  _SideItem(
                    icon: AppIcons.settings,
                    label: 'Configuración',
                    onTap: onSettings!,
                  ),
                _SideItem(
                  icon: AppIcons.signOut,
                  label: 'Cerrar sesión',
                  color: AppColors.error,
                  onTap: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final String name;
  final String? logoBase64;
  const _Brand({required this.name, this.logoBase64});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: logoBase64 != null
              ? Image.memory(base64Decode(logoBase64!), fit: BoxFit.cover)
              : const Icon(AppIcons.store, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Creatrix Business',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                name.isEmpty ? 'Mi negocio' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (active ? AppColors.primary : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.greenTint : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: active ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
