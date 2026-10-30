import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/injection/injection.dart';

/// Pide el correo y envía el enlace de Firebase para crear una contraseña nueva.
Future<void> showForgotPasswordDialog(BuildContext context,
    {String initialEmail = ''}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _ctrl = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await getIt<FirebaseAuth>().sendPasswordResetEmail(email: email);
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'invalid-email' => 'El correo no es válido.',
            'too-many-requests' =>
              'Demasiados intentos. Espera unos minutos.',
            'network-request-failed' => 'Sin conexión a internet.',
            // Por seguridad no se revela si el correo existe o no
            _ => null,
          });
      if (_error == null) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.primary, size: 40),
        title: const Text('Revisa tu correo',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Si existe una cuenta con ${_ctrl.text.trim()}, te llegará un '
          'enlace para crear una contraseña nueva. Revisa también la '
          'carpeta de spam.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escribe tu correo y te enviaremos un enlace para crear una '
            'contraseña nueva.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, size: 19),
              hintText: 'tucorreo@ejemplo.com',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Enviar enlace'),
        ),
      ],
    );
  }
}
