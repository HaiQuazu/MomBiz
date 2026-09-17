import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor =
      Color(0xFF28764F);

  static ThemeData get light {
    return _buildTheme(
      Brightness.light,
    );
  }

  static ThemeData get dark {
    return _buildTheme(
      Brightness.dark,
    );
  }

  static ThemeData _buildTheme(
    Brightness brightness,
  ) {
    final colorScheme =
        ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final textTheme =
        _buildTextTheme(
      base.textTheme,
    );

    final primaryTextTheme =
        _buildTextTheme(
      base.primaryTextTheme,
    );

    return base.copyWith(
      // -----------------------------
      // GLOBAL KHMER-FRIENDLY FONT
      // -----------------------------
      textTheme: textTheme,
      primaryTextTheme:
          primaryTextTheme,

      // -----------------------------
      // BACKGROUND
      // -----------------------------
      scaffoldBackgroundColor:
          colorScheme.surface,

      // -----------------------------
      // APP BAR
      // -----------------------------
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor:
            colorScheme.surface,
        foregroundColor:
            colorScheme.onSurface,
      ),

      // -----------------------------
      // CARDS
      // -----------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme
            .surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),
      ),

      // -----------------------------
      // INPUT FIELDS
      // -----------------------------
      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor: colorScheme
            .surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide: BorderSide(
            color:
                colorScheme.primary,
            width: 1.6,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide: BorderSide(
            color:
                colorScheme.error,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide: BorderSide(
            color:
                colorScheme.error,
            width: 1.6,
          ),
        ),
      ),

      // -----------------------------
      // FILLED BUTTON
      // -----------------------------
      filledButtonTheme:
          FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
          minimumSize:
              const Size.fromHeight(
            52,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),

      // -----------------------------
      // OUTLINED BUTTON
      // -----------------------------
      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
          minimumSize:
              const Size.fromHeight(
            52,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),

      // -----------------------------
      // TEXT BUTTON
      // -----------------------------
      textButtonTheme:
          TextButtonThemeData(
        style:
            TextButton.styleFrom(),
      ),

      // -----------------------------
      // FLOATING ACTION BUTTON
      //
      // No extendedTextStyle here.
      // This avoids the TextStyle
      // interpolation exception.
      // -----------------------------
      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        elevation: 2,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
      ),

      // -----------------------------
      // BOTTOM NAVIGATION
      // -----------------------------
      navigationBarTheme:
          NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor:
            colorScheme.surface,
        indicatorColor: colorScheme
            .primaryContainer,
        labelTextStyle:
            WidgetStateProperty
                .resolveWith(
          (states) {
            return TextStyle(
              fontFamily:
                  GoogleFonts
                      .notoSansKhmer()
                      .fontFamily,
              fontSize: 12,
              height: 1.25,
              fontWeight:
                  states.contains(
                WidgetState.selected,
              )
                      ? FontWeight.w600
                      : FontWeight.w400,
            );
          },
        ),
      ),

      // -----------------------------
      // DIALOG
      // -----------------------------
      dialogTheme:
          DialogThemeData(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            24,
          ),
        ),
      ),

      // -----------------------------
      // BOTTOM SHEET
      // -----------------------------
      bottomSheetTheme:
          BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor:
            colorScheme.surface,
        shape:
            const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(28),
          ),
        ),
      ),

      // -----------------------------
      // DIVIDER
      // -----------------------------
      dividerTheme:
          DividerThemeData(
        color: colorScheme
            .outlineVariant
            .withValues(
          alpha: 0.6,
        ),
      ),

      // -----------------------------
      // SNACKBAR
      // -----------------------------
      snackBarTheme:
          SnackBarThemeData(
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextTheme base,
  ) {
    final khmerTheme =
        GoogleFonts
            .notoSansKhmerTextTheme(
      base,
    );

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
        fontWeight:
            weight ??
            original.fontWeight,
      );
    }

    return khmerTheme.copyWith(
      // ---------------------------
      // DISPLAY
      // ---------------------------
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

      // ---------------------------
      // HEADINGS
      // ---------------------------
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

      // ---------------------------
      // TITLES
      // ---------------------------
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

      // ---------------------------
      // NORMAL TEXT
      // ---------------------------
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

      // ---------------------------
      // LABELS / BUTTONS
      // ---------------------------
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
