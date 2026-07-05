import 'package:flutter/material.dart';

/// Design tokens for Jejak — an energetic orange, Inter, flat cards.
abstract class AppColors {
  static const primary = Color(0xFFFC4C02);
  static const primaryDark = Color(0xFFE44500);
  static const backgroundLight = Color(0xFFF7F7F5);
  static const backgroundDark = Color(0xFF15130F);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF221F1A);
  static const textMain = Color(0xFF1F2328);
  static const textSub = Color(0xFF6B7280);
  static const borderLight = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF35312A);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF16A34A);
}

abstract class AppTheme {
  static const _fontFamily = 'Inter';
  static const _radiusControl = 8.0;
  static const _radiusCard = 12.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMain = isDark ? Colors.white : AppColors.textMain;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: card,
      onSurface: textMain,
      error: AppColors.danger,
      outline: border,
      outlineVariant: border,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true, fontFamily: _fontFamily);
    final textTheme = base.textTheme
        .apply(fontFamily: _fontFamily, bodyColor: textMain, displayColor: textMain);

    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: color, width: width),
        );

    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl));
    const controlSize = Size.fromHeight(48);
    final boldLabel = TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700, fontSize: 15);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textMain,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: textMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: controlSize,
          shape: controlShape,
          textStyle: boldLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          minimumSize: controlSize,
          shape: controlShape,
          side: BorderSide(color: border, width: 1.5),
          textStyle: boldLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: boldLabel),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 2),
        labelStyle: const TextStyle(color: AppColors.textSub, fontFamily: _fontFamily),
        hintStyle: const TextStyle(color: AppColors.textSub, fontFamily: _fontFamily),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        selectedColor: AppColors.primary,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl)),
        labelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: textMain),
        secondaryLabelStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl)),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.textSub),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
