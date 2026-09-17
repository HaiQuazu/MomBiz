import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exchange_rate.dart';
import '../../services/exchange_rate_service.dart';

class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({
    super.key,
  });

  @override
  State<ExchangeRateScreen> createState() =>
      _ExchangeRateScreenState();
}

class _ExchangeRateScreenState
    extends State<ExchangeRateScreen> {
  bool _refreshing = false;

  String _formatRate(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
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

    final l10n =
        AppLocalizations.of(context)!;

    setState(() {
      _refreshing = true;
    });

    try {
      final rate =
          await ExchangeRateService
              .instance
              .fetchNbcRate();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.nbcRateUpdated(
              _formatRate(
                rate.khrPerUsd,
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.couldNotUpdateNbcRate(
              error.toString(),
            ),
          ),
        ),
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

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        ExchangeRateService.instance
            .refreshIfNeeded();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.exchangeRate,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<ExchangeRate?>(
        stream: ExchangeRateService
            .instance
            .watchCurrentRate(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  l10n
                      .couldNotLoadSavedExchangeRate(
                    snapshot.error
                        .toString(),
                  ),
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final rate = snapshot.data;

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              40,
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                decoration:
                    BoxDecoration(
                  color: colors.primary,
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration:
                          BoxDecoration(
                        color: colors
                            .onPrimary
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .account_balance_rounded,
                        color:
                            colors.onPrimary,
                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      l10n
                          .latestOfficialNbcRate,
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: colors
                            .onPrimary
                            .withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      '1 USD',
                      style: TextStyle(
                        color:
                            colors.onPrimary,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      '=',
                      style: TextStyle(
                        color: colors
                            .onPrimary
                            .withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      rate == null
                          ? l10n.notLoaded
                          : '${_formatRate(rate.khrPerUsd)} KHR',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            colors.onPrimary,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    if (rate != null) ...[
                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        l10n
                            .effectiveDateValue(
                          _formatDate(
                            rate.rateDate,
                          ),
                        ),
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: colors
                              .onPrimary
                              .withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons
                            .verified_outlined,
                        color:
                            colors.primary,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              l10n
                                  .rateSource,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              rate?.source ??
                                  l10n
                                      .nbcViaFrankfurter,
                              style:
                                  TextStyle(
                                color: colors
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              FilledButton.icon(
                onPressed:
                    _refreshing
                        ? null
                        : _refreshRate,
                icon: _refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .refresh_rounded,
                      ),
                label: Text(
                  _refreshing
                      ? l10n
                          .gettingNbcRate
                      : rate == null
                          ? l10n
                              .getNbcRate
                          : l10n
                              .refreshNbcRate,
                  textAlign:
                      TextAlign.center,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                l10n
                    .exchangeRateExplanation,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: colors
                      .onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
