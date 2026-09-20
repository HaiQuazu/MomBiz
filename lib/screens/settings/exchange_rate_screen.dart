import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exchange_rate.dart';
import '../../services/exchange_rate_service.dart';
import '../../theme/app_icons.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  bool _refreshing = false;

  String _formatRate(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _refreshRate() async {
    if (_refreshing) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _refreshing = true;
    });

    try {
      final rate = await ExchangeRateService.instance.fetchNbcRate();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nbcRateUpdated(_formatRate(rate.khrPerUsd))),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdateNbcRate(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ExchangeRateService.instance.refreshIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final pageTitleWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    final sectionTitleWeight = isKhmer ? FontWeight.w500 : FontWeight.w600;

    return Scaffold(
      // ====================================================
      // FIXED APP BAR
      // ====================================================
      appBar: AppBar(
        title: Text(
          l10n.exchangeRate,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: pageTitleWeight,
          ),
        ),
      ),

      // ====================================================
      // SAVED RATE STREAM
      // ====================================================
      body: StreamBuilder<ExchangeRate?>(
        stream: ExchangeRateService.instance.watchCurrentRate(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        AppIcons.error,
                        size: 30,
                        color: colors.onErrorContainer,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      l10n.couldNotLoadSavedExchangeRate(
                        snapshot.error.toString(),
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rate = snapshot.data;

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                // =================================================
                // MAIN RATE CARD
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          AppIcons.exchangeRate,
                          color: colors.onPrimary,
                          size: 26,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        l10n.latestOfficialNbcRate,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        '1 USD',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '=',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.65),
                        ),
                      ),

                      const SizedBox(height: 3),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          rate == null
                              ? l10n.notLoaded
                              : '${_formatRate(rate.khrPerUsd)} KHR',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (rate != null) ...[
                        const SizedBox(height: 14),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.calendar,
                              size: 15,
                              color: colors.onPrimary.withValues(alpha: 0.75),
                            ),

                            const SizedBox(width: 6),

                            Flexible(
                              child: Text(
                                l10n.effectiveDateValue(
                                  _formatDate(rate.rateDate),
                                ),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // RATE SOURCE
                // =================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          AppIcons.selected,
                          size: 21,
                          color: colors.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.rateSource,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: sectionTitleWeight,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              rate?.source ?? l10n.nbcViaFrankfurter,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // REFRESH
                // =================================================
                FilledButton.icon(
                  onPressed: _refreshing ? null : _refreshRate,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.exchangeRate, size: 20),
                  label: Text(
                    _refreshing
                        ? l10n.gettingNbcRate
                        : rate == null
                        ? l10n.getNbcRate
                        : l10n.refreshNbcRate,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // EXPLANATION
                // =================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.exchangeRateExplanation,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
