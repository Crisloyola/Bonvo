import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/domain/entities/auth_user.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';

enum ClientSection { home, stores, promotions }

/// Estructura de escritorio del cliente: menú lateral + contenido.
/// En celular no se usa; cada página mantiene su barra inferior.
class ClientWebShell extends StatelessWidget {
  final ClientSection current;
  final AuthUser user;
  final Widget child;

  const ClientWebShell({
    super.key,
    required this.current,
    required this.user,
    required this.child,
  });

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
                _Profile(user: user),
                const SizedBox(height: 28),
                _SideItem(
                  icon: AppIcons.home,
                  label: 'Inicio',
                  active: current == ClientSection.home,
                  onTap: () => context.go('/client/home'),
                ),
                _SideItem(
                  icon: AppIcons.tiendas,
                  label: 'Mis tiendas',
                  active: current == ClientSection.stores,
                  onTap: () => context.go('/client/tiendas'),
                ),
                _SideItem(
                  icon: AppIcons.promotions,
                  label: 'Promociones',
                  active: current == ClientSection.promotions,
                  onTap: () =>
                      context.go('/client/promotions', extra: user.businessIds),
                ),
                _SideItem(
                  icon: AppIcons.scanner,
                  label: 'Escanear tienda',
                  onTap: () => context.push('/client/scan-business'),
                ),
                _SideItem(
                  icon: AppIcons.history,
                  label: 'Historial',
                  onTap: () => context
                      .push('/client/history', extra: {'userId': user.uid}),
                ),
                const Spacer(),
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

class _Profile extends StatelessWidget {
  final AuthUser user;
  const _Profile({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: AppColors.gradient,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: user.photoBase64 != null
              ? Image.memory(base64Decode(user.photoBase64!), fit: BoxFit.cover)
              : Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Creatrix',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                user.name.isEmpty ? 'Mi cuenta' : user.name,
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
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
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
