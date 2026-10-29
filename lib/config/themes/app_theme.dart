import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════
// COLORES — paleta Creatrixweb (negro, blanco y púrpura)
// ══════════════════════════════════════════════════════════
class AppColors {
  // Brand primario: --violet, --violet-dark y púrpura medio del Hero
  static const primary = Color(0xFF7C3AED);
  static const primaryDeep = Color(0xFF5B21B6);
  static const primaryLight = Color(0xFF9B6BFF);

  // Acento de puntos/cashback: bloques oscuros (--ink y #2a2a27).
  // Se mantienen los nombres "amber" por compatibilidad con el código.
  static const amber = Color(0xFF2A2A27);
  static const amberTint = Color(0xFFECECEC);
  static const amberText = Color(0xFF0F0F0E);

  // Tintes de marca: --violet-claro (los nombres "green" son heredados)
  static const greenTint = Color(0xFFEDE5FF);
  static const greenBorder = Color(0xFFD9C8FF);

  // Lilas para usar sobre fondos oscuros
  static const lilac = Color(0xFFB794FF);
  static const lilacLight = Color(0xFFC4A6FF);

  // Superficies: --s1 (hueso cálido), --card y --line
  static const background = Color(0xFFF1F1EC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0E0D8);

  // Texto: --ink, --ink-mut y --mut
  static const textPrimary = Color(0xFF0F0F0E);
  static const textSecondary = Color(0xFF5D5E57);
  static const textMuted = Color(0xFF8B8C84);

  // Estado
  static const error = Color(0xFFE5484D);
  static const success = Color(0xFF7C3AED);

  // Gradiente de marca 145°  #9b6bff → #7c3aed → #5b21b6
  static const gradient = LinearGradient(
    begin: Alignment(-0.7, -1.0),
    end: Alignment(0.7, 1.0),
    colors: [Color(0xFF9B6BFF), Color(0xFF7C3AED), Color(0xFF5B21B6)],
    stops: [0.0, 0.45, 1.0],
  );

  // ── Aliases heredados (compatibilidad con código existente) ──
  static const primaryDark = primaryDeep;
  static const accent = amber;
  static const accentLight = amberTint;
  static const divider = border;
  static const cardBg = surface;
  static const textLight = textMuted;

  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B6BFF), Color(0xFF7C3AED), Color(0xFF5B21B6)],
  );
  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B6BFF), Color(0xFF7C3AED)],
  );
  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A27), Color(0xFF0F0F0E)],
  );
}

// ══════════════════════════════════════════════════════════
// RADIOS
// ══════════════════════════════════════════════════════════
class AppRadius {
  static const double cardLg = 24.0;
  static const double card = 20.0;
  static const double button = 14.0;
  static const double chip = 20.0;
  static const double input = 13.0;
  static const double icon = 12.0;
  static const double sm = 8.0;
}

// ══════════════════════════════════════════════════════════
// ESPACIADOS
// ══════════════════════════════════════════════════════════
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets card = EdgeInsets.all(18);
}

// ══════════════════════════════════════════════════════════
// SOMBRAS
// ══════════════════════════════════════════════════════════
class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x1A101828),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -12,
    ),
  ];

  static const button = [
    BoxShadow(
      color: Color(0x667C3AED),
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -10,
    ),
  ];
}

// ══════════════════════════════════════════════════════════
// ICONOGRAFÍA — Material Icons outlined (línea, sin deps externas)
// ══════════════════════════════════════════════════════════
class AppIcons {
  // ── Navegación ──────────────────────────────────────────
  static const home        = Icons.home_outlined;
  static const dashboard   = Icons.grid_view;
  static const clients     = Icons.group_outlined;
  static const promotions  = Icons.label_outlined;
  static const profile     = Icons.person_outlined;
  static const store       = Icons.storefront;
  static const tiendas     = Icons.storefront;

  // ── Acciones ────────────────────────────────────────────
  static const scanner     = Icons.qr_code_scanner;
  static const search      = Icons.search;
  static const searchOff   = Icons.search_off;
  static const settings    = Icons.settings_outlined;
  static const refresh     = Icons.refresh;
  static const plus        = Icons.add;
  static const minus       = Icons.remove;
  static const back        = Icons.arrow_back;
  static const close       = Icons.close;
  static const edit        = Icons.edit_outlined;
  static const delete      = Icons.delete_outline;
  static const upload      = Icons.upload;
  static const image       = Icons.image_outlined;
  static const camera      = Icons.camera_alt_outlined;
  static const signOut     = Icons.logout;
  static const history     = Icons.receipt_long_outlined;
  static const info        = Icons.info_outline;
  static const configure   = Icons.tune;
  static const backspace   = Icons.backspace;
  static const plusCircle  = Icons.add_circle_outline;
  static const minusCircle = Icons.remove_circle_outline;
  static const mail        = Icons.mail_outline;
  static const lock        = Icons.lock_outline;
  static const eye         = Icons.visibility;
  static const eyeOff      = Icons.visibility_off;

  // ── Puntos / fidelización ───────────────────────────────
  static const star        = Icons.star_border;
  static const gift        = Icons.card_giftcard_outlined;
  static const ticket      = Icons.confirmation_number_outlined;
  static const coins       = Icons.monetization_on_outlined;
  static const bell        = Icons.notifications_none;
  static const percent     = Icons.percent;

  // ── Estado ──────────────────────────────────────────────
  static const check       = Icons.check;
  static const checkCircle = Icons.check_circle_outline;
  static const warning     = Icons.warning_amber;
  static const verified    = Icons.verified;

  // ── Categorías de promo ─────────────────────────────────
  static const cafe        = Icons.local_cafe;
  static const restaurant  = Icons.restaurant;
}

// ══════════════════════════════════════════════════════════
// TEMA CENTRAL
// ══════════════════════════════════════════════════════════
class AppTheme {
  static TextTheme _buildTextTheme() {
    return GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: AppColors.textPrimary),
        headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary),
        headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary),
        headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary),
        titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary),
        titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
        bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
        labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData lightTheme() {
    final textTheme = _buildTextTheme();

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.greenTint,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.amber,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.amberTint,
      onSecondaryContainer: AppColors.amberText,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      outline: AppColors.border,
      outlineVariant: Color(0xFFDEDED6),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFDEDED6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFDEDED6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: const BorderSide(color: AppColors.border),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.greenTint,
        labelStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13),
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
