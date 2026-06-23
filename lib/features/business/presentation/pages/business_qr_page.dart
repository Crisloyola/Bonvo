import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';

/// Muestra el QR de la tienda. Los clientes lo escanean para unirse al programa.
class BusinessQrPage extends StatelessWidget {
  final Business business;
  const BusinessQrPage({super.key, required this.business});

  // El QR contiene un texto con prefijo para distinguirlo de QR de cliente
  String get _qrData => 'biz:${business.id}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR de mi negocio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              business.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tus clientes escanean este QR\npara unirse a tu programa de puntos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${business.pointsPerSol} pt por cada S/ 1.00',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
