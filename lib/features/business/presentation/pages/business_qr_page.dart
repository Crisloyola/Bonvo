import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/file_download.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/loyalty/presentation/widgets/loyalty_widgets.dart';

/// QR de la tienda como afiche listo para imprimir: los clientes lo escanean
/// para unirse y registrar sus compras. Se puede descargar como PNG.
class BusinessQrPage extends StatefulWidget {
  final Business business;
  const BusinessQrPage({super.key, required this.business});

  @override
  State<BusinessQrPage> createState() => _BusinessQrPageState();
}

class _BusinessQrPageState extends State<BusinessQrPage> {
  final _posterKey = GlobalKey();
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final boundary = _posterKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // Alta resolución para que se imprima nítido (≈ 1800 × 2400 px)
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final name = widget.business.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      await downloadBytes(
          png!.buffer.asUint8List(), 'qr-$name.png', 'image/png');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo descargar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('QR de mi tienda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Imprímelo y pégalo en tu mostrador. Tus clientes lo '
                  'escanean para unirse y registrar sus compras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                // El afiche se dibuja a tamaño fijo y se escala a la pantalla
                FittedBox(
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: _Poster(business: widget.business),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _downloading ? null : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded),
                  label: const Text('Descargar afiche (PNG)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Afiche de 600 × 800 (proporción 3:4).
class _Poster extends StatelessWidget {
  final Business business;
  const _Poster({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 800,
      color: Colors.white,
      child: Column(
        children: [
          // Cabecera de marca
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 36),
            decoration: const BoxDecoration(gradient: AppColors.gradient),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: business.logoBase64 != null
                      ? Image.memory(base64Decode(business.logoBase64!),
                          fit: BoxFit.cover)
                      : const Icon(AppIcons.store,
                          color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 16),
                Text(
                  business.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escanea y gana en cada compra',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // QR
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: 'biz:${business.id}',
              version: QrVersions.auto,
              size: 270,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 22),
          // Beneficios activos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: ProgramList(programs: business.programs),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              'Abre la app Creatrix › Escanear tienda',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
