import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/chick_reservation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'services/chick_notification_service.dart';
import 'services/chick_queue_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppSettingsService.instance.load();

  await ChickNotificationService.instance.initialize();

  final platformBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  final initialBrightness = switch (AppSettingsService.instance.themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platformBrightness,
  };

  final initialTheme = initialBrightness == Brightness.dark
      ? AppTheme.dark
      : AppTheme.light;

  SystemChrome.setSystemUIOverlayStyle(
    _systemUiStyle(
      backgroundColor: initialTheme.scaffoldBackgroundColor,
      brightness: initialBrightness,
    ),
  );

  runApp(const MomBizApp());
}

SystemUiOverlayStyle _systemUiStyle({
  required Color backgroundColor,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;

  final baseStyle = isDark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;

  return baseStyle.copyWith(
    statusBarColor: backgroundColor,

    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,

    systemNavigationBarColor: backgroundColor,

    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,

    systemNavigationBarDividerColor: Colors.transparent,
  );
}

class MomBizApp extends StatelessWidget {
  const MomBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'MomBiz',

          debugShowCheckedModeBanner: false,

          locale: AppSettingsService.instance.locale,

          localizationsDelegates: AppLocalizations.localizationsDelegates,

          supportedLocales: AppLocalizations.supportedLocales,

          theme: AppTheme.light,

          darkTheme: AppTheme.dark,

          themeMode: AppSettingsService.instance.themeMode,

          builder: (context, child) {
            final theme = Theme.of(context);

            final style = _systemUiStyle(
              backgroundColor: theme.scaffoldBackgroundColor,
              brightness: theme.brightness,
            );

            SystemChrome.setSystemUIOverlayStyle(style);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: style,
              child: child ?? const SizedBox.shrink(),
            );
          },

          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const String _notificationPermissionAskedKey =
      'notification_permission_asked_v1';

  bool _permissionCheckScheduled = false;

  void _scheduleNotificationPermissionCheck() {
    if (_permissionCheckScheduled) {
      return;
    }

    _permissionCheckScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();

        final alreadyAsked =
            preferences.getBool(_notificationPermissionAskedKey) ?? false;

        if (alreadyAsked) {
          return;
        }

        await ChickNotificationService.instance.requestPermission();

        await preferences.setBool(_notificationPermissionAskedKey, true);
      } catch (_) {
        // Notification permission problems
        // must never prevent MomBiz from opening.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          _scheduleNotificationPermissionCheck();

          return _SignedInHome(key: ValueKey(user.uid));
        }

        return const LoginScreen();
      },
    );
  }
}

class _SignedInHome extends StatefulWidget {
  const _SignedInHome({super.key});

  @override
  State<_SignedInHome> createState() => _SignedInHomeState();
}

class _SignedInHomeState extends State<_SignedInHome> {
  late final StreamSubscription<List<ChickReservation>>
  _reservationSubscription;

  List<ChickReservation>? _latestReservations;

  late String _lastLanguageCode;

  Future<void> _notificationSyncQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();

    _lastLanguageCode = AppSettingsService.instance.locale.languageCode;

    // Watch MomBiz settings so changing
    // English <-> Khmer rebuilds existing
    // scheduled chick reminders.
    AppSettingsService.instance.addListener(_onAppSettingsChanged);

    // Keep reminders synchronized with Firestore.
    _reservationSubscription = ChickQueueService.instance
        .watchReservations()
        .listen(
          _onReservationsChanged,
          onError: (_) {
            // Notification syncing must never stop
            // the rest of MomBiz from working.
          },
        );
  }

  void _onReservationsChanged(List<ChickReservation> reservations) {
    _latestReservations = List<ChickReservation>.from(reservations);

    _queueNotificationSync(_latestReservations!);
  }

  void _onAppSettingsChanged() {
    final newLanguageCode = AppSettingsService.instance.locale.languageCode;

    // Ignore theme changes and other settings.
    if (newLanguageCode == _lastLanguageCode) {
      return;
    }

    _lastLanguageCode = newLanguageCode;

    final reservations = _latestReservations;

    if (reservations == null) {
      return;
    }

    // Cancel old scheduled reminders and rebuild
    // them using the newly selected language.
    _queueNotificationSync(reservations);
  }

  void _queueNotificationSync(List<ChickReservation> reservations) {
    final snapshot = List<ChickReservation>.from(reservations);

    // Run notification updates one after another.
    // This prevents English/Khmer rescheduling
    // operations from racing each other.
    _notificationSyncQueue = _notificationSyncQueue.then((_) async {
      try {
        await ChickNotificationService.instance.syncReservations(snapshot);
      } catch (_) {
        // Scheduling problems must never affect
        // the Chick Queue itself.
      }
    });
  }

  @override
  void dispose() {
    AppSettingsService.instance.removeListener(_onAppSettingsChanged);

    _reservationSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
