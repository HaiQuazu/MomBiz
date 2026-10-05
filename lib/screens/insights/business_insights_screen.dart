import 'package:flutter/material.dart';

import '../../services/business_insights_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';

class BusinessInsightsScreen
    extends StatefulWidget {
  const BusinessInsightsScreen({
    super.key,
  });

  @override
  State<BusinessInsightsScreen>
      createState() =>
          _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState
    extends State<BusinessInsightsScreen> {
  BusinessInsightsData? _data;

  Object? _error;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _load();
  }

  String _text({
    required String en,
    required String km,
  }) {
    return Localizations.localeOf(
                  context,
                ).languageCode ==
            'km'
        ? km
        : en;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data =
          await BusinessInsightsService
              .instance
              .load();

      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _format(
    int amount,
    MoneyCurrency currency,
  ) {
    return MoneyUtils.format(
      amount,
      currency,
    );
  }

  String _countText({
    required int count,
    required String singularEn,
    required String pluralEn,
    required String km,
  }) {
    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    if (isKhmer) {
      return '$count $km';
    }

    return '$count '
        '${count == 1 ? singularEn : pluralEn}';
  }

  List<_Observation>
      _observations(
    BusinessInsightsData data,
  ) {
    final observations =
        <_Observation>[];

    if (data.customersWithDebt > 0) {
      observations.add(
        _Observation(
          icon: AppIcons.customers,
          text: _text(
            en:
                '${data.customersWithDebt} '
                '${data.customersWithDebt == 1 ? 'customer has' : 'customers have'} '
                'outstanding debt.',
            km:
                'មានអតិថិជន ${data.customersWithDebt} នាក់ដែលនៅមានបំណុល។',
          ),
        ),
      );
    } else {
      observations.add(
        _Observation(
          icon: AppIcons.check,
          text: _text(
            en:
                'No customer currently has outstanding debt.',
            km:
                'បច្ចុប្បន្នមិនមានអតិថិជនណាមានបំណុលនៅសល់ទេ។',
          ),
        ),
      );
    }

    if (data.waitingChicks > 0) {
      observations.add(
        _Observation(
          icon: AppIcons.queue,
          text: _text(
            en:
                '${data.waitingChicks} chicks are currently waiting in the queue.',
            km:
                'មានកូនមាន់ ${data.waitingChicks} ក្បាលកំពុងរង់ចាំក្នុងជួរ។',
          ),
        ),
      );
    } else {
      observations.add(
        _Observation(
          icon: AppIcons.queue,
          text: _text(
            en:
                'There are no chicks currently waiting in the queue.',
            km:
                'បច្ចុប្បន្នមិនមានកូនមាន់កំពុងរង់ចាំក្នុងជួរទេ។',
          ),
        ),
      );
    }

    final khrObservation =
        _trendObservation(
      current:
          data.salesThisMonthKhr,
      previous:
          data.salesLastMonthKhr,
      currency:
          MoneyCurrency.khr,
      currencyName: 'KHR',
    );

    if (khrObservation != null) {
      observations.add(
        khrObservation,
      );
    }

    final usdObservation =
        _trendObservation(
      current:
          data.salesThisMonthUsd,
      previous:
          data.salesLastMonthUsd,
      currency:
          MoneyCurrency.usd,
      currencyName: 'USD',
    );

    if (usdObservation != null) {
      observations.add(
        usdObservation,
      );
    }

    if (data
            .pickedUpThisMonthChicks >
        0) {
      observations.add(
        _Observation(
          icon: AppIcons.check,
          text: _text(
            en:
                '${data.pickedUpThisMonthChicks} chicks were picked up this month.',
            km:
                'ខែនេះមានកូនមាន់ ${data.pickedUpThisMonthChicks} ក្បាលត្រូវបានមកយក។',
          ),
        ),
      );
    }

    if (observations.length >
        4) {
      return observations
          .take(4)
          .toList();
    }

    return observations;
  }

  _Observation? _trendObservation({
    required int current,
    required int previous,
    required MoneyCurrency currency,
    required String currencyName,
  }) {
    if (current == 0 &&
        previous == 0) {
      return null;
    }

    if (current > previous) {
      final difference =
          current - previous;

      return _Observation(
        icon: AppIcons.sale,
        text: _text(
          en:
              '$currencyName sales are higher than last month by '
              '${_format(difference, currency)}.',
          km:
              'ការលក់ $currencyName ខែនេះខ្ពស់ជាងខែមុន '
              '${_format(difference, currency)}។',
        ),
      );
    }

    if (current < previous) {
      final difference =
          previous - current;

      return _Observation(
        icon: AppIcons.sale,
        text: _text(
          en:
              '$currencyName sales are lower than last month by '
              '${_format(difference, currency)}.',
          km:
              'ការលក់ $currencyName ខែនេះទាបជាងខែមុន '
              '${_format(difference, currency)}។',
        ),
      );
    }

    return _Observation(
      icon: AppIcons.sale,
      text: _text(
        en:
            '$currencyName sales are the same as last month.',
        km:
            'ការលក់ $currencyName ខែនេះស្មើនឹងខែមុន។',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    final pageTitleWeight =
        isKhmer
            ? FontWeight.w600
            : FontWeight.w700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en:
                'Business Insights',
            km:
                'ការវិភាគអាជីវកម្ម',
          ),
          style: theme
              .textTheme.titleLarge
              ?.copyWith(
            fontWeight:
                pageTitleWeight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _text(
              en: 'Refresh',
              km: 'ផ្ទុកឡើងវិញ',
            ),
            onPressed:
                _loading ? null : _load,
            icon: const Icon(
              AppIcons.exchangeRate,
              size: 21,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading &&
        _data == null) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null &&
        _data == null) {
      return _ErrorState(
        title: _text(
          en:
              'Could not load business insights',
          km:
              'មិនអាចទាញយកការវិភាគអាជីវកម្មបានទេ',
        ),
        message: _text(
          en:
              'Check your connection and try again.',
          km:
              'សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត ហើយសាកល្បងម្តងទៀត។',
        ),
        retryLabel: _text(
          en: 'Try again',
          km: 'សាកល្បងម្តងទៀត',
        ),
        onRetry: _load,
      );
    }

    final data =
        _data!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),
        children: [
          _SectionHeader(
            title: _text(
              en: 'This month',
              km: 'ខែនេះ',
            ),
            subtitle: _text(
              en:
                  'A simple view of the business right now',
              km:
                  'ទិដ្ឋភាពសង្ខេបនៃអាជីវកម្មបច្ចុប្បន្ន',
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _MoneyMetricCard(
            icon: AppIcons.sale,
            title: _text(
              en:
                  'Sales this month',
              km:
                  'ការលក់ខែនេះ',
            ),
            khr:
                data.salesThisMonthKhr,
            usd:
                data.salesThisMonthUsd,
          ),

          const SizedBox(
            height: 10,
          ),

          _MoneyMetricCard(
            icon: AppIcons.payment,
            title: _text(
              en:
                  'Money received',
              km:
                  'ប្រាក់ទទួលបាន',
            ),
            subtitle: _text(
              en:
                  'Actual money received this month',
              km:
                  'ប្រាក់ដែលបានទទួលពិតប្រាកដក្នុងខែនេះ',
            ),
            khr:
                data.receivedThisMonthKhr,
            usd:
                data.receivedThisMonthUsd,
          ),

          const SizedBox(
            height: 10,
          ),

          _DebtCard(
            title: _text(
              en:
                  'Outstanding debt',
              km:
                  'បំណុលនៅសល់',
            ),
            customerText:
                _countText(
              count:
                  data.customersWithDebt,
              singularEn:
                  'customer with debt',
              pluralEn:
                  'customers with debt',
              km:
                  'អតិថិជនមានបំណុល',
            ),
            khr:
                data.outstandingKhr,
            usd:
                data.outstandingUsd,
          ),

          const SizedBox(
            height: 24,
          ),

          _SectionHeader(
            title: _text(
              en: 'Chick queue',
              km: 'ជួរកូនមាន់',
            ),
            subtitle: _text(
              en:
                  'Waiting now and pickups completed this month',
              km:
                  'កំពុងរង់ចាំ និងការមកយកដែលបានបញ្ចប់ក្នុងខែនេះ',
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    _QueueMetricCard(
                  icon:
                      AppIcons.waiting,
                  title: _text(
                    en: 'Waiting',
                    km:
                        'កំពុងរង់ចាំ',
                  ),
                  chicks:
                      data.waitingChicks,
                  customers:
                      data.waitingCustomers,
                  reservations:
                      data.waitingReservations,
                  customerLabel:
                      _text(
                    en: 'customers',
                    km:
                        'អតិថិជន',
                  ),
                  chickLabel:
                      _text(
                    en: 'chicks',
                    km:
                        'កូនមាន់',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _QueueMetricCard(
                  icon:
                      AppIcons.check,
                  title: _text(
                    en:
                        'Picked up',
                    km:
                        'បានមកយក',
                  ),
                  subtitle: _text(
                    en:
                        'This month',
                    km: 'ខែនេះ',
                  ),
                  chicks: data
                      .pickedUpThisMonthChicks,
                  customers: data
                      .pickedUpThisMonthCustomers,
                  reservations: data
                      .pickedUpThisMonthReservations,
                  customerLabel:
                      _text(
                    en: 'customers',
                    km:
                        'អតិថិជន',
                  ),
                  chickLabel:
                      _text(
                    en: 'chicks',
                    km:
                        'កូនមាន់',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          _SectionHeader(
            title: _text(
              en:
                  'This month vs last month',
              km:
                  'ខែនេះធៀបនឹងខែមុន',
            ),
            subtitle: _text(
              en:
                  'Sales are compared separately for KHR and USD',
              km:
                  'ការលក់ត្រូវបានប្រៀបធៀបដាច់ដោយឡែកសម្រាប់ KHR និង USD',
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _ComparisonCard(
            currentLabel: _text(
              en: 'This month',
              km: 'ខែនេះ',
            ),
            previousLabel:
                _text(
              en: 'Last month',
              km: 'ខែមុន',
            ),
            higherLabel: _text(
              en: 'Higher',
              km: 'ខ្ពស់ជាង',
            ),
            lowerLabel: _text(
              en: 'Lower',
              km: 'ទាបជាង',
            ),
            sameLabel: _text(
              en: 'No change',
              km:
                  'មិនមានការប្រែប្រួល',
            ),
            currentKhr:
                data.salesThisMonthKhr,
            previousKhr:
                data.salesLastMonthKhr,
            currentUsd:
                data.salesThisMonthUsd,
            previousUsd:
                data.salesLastMonthUsd,
          ),

          const SizedBox(
            height: 24,
          ),

          _SectionHeader(
            title: _text(
              en:
                  'Analyst observations',
              km:
                  'ការសង្កេតអាជីវកម្ម',
            ),
            subtitle: _text(
              en:
                  'Simple observations calculated from MomBiz data',
              km:
                  'ការសង្កេតសាមញ្ញដែលគណនាពីទិន្នន័យ MomBiz',
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _ObservationsCard(
            observations:
                _observations(data),
          ),

          if (_loading) ...[
            const SizedBox(
              height: 18,
            ),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme
              .textTheme.titleLarge
              ?.copyWith(
            fontWeight:
                isKhmer
                    ? FontWeight.w500
                    : FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style: theme
              .textTheme.bodySmall
              ?.copyWith(
            color:
                colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MoneyMetricCard
    extends StatelessWidget {
  const _MoneyMetricCard({
    required this.icon,
    required this.title,
    required this.khr,
    required this.usd,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final int khr;
  final int usd;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: colors
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color: colors
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: colors
                  .onPrimaryContainer,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        isKhmer
                            ? FontWeight
                                .w500
                            : FontWeight
                                .w600,
                  ),
                ),

                if (subtitle !=
                    null) ...[
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    subtitle!,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: colors
                          .onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 10,
                ),

                Text(
                  MoneyUtils.format(
                    khr,
                    MoneyCurrency.khr,
                  ),
                  style: theme
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  MoneyUtils.format(
                    usd,
                    MoneyCurrency.usd,
                  ),
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: colors
                        .onSurfaceVariant,
                    fontWeight:
                        FontWeight.w600,
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

class _DebtCard
    extends StatelessWidget {
  const _DebtCard({
    required this.title,
    required this.customerText,
    required this.khr,
    required this.usd,
  });

  final String title;
  final String customerText;

  final int khr;
  final int usd;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: colors.primary,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment:
                    Alignment.center,
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
                    14,
                  ),
                ),
                child: Icon(
                  AppIcons.customers,
                  size: 21,
                  color:
                      colors.onPrimary,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  title,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color:
                        colors.onPrimary,
                    fontWeight:
                        isKhmer
                            ? FontWeight
                                .w500
                            : FontWeight
                                .w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            MoneyUtils.format(
              khr,
              MoneyCurrency.khr,
            ),
            style: theme
                .textTheme
                .headlineMedium
                ?.copyWith(
              color: colors.onPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            MoneyUtils.format(
              usd,
              MoneyCurrency.usd,
            ),
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              color: colors.onPrimary,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          Text(
            customerText,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: colors.onPrimary
                  .withValues(
                alpha: 0.78,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMetricCard
    extends StatelessWidget {
  const _QueueMetricCard({
    required this.icon,
    required this.title,
    required this.chicks,
    required this.customers,
    required this.reservations,
    required this.customerLabel,
    required this.chickLabel,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final int chicks;
  final int customers;
  final int reservations;

  final String customerLabel;
  final String chickLabel;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final isKhmer =
        Localizations.localeOf(
                  context,
                ).languageCode ==
            'km';

    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: colors
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color: colors
                      .primaryContainer,
                  borderRadius:
                      BorderRadius
                          .circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: colors
                      .onPrimaryContainer,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            isKhmer
                                ? FontWeight
                                    .w500
                                : FontWeight
                                    .w600,
                      ),
                    ),

                    if (subtitle !=
                        null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: colors
                              .onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            '$chicks',
            style: theme
                .textTheme
                .headlineMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          Text(
            chickLabel,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: colors
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          Text(
            '$customers $customerLabel',
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: colors
                  .onSurfaceVariant,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard
    extends StatelessWidget {
  const _ComparisonCard({
    required this.currentLabel,
    required this.previousLabel,
    required this.higherLabel,
    required this.lowerLabel,
    required this.sameLabel,
    required this.currentKhr,
    required this.previousKhr,
    required this.currentUsd,
    required this.previousUsd,
  });

  final String currentLabel;
  final String previousLabel;

  final String higherLabel;
  final String lowerLabel;
  final String sameLabel;

  final int currentKhr;
  final int previousKhr;

  final int currentUsd;
  final int previousUsd;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      decoration:
          BoxDecoration(
        color: colors
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          _ComparisonRow(
            code: 'KHR',
            currentLabel:
                currentLabel,
            previousLabel:
                previousLabel,
            higherLabel:
                higherLabel,
            lowerLabel:
                lowerLabel,
            sameLabel: sameLabel,
            current: currentKhr,
            previous: previousKhr,
            currency:
                MoneyCurrency.khr,
          ),

          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colors.outlineVariant
                .withValues(
              alpha: 0.55,
            ),
          ),

          _ComparisonRow(
            code: 'USD',
            currentLabel:
                currentLabel,
            previousLabel:
                previousLabel,
            higherLabel:
                higherLabel,
            lowerLabel:
                lowerLabel,
            sameLabel: sameLabel,
            current: currentUsd,
            previous: previousUsd,
            currency:
                MoneyCurrency.usd,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow
    extends StatelessWidget {
  const _ComparisonRow({
    required this.code,
    required this.currentLabel,
    required this.previousLabel,
    required this.higherLabel,
    required this.lowerLabel,
    required this.sameLabel,
    required this.current,
    required this.previous,
    required this.currency,
  });

  final String code;

  final String currentLabel;
  final String previousLabel;

  final String higherLabel;
  final String lowerLabel;
  final String sameLabel;

  final int current;
  final int previous;

  final MoneyCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final difference =
        current - previous;

    final trendIcon =
        difference > 0
            ? AppIcons.chevronRight
            : difference < 0
                ? AppIcons.chevronDown
                : AppIcons.check;

    final trendLabel =
        difference > 0
            ? higherLabel
            : difference < 0
                ? lowerLabel
                : sameLabel;

    final differenceAmount =
        difference.abs();

    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _ComparisonValue(
                  label:
                      currentLabel,
                  amount:
                      current,
                  currency:
                      currency,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _ComparisonValue(
                  label:
                      previousLabel,
                  amount:
                      previous,
                  currency:
                      currency,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Icon(
                trendIcon,
                size: 17,
                color:
                    colors.primary,
              ),

              const SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  difference == 0
                      ? trendLabel
                      : '$trendLabel • '
                          '${MoneyUtils.format(
                            differenceAmount,
                            currency,
                          )}',
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                        colors.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonValue
    extends StatelessWidget {
  const _ComparisonValue({
    required this.label,
    required this.amount,
    required this.currency,
  });

  final String label;
  final int amount;
  final MoneyCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme
              .textTheme.bodySmall
              ?.copyWith(
            color:
                colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          MoneyUtils.format(
            amount,
            currency,
          ),
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: theme
              .textTheme.titleSmall
              ?.copyWith(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ObservationsCard
    extends StatelessWidget {
  const _ObservationsCard({
    required this.observations,
  });

  final List<_Observation>
      observations;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: colors
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0;
              index <
                  observations.length;
              index++) ...[
            _ObservationRow(
              observation:
                  observations[index],
            ),

            if (index !=
                observations.length -
                    1)
              Divider(
                height: 1,
                color: colors
                    .outlineVariant
                    .withValues(
                  alpha: 0.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ObservationRow
    extends StatelessWidget {
  const _ObservationRow({
    required this.observation,
  });

  final _Observation observation;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color: colors
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              observation.icon,
              size: 17,
              color: colors
                  .onPrimaryContainer,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                observation.text,
                style: theme
                    .textTheme
                    .bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Observation {
  const _Observation({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: colors
                    .errorContainer,
                borderRadius:
                    BorderRadius
                        .circular(
                  22,
                ),
              ),
              child: Icon(
                AppIcons.error,
                size: 32,
                color: colors
                    .onErrorContainer,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colors
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                AppIcons.exchangeRate,
                size: 19,
              ),
              label:
                  Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
