import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/services/storage_service.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/promotions/domain/entities/promotion.dart';
import 'package:bonvo/features/promotions/domain/repositories/promotions_repository.dart';
import 'package:bonvo/injection/injection.dart';

class CreatePromotionPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const CreatePromotionPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<CreatePromotionPage> createState() => _CreatePromotionPageState();
}

class _CreatePromotionPageState extends State<CreatePromotionPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _pointsCost = 100;
  bool _sendPush = true;
  bool _publishing = false;
  String? _bannerBase64;
  bool _pickingBanner = false;
  int _clientCount = 0;

  @override
  void initState() {
    super.initState();
    _loadClientCount();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClientCount() async {
    final result =
        await getIt<BusinessRepository>().getBusinessStats(widget.businessId);
    result.fold(
      (_) {},
      (stats) {
        if (mounted) setState(() => _clientCount = stats.uniqueClients);
      },
    );
  }

  Future<void> _pickBanner() async {
    setState(() => _pickingBanner = true);
    try {
      final base64 = await getIt<StorageService>().pickBannerImage();
      if (base64 != null && mounted) {
        setState(() => _bannerBase64 = base64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _pickingBanner = false);
    }
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Agrega un título a la promoción'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _publishing = true);

    final promo = Promotion(
      id: '',
      businessId: widget.businessId,
      businessName: widget.businessName,
      title: title,
      description: _descCtrl.text.trim(),
      pointsCost: _pointsCost,
      active: true,
      createdAt: DateTime.now(),
      imageBase64: _bannerBase64,
    );

    final result =
        await getIt<PromotionsRepository>().createPromotion(promo);

    if (!mounted) return;

    await result.fold(
      (f) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) async {
        if (_sendPush) {
          final desc = _descCtrl.text.trim();
          final String pushBody;
          if (_pointsCost > 0) {
            pushBody = desc.isNotEmpty
                ? 'Canjea $title por solo $_pointsCost pts. $desc'
                : 'Canjea $title por solo $_pointsCost pts.';
          } else {
            pushBody = desc.isNotEmpty ? '$title · $desc' : '¡Promoción gratuita disponible!';
          }
          await FirebaseFirestore.instance
              .collection('businesses')
              .doc(widget.businessId)
              .collection('announcements')
              .add({
            'title': '🎁 ¡Nueva promo en ${widget.businessName}!',
            'body': pushBody,
            'sentAt': FieldValue.serverTimestamp(),
          });
        }
        if (mounted) context.pop(true);
      },
    );

    if (mounted) setState(() => _publishing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(AppIcons.back,
                          color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Nueva promoción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Formulario ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner
                  const _SectionLabel('Imagen del banner'),
                  const SizedBox(height: 8),
                  _BannerUploader(
                    base64: _bannerBase64,
                    loading: _pickingBanner,
                    onTap: _pickBanner,
                  ),

                  const SizedBox(height: 20),

                  // Título
                  const _SectionLabel('Título'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Café americano gratis',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  const _SectionLabel('Descripción'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Válido para cualquier café de la carta. Un canje por cliente.',
                      fillColor: Colors.white,
                      filled: true,
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Costo en puntos
                  const _SectionLabel('Costo en puntos'),
                  const SizedBox(height: 8),
                  _PointsSelector(
                    value: _pointsCost,
                    onDecrement: _pointsCost >= 50
                        ? () =>
                            setState(() => _pointsCost -= 50)
                        : null,
                    onIncrement: () =>
                        setState(() => _pointsCost += 50),
                  ),

                  const SizedBox(height: 16),

                  // Toggle push
                  _PushToggle(
                    clientCount: _clientCount,
                    value: _sendPush,
                    onChanged: (v) => setState(() => _sendPush = v),
                  ),

                  const SizedBox(height: 28),

                  // Botón publicar
                  GestureDetector(
                    onTap: _publishing ? null : _publish,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                        boxShadow: AppShadows.button,
                      ),
                      alignment: Alignment.center,
                      child: _publishing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white),
                            )
                          : const Text(
                              'Publicar promoción',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _BannerUploader extends StatelessWidget {
  final String? base64;
  final bool loading;
  final VoidCallback onTap;

  const _BannerUploader({
    required this.base64,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: SizedBox(
        height: 120,
        child: Stack(
          children: [
            // Dashed border
            CustomPaint(
              painter: const _DashedBorderPainter(
                color: AppColors.border,
                radius: AppRadius.card,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppRadius.card),
                child: base64 != null
                    ? Image.memory(
                        base64Decode(base64!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          // Diagonal hatch fill
                          CustomPaint(
                              painter: _HatchPainter()),
                          Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.image,
                                  size: 32,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subir imagen 16:9',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (loading)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppRadius.card),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child:
                      const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (base64 != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double strokeWidth = 1.5;
  static const double dashLen = 7;
  static const double gapLen = 5;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final step = draw ? dashLen : gapLen;
        final end = (dist + step).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, end), paint);
        }
        dist += step;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCDCD6)
      ..strokeWidth = 1;
    const spacing = 14.0;
    for (double i = -size.height;
        i < size.width + size.height;
        i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}

// ──────────────────────────────────────────────────────────────
class _PointsSelector extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _PointsSelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Valor
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const TextSpan(
                  text: ' pts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Botón −
          _PtsBtn(
            icon: AppIcons.minus,
            iconColor: AppColors.textSecondary,
            bgColor: const Color(0xFFF3F3EE),
            onTap: onDecrement,
          ),
          const SizedBox(width: 10),
          // Botón +
          _PtsBtn(
            icon: AppIcons.plus,
            iconColor: Colors.white,
            bgColor: AppColors.primary,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _PtsBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _PtsBtn({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF3F3EE).withValues(alpha: 0.5)
              : bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? AppColors.textMuted.withValues(alpha: 0.4)
              : iconColor,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _PushToggle extends StatelessWidget {
  final int clientCount;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PushToggle({
    required this.clientCount,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(AppIcons.bell,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              clientCount > 0
                  ? 'Enviar push a $clientCount clientes'
                  : 'Enviar notificación push',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.greenTint,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
