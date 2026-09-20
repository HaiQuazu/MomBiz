import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/chick_notification_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../theme/app_icons.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import '../queue/chick_queue_screen.dart';
import '../sales/sale_form_screen.dart';
import '../settings/exchange_rate_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  StreamSubscription<bool>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();

    _notificationTapSubscription = ChickNotificationService
        .instance
        .queueOpenRequests
        .listen((_) {
          ChickNotificationService.instance.consumePendingQueueOpenRequest();

          _openQueue();
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ExchangeRateService.instance.refreshIfNeeded();

      final shouldOpenQueue = ChickNotificationService.instance
          .consumePendingQueueOpenRequest();

      if (shouldOpenQueue) {
        _openQueue();
      }
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openNewSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SaleFormScreen()),
    );
  }

  void _openCustomers() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openQueue() {
    if (!mounted || _selectedIndex == 2) {
      return;
    }

    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      DashboardScreen(
        onCustomersTap: _openCustomers,
        onNewSaleTap: _openNewSale,
      ),
      const CustomersScreen(),
      const ChickQueueScreen(),
      const _MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(AppIcons.home, size: 21),
            selectedIcon: const Icon(AppIcons.home, size: 22),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.customers, size: 21),
            selectedIcon: const Icon(AppIcons.customers, size: 22),
            label: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.queue, size: 21),
            selectedIcon: const Icon(AppIcons.queue, size: 22),
            label: l10n.queue,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.more, size: 21),
            selectedIcon: const Icon(AppIcons.more, size: 22),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  String _text(BuildContext context, {required String en, required String km}) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return languageCode == 'km' ? km : en;
  }

  String _profileName() {
    final user = AuthService.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim() ?? '';

    if (email.isNotEmpty) {
      final beforeAt = email.split('@').first.trim();

      if (beforeAt.isNotEmpty) {
        return beforeAt;
      }
    }

    return 'MomBiz';
  }

  String _profileEmail() {
    return AuthService.instance.currentUser?.email?.trim() ?? '';
  }

  String _profileInitial(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'M';
    }

    return trimmed[0].toUpperCase();
  }

  Widget _fallbackAvatar(BuildContext context, String name) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        _profileInitial(name),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _profileAvatar(BuildContext context, String name) {
    final photoUrl = AuthService.instance.currentUser?.photoURL?.trim() ?? '';

    if (photoUrl.isEmpty) {
      return _fallbackAvatar(context, name);
    }

    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackAvatar(context, name);
          },
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentLanguage = AppSettingsService.instance.locale.languageCode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        final isKhmer = Localizations.localeOf(context).languageCode == 'km';

        final titleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: titleWeight),
                ),

                const SizedBox(height: 5),

                Text(
                  l10n.chooseLanguage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                _LanguageOption(
                  flag: '🇬🇧',
                  title: l10n.english,
                  selected: currentLanguage == 'en',
                  onTap: () {
                    Navigator.pop(context, 'en');
                  },
                ),

                const SizedBox(height: 4),

                _LanguageOption(
                  flag: '🇰🇭',
                  title: l10n.khmer,
                  selected: currentLanguage == 'km',
                  onTap: () {
                    Navigator.pop(context, 'km');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == currentLanguage) {
      return;
    }

    await AppSettingsService.instance.setLanguage(selected);
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentTheme = AppSettingsService.instance.themeMode;

    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        final isKhmer = Localizations.localeOf(context).languageCode == 'km';

        final titleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.theme,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: titleWeight),
                ),

                const SizedBox(height: 5),

                Text(
                  l10n.chooseTheme,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                _ThemeOption(
                  icon: AppIcons.systemTheme,
                  title: l10n.systemTheme,
                  selected: currentTheme == ThemeMode.system,
                  onTap: () {
                    Navigator.pop(context, ThemeMode.system);
                  },
                ),

                const SizedBox(height: 4),

                _ThemeOption(
                  icon: AppIcons.lightTheme,
                  title: l10n.lightTheme,
                  selected: currentTheme == ThemeMode.light,
                  onTap: () {
                    Navigator.pop(context, ThemeMode.light);
                  },
                ),

                const SizedBox(height: 4),

                _ThemeOption(
                  icon: AppIcons.darkTheme,
                  title: l10n.darkTheme,
                  selected: currentTheme == ThemeMode.dark,
                  onTap: () {
                    Navigator.pop(context, ThemeMode.dark);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == currentTheme) {
      return;
    }

    await AppSettingsService.instance.setThemeMode(selected);
  }

  String _currentThemeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightTheme;

      case ThemeMode.dark:
        return l10n.darkTheme;

      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(AppIcons.signOut, size: 28, color: colors.error),
          title: Text(
            _text(dialogContext, en: 'Sign out?', km: 'ចាកចេញពីគណនី?'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            _text(
              dialogContext,
              en: 'Are you sure you want to sign out of MomBiz?',
              km: 'តើអ្នកប្រាកដថាចង់ចាកចេញពីគណនី MomBiz មែនទេ?',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(_text(dialogContext, en: 'Cancel', km: 'បោះបង់')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.signOut),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final profileWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final languageCode = AppSettingsService.instance.locale.languageCode;

    final currentLanguage = languageCode == 'km' ? l10n.khmer : l10n.english;

    final currentTheme = AppSettingsService.instance.themeMode;

    final profileName = _profileName();

    final profileEmail = _profileEmail();

    const cardRadius = 20.0;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================
          // FIXED HEADER
          // =================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.more,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: headingWeight,
                    ),
                  ),
                ),

                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    AppIcons.more,
                    size: 23,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =================================================
          // SCROLLABLE BODY
          // =================================================
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // -------------------------------------------
                // PROFILE
                // -------------------------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      _profileAvatar(context, profileName),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: profileWeight,
                              ),
                            ),

                            if (profileEmail.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                profileEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // -------------------------------------------
                // PRODUCTS
                // -------------------------------------------
                _MoreCard(
                  icon: AppIcons.products,
                  title: l10n.products,
                  subtitle: l10n.productsSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 9),

                // -------------------------------------------
                // LANGUAGE
                // -------------------------------------------
                _MoreCard(
                  icon: AppIcons.language,
                  title: l10n.language,
                  subtitle: currentLanguage,
                  onTap: () {
                    _showLanguagePicker(context);
                  },
                ),

                const SizedBox(height: 9),

                // -------------------------------------------
                // THEME
                // -------------------------------------------
                _MoreCard(
                  icon: AppIcons.theme,
                  title: l10n.theme,
                  subtitle: _currentThemeLabel(l10n, currentTheme),
                  onTap: () {
                    _showThemePicker(context);
                  },
                ),

                const SizedBox(height: 9),

                // -------------------------------------------
                // EXCHANGE RATE
                // -------------------------------------------
                _MoreCard(
                  icon: AppIcons.exchangeRate,
                  title: l10n.exchangeRate,
                  subtitle: l10n.exchangeRateSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExchangeRateScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 9),

                // -------------------------------------------
                // SIGN OUT
                // -------------------------------------------
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    minTileHeight: 66,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    leading: Icon(
                      AppIcons.signOut,
                      size: 22,
                      color: colors.onSurfaceVariant,
                    ),
                    title: Text(
                      l10n.signOut,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(AppIcons.chevronRight, size: 20),
                    onTap: () {
                      _confirmSignOut(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LANGUAGE OPTION
// ============================================================

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    flag,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),

                if (selected)
                  Icon(AppIcons.check, size: 21, color: colors.primary)
                else
                  const SizedBox(width: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// THEME OPTION
// ============================================================

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),

                if (selected)
                  Icon(AppIcons.check, size: 21, color: colors.primary)
                else
                  const SizedBox(width: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MORE CARD
// ============================================================

class _MoreCard extends StatelessWidget {
  const _MoreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    const radius = 20.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        minTileHeight: 66,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Icon(icon, size: 22, color: colors.onSurfaceVariant),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ),
        trailing: const Icon(AppIcons.chevronRight, size: 20),
        onTap: onTap,
      ),
    );
  }
}
