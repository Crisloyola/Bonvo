import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';

enum LegalDoc { terms, privacy }

/// Textos base de Términos y Privacidad. Son una plantilla según lo que hace
/// la app: deben revisarse legalmente antes de operar comercialmente.
Future<void> showLegalDialog(BuildContext context, LegalDoc doc) {
  final (title, sections) = switch (doc) {
    LegalDoc.terms => ('Términos y condiciones', _terms),
    LegalDoc.privacy => ('Política de privacidad', _privacy),
  };
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (heading, body) in sections) ...[
                Text(heading,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.45)),
                const SizedBox(height: 14),
              ],
              const Text('Última actualización: octubre de 2026',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

const _terms = [
  (
    '1. El servicio',
    'Creatrix es una plataforma de fidelización que permite a los negocios '
        'ofrecer tarjetas de sellos, cashback y puntos canjeables por premios, '
        'y a los clientes acumular esos beneficios en cada tienda.'
  ),
  (
    '2. Cuentas',
    'Para usar la plataforma necesitas una cuenta con datos reales. Eres '
        'responsable de mantener tu contraseña en reserva y de la actividad '
        'que se realice con tu cuenta.'
  ),
  (
    '3. Compras, puntos y premios',
    'Cada compra, sello o canje que registres es una solicitud que el '
        'negocio debe aprobar. Cada negocio define sus propios programas, '
        'premios y condiciones, y es el responsable de entregarlos. Los puntos, '
        'sellos y saldo de cashback son de cada tienda, no son dinero, no se '
        'transfieren entre tiendas ni se canjean por efectivo, salvo que el '
        'negocio lo indique.'
  ),
  (
    '4. Uso correcto',
    'Está prohibido registrar compras falsas, intentar obtener beneficios '
        'que no corresponden o usar la plataforma de forma fraudulenta. Podemos '
        'suspender cuentas que incumplan estas reglas.'
  ),
  (
    '5. Cambios',
    'Podemos actualizar estos términos; te avisaremos en la app cuando haya '
        'cambios importantes.'
  ),
];

const _privacy = [
  (
    'Qué datos guardamos',
    'Tu nombre, correo electrónico y, si la subes, tu foto de perfil. De '
        'cada tienda en la que te inscribes guardamos tus puntos, sellos, saldo '
        'de cashback y el historial de compras y canjes (monto, fecha y estado). '
        'Los negocios además registran su nombre, logo, imágenes de premios y, '
        'si lo desean, la ubicación de su local.'
  ),
  (
    'Para qué los usamos',
    'Solo para que funcione el programa de fidelización: calcular tus '
        'beneficios, mostrárselos al negocio para que apruebe tus solicitudes y '
        'avisarte de promociones de las tiendas en las que estás inscrito. No '
        'vendemos tus datos.'
  ),
  (
    'Quién los ve',
    'Cada negocio ve solo los datos de los clientes inscritos en su tienda '
        '(nombre, foto, saldos e historial en esa tienda). Los datos se '
        'almacenan en servidores de Google Firebase.'
  ),
  (
    'Tus derechos',
    'De acuerdo con la Ley N.° 29733 de Protección de Datos Personales, '
        'puedes solicitar el acceso, rectificación o eliminación de tus datos, '
        'escribiéndonos desde el correo con el que te registraste.'
  ),
];
