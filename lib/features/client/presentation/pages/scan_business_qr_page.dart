import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// El cliente escanea el QR de la tienda para unirse a su programa.
class ScanBusinessQrPage extends StatefulWidget {
  const ScanBusinessQrPage({super.key});

  @override
  State<ScanBusinessQrPage> createState() => _ScanBusinessQrPageState();
}

class _ScanBusinessQrPageState extends State<ScanBusinessQrPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // El QR de la tienda tiene el formato: "biz:BUSINESS_ID"
    if (!raw.startsWith('biz:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este no es un QR de tienda válido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _scanned = true;
    _controller.stop();
    final businessId = raw.substring(4);
    context.pushReplacement('/client/join', extra: {'businessId': businessId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de tienda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta al QR de la tienda\npara unirte a su programa',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
