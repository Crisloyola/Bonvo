import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:bonvo/config/themes/app_theme.dart';

class QrScannerPage extends StatefulWidget {
  /// Ruta a la que volver al presionar atrás (default: /employee/home)
  final String homeRoute;

  const QrScannerPage({super.key, this.homeRoute = '/employee/home'});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    _controller.stop();

    context.pushReplacement(
      '/employee/accredit',
      extra: {'userId': raw, 'homeRoute': widget.homeRoute},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay oscuro con recorte
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x99000000),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Marco del QR con esquinas coloreadas
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _CornerPainter(color: AppColors.primaryLight),
              ),
            ),
          ),

          // AppBar transparente
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => context.go(widget.homeRoute),
                  ),
                  const Expanded(
                    child: Text(
                      'Escanear QR del cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch_rounded,
                        color: Colors.white),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              ),
            ),
          ),

          // Instrucción inferior
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded,
                          color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Apunta al QR del cliente',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLen = 28.0;
    const r = 20.0;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(0, cornerLen)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(cornerLen, 0),
        paint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - cornerLen, 0)
          ..lineTo(size.width - r, 0)
          ..arcToPoint(Offset(size.width, r),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(size.width, cornerLen),
        paint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - cornerLen)
          ..lineTo(0, size.height - r)
          ..arcToPoint(Offset(r, size.height),
              radius: const Radius.circular(r), clockwise: false)
          ..lineTo(cornerLen, size.height),
        paint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - cornerLen, size.height)
          ..lineTo(size.width - r, size.height)
          ..arcToPoint(Offset(size.width, size.height - r),
              radius: const Radius.circular(r), clockwise: false)
          ..lineTo(size.width, size.height - cornerLen),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
