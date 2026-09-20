import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_icons.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // MOMBiz MASTER GREEN
  // ============================================================

  static const Color _seedColor = Color(0xFF28764F);

  static ThemeData get light {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get dark {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final textTheme = _buildTextTheme(base.textTheme);

    final primaryTextTheme = _buildTextTheme(base.primaryTextTheme);

    return base.copyWith(
      // ========================================================
      // TYPOGRAPHY
      // ========================================================
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,

      // ========================================================
      // GLOBAL ICONS
      // ========================================================
      iconTheme: IconThemeData(color: colorScheme.onSurface),

      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) {
          return const Icon(AppIcons.back, size: 23);
        },
      ),

      // ========================================================
      // PAGE BACKGROUND
      // ========================================================
      scaffoldBackgroundColor: colorScheme.surface,

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 23),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
      ),

      // ========================================================
      // CARDS
      // ========================================================
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        prefixIconColor: colorScheme.primary,

        suffixIconColor: colorScheme.onSurfaceVariant,

        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),

        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),

        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ========================================================
      // FLOATING ACTION BUTTON
      //
      // Important:
      // Keep extendedTextStyle unset.
      // This avoids the previous TextStyle interpolation issue.
      // ========================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 3,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ========================================================
      // SEARCH BAR
      // ========================================================
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerLow,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.bodyLarge),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,

        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(
            size: 22,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            fontFamily: GoogleFonts.notoSansKhmer().fontFamily,
            fontSize: 12,
            height: 1.25,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
      ),

      // ========================================================
      // POPUP MENUS
      // ========================================================
      popupMenuTheme: PopupMenuThemeData(
        elevation: 6,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.bodyMedium,
      ),

      // ========================================================
      // DIALOGS
      // ========================================================
      dialogTheme: DialogThemeData(
        elevation: 4,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // ========================================================
      // BOTTOM SHEETS
      //
      // Fixed form save areas should NOT show a drag handle.
      // Modal picker sheets explicitly request one themselves.
      // ========================================================
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.60),
        thickness: 1,
      ),

      // ========================================================
      // SNACKBARS
      // ========================================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ============================================================
  // KHMER-FRIENDLY TEXT THEME
  // ============================================================

  static TextTheme _buildTextTheme(TextTheme base) {
    final khmerTheme = GoogleFonts.notoSansKhmerTextTheme(base);

    TextStyle? makeStyle(
      TextStyle? original, {
      double? height,
      FontWeight? weight,
    }) {
      if (original == null) {
        return null;
      }

      return original.copyWith(
        height: height,
        fontWeight: weight ?? original.fontWeight,
      );
    }

    return khmerTheme.copyWith(
      // ======================================================
      // DISPLAY
      // ======================================================
      displayLarge: makeStyle(
        khmerTheme.displayLarge,
        height: 1.15,
        weight: FontWeight.w700,
      ),

      displayMedium: makeStyle(
        khmerTheme.displayMedium,
        height: 1.15,
        weight: FontWeight.w700,
      ),

      displaySmall: makeStyle(
        khmerTheme.displaySmall,
        height: 1.18,
        weight: FontWeight.w700,
      ),

      // ======================================================
      // HEADINGS
      // ======================================================
      headlineLarge: makeStyle(
        khmerTheme.headlineLarge,
        height: 1.20,
        weight: FontWeight.w700,
      ),

      headlineMedium: makeStyle(
        khmerTheme.headlineMedium,
        height: 1.22,
        weight: FontWeight.w700,
      ),

      headlineSmall: makeStyle(
        khmerTheme.headlineSmall,
        height: 1.24,
        weight: FontWeight.w700,
      ),

      // ======================================================
      // TITLES
      // ======================================================
      titleLarge: makeStyle(
        khmerTheme.titleLarge,
        height: 1.22,
        weight: FontWeight.w600,
      ),

      titleMedium: makeStyle(
        khmerTheme.titleMedium,
        height: 1.25,
        weight: FontWeight.w600,
      ),

      titleSmall: makeStyle(
        khmerTheme.titleSmall,
        height: 1.25,
        weight: FontWeight.w600,
      ),

      // ======================================================
      // BODY
      // ======================================================
      bodyLarge: makeStyle(
        khmerTheme.bodyLarge,
        height: 1.35,
        weight: FontWeight.w400,
      ),

      bodyMedium: makeStyle(
        khmerTheme.bodyMedium,
        height: 1.35,
        weight: FontWeight.w400,
      ),

      bodySmall: makeStyle(
        khmerTheme.bodySmall,
        height: 1.32,
        weight: FontWeight.w400,
      ),

      // ======================================================
      // LABELS / BUTTONS
      // ======================================================
      labelLarge: makeStyle(
        khmerTheme.labelLarge,
        height: 1.28,
        weight: FontWeight.w600,
      ),

      labelMedium: makeStyle(
        khmerTheme.labelMedium,
        height: 1.28,
        weight: FontWeight.w500,
      ),

      labelSmall: makeStyle(
        khmerTheme.labelSmall,
        height: 1.25,
        weight: FontWeight.w500,
      ),
    );
  }
}
