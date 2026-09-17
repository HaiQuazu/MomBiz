import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppSettingsService.instance.load();

  // Apply the correct system-bar style immediately,
  // before the first MomBiz screen is displayed.
  final platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  final initialBrightness =
      switch (AppSettingsService.instance.themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platformBrightness,
  };

  final initialTheme =
      initialBrightness == Brightness.dark
          ? AppTheme.dark
          : AppTheme.light;

  SystemChrome.setSystemUIOverlayStyle(
    _systemUiStyle(
      backgroundColor:
          initialTheme.scaffoldBackgroundColor,
      brightness: initialBrightness,
    ),
  );

  runApp(
    const MomBizApp(),
  );
}

SystemUiOverlayStyle _systemUiStyle({
  required Color backgroundColor,
  required Brightness brightness,
}) {
  final isDark =
      brightness == Brightness.dark;

  final baseStyle =
      isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark;

  return baseStyle.copyWith(
    // Top Android status bar
    statusBarColor:
        backgroundColor,

    statusBarIconBrightness:
        isDark
            ? Brightness.light
            : Brightness.dark,

    // Bottom Android system navigation area
    systemNavigationBarColor:
        backgroundColor,

    systemNavigationBarIconBrightness:
        isDark
            ? Brightness.light
            : Brightness.dark,

    systemNavigationBarDividerColor:
        Colors.transparent,
  );
}

class MomBizApp extends StatelessWidget {
  const MomBizApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          AppSettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'MomBiz',
          debugShowCheckedModeBanner:
              false,

          locale:
              AppSettingsService
                  .instance
                  .locale,

          localizationsDelegates:
              AppLocalizations
                  .localizationsDelegates,

          supportedLocales:
              AppLocalizations
                  .supportedLocales,

          theme:
              AppTheme.light,

          darkTheme:
              AppTheme.dark,

          themeMode:
              AppSettingsService
                  .instance
                  .themeMode,

          // Keeps the Android status bar correct
          // when switching between Light/Dark/System.
          builder: (context, child) {
            final theme =
                Theme.of(context);

            final style =
                _systemUiStyle(
              backgroundColor:
                  theme.scaffoldBackgroundColor,
              brightness:
                  theme.brightness,
            );

            SystemChrome
                .setSystemUIOverlayStyle(
              style,
            );

            return AnnotatedRegion<
                SystemUiOverlayStyle>(
              value: style,
              child:
                  child ??
                  const SizedBox.shrink(),
            );
          },

          home:
              const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          AuthService
              .instance
              .authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
