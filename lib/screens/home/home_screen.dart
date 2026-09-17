import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/exchange_rate_service.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import '../queue/chick_queue_screen.dart';
import '../sales/sale_form_screen.dart';
import '../settings/exchange_rate_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ExchangeRateService.instance.refreshIfNeeded();
    });
  }

  Future<void> _openNewSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SaleFormScreen(),
      ),
    );
  }

  void _openCustomers() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

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
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(
              Icons.home_outlined,
            ),
            selectedIcon: const Icon(
              Icons.home_rounded,
            ),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.people_outline,
            ),
            selectedIcon: const Icon(
              Icons.people,
            ),
            label: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.egg_alt_outlined,
            ),
            selectedIcon: const Icon(
              Icons.egg_alt,
            ),
            label: l10n.queue,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.grid_view_outlined,
            ),
            selectedIcon: const Icon(
              Icons.grid_view_rounded,
            ),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  Future<void> _showLanguagePicker(
    BuildContext context,
  ) async {
    final l10n =
        AppLocalizations.of(context)!;

    final currentLanguage =
        AppSettingsService
            .instance
            .locale
            .languageCode;

    final selected =
        await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  l10n.chooseLanguage,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: colors
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(
                  height: 12,
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.language_rounded,
                  ),
                  title: Text(
                    l10n.english,
                  ),
                  trailing:
                      currentLanguage == 'en'
                          ? Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  colors.primary,
                            )
                          : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      'en',
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.translate_rounded,
                  ),
                  title: Text(
                    l10n.khmer,
                  ),
                  trailing:
                      currentLanguage == 'km'
                          ? Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  colors.primary,
                            )
                          : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      'km',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected == currentLanguage) {
      return;
    }

    await AppSettingsService.instance
        .setLanguage(
      selected,
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
  ) async {
    final l10n =
        AppLocalizations.of(context)!;

    final currentTheme =
        AppSettingsService
            .instance
            .themeMode;

    final selected =
        await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.theme,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  l10n.chooseTheme,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: colors
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(
                  height: 12,
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons
                        .brightness_auto_rounded,
                  ),
                  title: Text(
                    l10n.systemTheme,
                  ),
                  trailing:
                      currentTheme ==
                              ThemeMode.system
                          ? Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  colors.primary,
                            )
                          : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      ThemeMode.system,
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.light_mode_rounded,
                  ),
                  title: Text(
                    l10n.lightTheme,
                  ),
                  trailing:
                      currentTheme ==
                              ThemeMode.light
                          ? Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  colors.primary,
                            )
                          : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      ThemeMode.light,
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.dark_mode_rounded,
                  ),
                  title: Text(
                    l10n.darkTheme,
                  ),
                  trailing:
                      currentTheme ==
                              ThemeMode.dark
                          ? Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  colors.primary,
                            )
                          : null,
                  onTap: () {
                    Navigator.pop(
                      context,
                      ThemeMode.dark,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected == currentTheme) {
      return;
    }

    await AppSettingsService.instance
        .setThemeMode(
      selected,
    );
  }

  String _currentThemeLabel(
    AppLocalizations l10n,
    ThemeMode mode,
  ) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightTheme;

      case ThemeMode.dark:
        return l10n.darkTheme;

      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final colors =
        Theme.of(context).colorScheme;

    final languageCode =
        AppSettingsService
            .instance
            .locale
            .languageCode;

    final currentLanguage =
        languageCode == 'km'
            ? l10n.khmer
            : l10n.english;

    final currentTheme =
        AppSettingsService
            .instance
            .themeMode;

    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          22,
        ),
        children: [
          Text(
            l10n.more,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(
            height: 16,
          ),

          _MoreCard(
            icon:
                Icons.inventory_2_outlined,
            title:
                l10n.products,
            subtitle:
                l10n.productsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProductsScreen(),
                ),
              );
            },
          ),

          const SizedBox(
            height: 9,
          ),

          _MoreCard(
            icon:
                Icons.language_rounded,
            title:
                l10n.language,
            subtitle:
                currentLanguage,
            onTap: () =>
                _showLanguagePicker(
              context,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          _MoreCard(
            icon:
                Icons.palette_outlined,
            title:
                l10n.theme,
            subtitle:
                _currentThemeLabel(
              l10n,
              currentTheme,
            ),
            onTap: () =>
                _showThemePicker(
              context,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          _MoreCard(
            icon: Icons
                .currency_exchange_rounded,
            title:
                l10n.exchangeRate,
            subtitle: l10n
                .exchangeRateSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ExchangeRateScreen(),
                ),
              );
            },
          ),

          const SizedBox(
            height: 9,
          ),

          Card(
            child: ListTile(
              minTileHeight: 66,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 4,
              ),
              leading: Icon(
                Icons.logout_rounded,
                size: 25,
                color: colors
                    .onSurfaceVariant,
              ),
              title: Text(
                l10n.signOut,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 24,
              ),
              onTap: () async {
                await AuthService
                    .instance
                    .signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors =
        Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        minTileHeight: 66,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Icon(
          icon,
          size: 25,
          color:
              colors.onSurfaceVariant,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                fontWeight:
                    FontWeight.w600,
              ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 1,
          ),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: colors
                      .onSurfaceVariant,
                  height: 1.2,
                ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}
