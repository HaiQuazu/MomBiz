import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A bottom action area that stays above:
/// - Android 3-button navigation
/// - gesture navigation insets
/// - the on-screen keyboard
///
/// Some Android/OEM combinations report a zero bottom safe-area while
/// still drawing the 3-button navigation bar over the Flutter window.
/// In that case MomBiz uses a small Android-only fallback inset.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.child,
    this.horizontalPadding = 20,
    this.topPadding = 12,
    this.bottomSpacing = 12,
    this.androidNavigationFallback = 40,
  });

  final Widget child;

  final double horizontalPadding;
  final double topPadding;
  final double bottomSpacing;

  /// Used only on Android when Flutter reports no bottom system inset.
  final double androidNavigationFallback;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final keyboardInset = media.viewInsets.bottom;

    final reportedSystemInset = math.max(
      media.padding.bottom,
      math.max(
        media.viewPadding.bottom,
        media.systemGestureInsets.bottom,
      ),
    );

    final isAndroid =
        Theme.of(context).platform == TargetPlatform.android;

    final systemInset =
        isAndroid && reportedSystemInset < 1
            ? androidNavigationFallback
            : reportedSystemInset;

    // When the keyboard is visible it occupies the bottom of the screen.
    // Put the action immediately above it. Otherwise reserve the system
    // navigation area.
    final bottomInset =
        keyboardInset > 0 ? keyboardInset : systemInset;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomInset + bottomSpacing,
        ),
        child: child,
      ),
    );
  }
}
