import 'package:flutter/material.dart';

/// Neutral zinc theme. 1:1 with `design/css/tokens.css`.
class AppTheme {
  static const bg = Color(0xFF131315);
  static const surface = Color(0xFF1B1C1F);
  static const card = Color(0xFF222326);
  static const card2 = Color(0xFF2C2D31);
  static const border = Color(0xFF343639);
  static const text = Color(0xFFF4F4F5);
  static const muted = Color(0xFFA1A1AA);
  static const faint = Color(0xFF71717A);
  static const primary = Color(0xFFFAFAFA);
  static const onPrimary = Color(0xFF131315);
  static const primarySoft = Color(0x1FFAFAFA);

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: bg,
      surfaceContainer: card,
      primary: primary,
      onPrimary: onPrimary,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary,
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: text, size: 20);
          }
          return const IconThemeData(color: muted, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: text);
          }
          return style.copyWith(color: muted);
        }),
      ),
      textTheme: const TextTheme(
        // .t-hero
        headlineSmall: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.2,
        ),
        // .t-section
        titleLarge: TextStyle(
          fontSize: 17,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.2,
        ),
        // .t-title
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        // .t-body
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.65,
          fontWeight: FontWeight.w400,
          color: Color(0xFFD4D4D8),
        ),
        // .t-meta
        labelMedium: TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        // chips + small buttons (single 13/600 style)
        labelLarge: TextStyle(
          fontSize: 13,
          height: 1.0,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: onPrimary,
          letterSpacing: 0.6,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: border),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
