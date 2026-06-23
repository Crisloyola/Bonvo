import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Muestra el QR del cliente a pantalla completa para facilitar el escaneo.
class QrFullscreenPage extends StatelessWidget {
  final String userId;
  final String userName;

  const QrFullscreenPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Mi QR'),
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
                data: userId,
                version: QrVersions.auto,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Muestra este código al empleado\npara acumular tus puntos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
