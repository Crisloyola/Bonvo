import 'package:flutter/material.dart';

class Breakpoints {
  /// A partir de este ancho se usa el diseño de escritorio.
  static const double wide = 900;

  /// Ancho de la columna tipo app para pantallas sin diseño de escritorio.
  static const double mobileFrame = 520;
}

extension ResponsiveContext on BuildContext {
  bool get isWide => MediaQuery.sizeOf(this).width >= Breakpoints.wide;
}

/// Rutas que tienen diseño propio para pantallas anchas.
const wideLayoutRoutes = {
  '/login',
  '/register',
  '/business/home',
  '/business/clients',
  '/business/promotions',
  '/client/home',
  '/client/tiendas',
  '/client/promotions',
  '/client/store',
  '/business/requests',
  '/business/programs',
};

/// Envuelve cada página: en pantallas anchas la centra en una columna tipo
/// app, salvo las que tienen diseño de escritorio ([fullWidth]).
class ResponsiveFrame extends StatelessWidget {
  final bool fullWidth;
  final Widget child;

  const ResponsiveFrame({
    super.key,
    required this.fullWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final framed = screenWidth > Breakpoints.mobileFrame &&
        !(fullWidth && screenWidth >= Breakpoints.wide);
    final width = framed ? Breakpoints.mobileFrame : screenWidth;

    return ColoredBox(
      color: const Color(0xFFDEDED6),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: framed
                ? const [
                    BoxShadow(
                      color: Color(0x1F101828),
                      blurRadius: 40,
                      spreadRadius: -8,
                    ),
                  ]
                : const [],
          ),
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: mq.copyWith(size: Size(width, mq.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula simple: reparte [children] en tantas columnas como quepan
/// con al menos [minItemWidth] de ancho cada una. Las filas se ajustan al
/// alto de su contenido.
class ResponsiveWrapGrid extends StatelessWidget {
  final double minItemWidth;
  final double spacing;

  /// Separación vertical entre filas; por defecto igual a [spacing].
  final double? runSpacing;
  final List<Widget> children;

  const ResponsiveWrapGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.spacing = 12,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cols =
            ((maxW + spacing) / (minItemWidth + spacing)).floor().clamp(1, 6);
        final itemW = (maxW - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: [
            for (final c in children) SizedBox(width: itemW, child: c),
          ],
        );
      },
    );
  }
}
