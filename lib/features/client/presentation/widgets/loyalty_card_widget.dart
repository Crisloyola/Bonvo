import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bonvo/config/themes/app_theme.dart';

class LoyaltyCardWidget extends StatelessWidget {
  final String userId;
  final String userName;
  final int points;
  final VoidCallback? onTapQr;

  const LoyaltyCardWidget({
    super.key,
    required this.userId,
    required this.userName,
    required this.points,
    this.onTapQr,
  });

  String get _fid {
    final s = userId.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '');
    return s.length >= 4
        ? s.substring(s.length - 4).toUpperCase()
        : s.toUpperCase();
  }

  String _formatPoints(int pts) {
    if (pts >= 1000) {
      final thousands = pts ~/ 1000;
      final remainder = (pts % 1000).toString().padLeft(3, '0');
      return '$thousands,$remainder';
    }
    return '$pts';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.cardLg)),
        boxShadow: [
          BoxShadow(
            color: Color(0x55059669),
            blurRadius: 28,
            offset: Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: puntos + QR ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus puntos',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPoints(points),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR en recuadro blanco
                  GestureDetector(
                    onTap: onTapQr,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: userId,
                        version: QrVersions.auto,
                        size: 76,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Separador
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),

              const SizedBox(height: 14),

              // ── Fila inferior: info miembro ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MIEMBRO',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '#FID-$_fid',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
