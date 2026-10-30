import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_event.dart';
import 'package:bonvo/features/auth/presentation/bloc/auth_state.dart';
import 'package:bonvo/features/auth/presentation/widgets/legal_dialog.dart';

/// Menú "Perfil" del cliente (barra inferior en celular).
Future<void> showClientProfileSheet(BuildContext context,
    {VoidCallback? beforeLogout}) {
  final auth = context.read<AuthBloc>().state;
  final user = auth is AuthAuthenticated ? auth.user : null;
  return _sheet(context, title: user?.name ?? 'Mi cuenta', items: [
    _Item(Icons.storefront_rounded, 'Mis tiendas',
        (c) => c.go('/client/tiendas')),
    if (user != null)
      _Item(Icons.history_rounded, 'Historial de compras y canjes',
          (c) => c.push('/client/history', extra: {'userId': user.uid})),
    _Item(Icons.description_outlined, 'Términos y privacidad',
        (c) => showLegalDialog(c, LegalDoc.privacy)),
    _Item(Icons.logout_rounded, 'Cerrar sesión', (c) {
      beforeLogout?.call();
      c.read<AuthBloc>().add(const AuthLogoutRequested());
    }, danger: true),
  ]);
}

/// Menú "Perfil" del negocio (barra inferior en celular).
Future<void> showBusinessProfileSheet(
  BuildContext context, {
  required String businessId,
  required String businessName,
}) {
  final extra = {'businessId': businessId, 'businessName': businessName};
  return _sheet(context,
      title: businessName.isEmpty ? 'Mi negocio' : businessName,
      items: [
        _Item(Icons.inbox_outlined, 'Solicitudes',
            (c) => c.push('/business/requests', extra: extra)),
        _Item(AppIcons.configure, 'Programas de fidelización',
            (c) => c.push('/business/programs', extra: extra)),
        _Item(AppIcons.gift, 'Regalos y promociones',
            (c) => c.push('/business/promotions', extra: extra)),
        _Item(Icons.logout_rounded, 'Cerrar sesión',
            (c) => c.read<AuthBloc>().add(const AuthLogoutRequested()),
            danger: true),
      ]);
}

class _Item {
  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
  final bool danger;
  const _Item(this.icon, this.label, this.onTap, {this.danger = false});
}

Future<void> _sheet(BuildContext context,
    {required String title, required List<_Item> items}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
            for (final item in items)
              ListTile(
                leading: Icon(item.icon,
                    color: item.danger ? AppColors.error : AppColors.primary),
                title: Text(item.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: item.danger
                            ? AppColors.error
                            : AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  // Se usa el context de la pantalla, no el de la hoja cerrada
                  item.onTap(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
