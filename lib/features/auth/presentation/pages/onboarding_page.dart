import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:bonvo/config/themes/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.local_offer_rounded,
      title: 'Tus compras\nahora valen más',
      subtitle:
          'Acumula puntos en cada visita y canjéalos por promociones exclusivas de tus negocios favoritos.',
    ),
    _PageData(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Escanea y\ngana puntos',
      subtitle:
          'Muestra tu QR personal en caja para acumular puntos automáticamente con cada compra.',
    ),
    _PageData(
      icon: Icons.card_giftcard_rounded,
      title: 'Canjea tus\nrecompensas',
      subtitle:
          'Accede a descuentos y ofertas exclusivas en tus tiendas favoritas.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.gradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Slides
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => _Slide(data: _pages[i]),
                    ),
                  ),

                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => _Dot(active: i == _currentPage),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Botón Empezar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Empezar',
                          style: TextStyle(
                            color: AppColors.primaryDeep,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ya tengo cuenta · Inicia sesión
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        children: [
                          TextSpan(text: 'Ya tengo cuenta  ·  '),
                          TextSpan(
                            text: 'Inicia sesión',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────
class _Slide extends StatelessWidget {
  final _PageData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono en recuadro translúcido
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(data.icon, color: Colors.white, size: 64),
          ),

          const SizedBox(height: 48),

          // Título w800 a 2 líneas
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 16),

          // Subtítulo
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
