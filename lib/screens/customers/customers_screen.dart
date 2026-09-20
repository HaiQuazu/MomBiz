import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
import '../../theme/app_icons.dart';
import '../../utils/money_utils.dart';
import 'customer_details_screen.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  late final Stream<List<Customer>> _activeCustomersStream;
  late final Stream<List<Customer>> _archivedCustomersStream;

  String _search = '';
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();

    // Keep both streams alive while switching tabs.
    _activeCustomersStream = CustomerService.instance.watchCustomers(
      archived: false,
    );

    _archivedCustomersStream = CustomerService.instance.watchCustomers(
      archived: true,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
  }

  Future<void> _openCustomer(Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(customerId: customer.id),
      ),
    );
  }

  String _nameKey(Customer customer) {
    return customer.name.trim().toLowerCase();
  }

  Widget _buildCustomerList({
    required Stream<List<Customer>> stream,
    required bool archived,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Customer>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CustomerMessage(
            icon: AppIcons.error,
            title: l10n.couldNotLoadCustomers,
            message: l10n.pleaseTryAgain,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCustomers = snapshot.data!;

        // =====================================================
        // DUPLICATE NAME COUNT
        //
        // Phone stays searchable for every customer,
        // but is only displayed when duplicate names
        // need to be distinguished.
        // =====================================================

        final nameCounts = <String, int>{};

        for (final customer in allCustomers) {
          final key = _nameKey(customer);

          if (key.isEmpty) {
            continue;
          }

          nameCounts[key] = (nameCounts[key] ?? 0) + 1;
        }

        // =====================================================
        // SEARCH
        // =====================================================

        final customers = allCustomers.where((customer) {
          if (_search.isEmpty) {
            return true;
          }

          return customer.name.toLowerCase().contains(_search) ||
              customer.phone.toLowerCase().contains(_search);
        }).toList();

        if (customers.isEmpty) {
          return _CustomerMessage(
            icon: archived ? AppIcons.archive : AppIcons.customers,
            title: _search.isNotEmpty
                ? l10n.noCustomerFound
                : archived
                ? l10n.noArchivedCustomers
                : l10n.noCustomersYet,
            message: _search.isNotEmpty
                ? l10n.tryAnotherNameOrPhone
                : archived
                ? l10n.archivedCustomersAppearHere
                : l10n.addFirstCustomer,
          );
        }

        // =====================================================
        // CUSTOMER LIST
        // =====================================================

        return ListView.separated(
          key: PageStorageKey(
            archived ? 'archived_customers_list' : 'active_customers_list',
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          itemCount: customers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final customer = customers[index];

            final key = _nameKey(customer);

            final duplicateName = (nameCounts[key] ?? 0) > 1;

            return _CustomerCard(
              customer: customer,
              archived: archived,
              showPhone: duplicateName && customer.phone.trim().isNotEmpty,
              onTap: () {
                _openCustomer(customer);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    final headingWeight = isKhmer ? FontWeight.w600 : FontWeight.w700;

    return SafeArea(
      child: Scaffold(
        // ====================================================
        // ADD CUSTOMER
        // ====================================================
        floatingActionButton: _showArchived
            ? null
            : FloatingActionButton.extended(
                heroTag: 'customers_add_customer',
                onPressed: _addCustomer,
                icon: const Icon(AppIcons.customerAdd, size: 21),
                label: Text(
                  l10n.addCustomer,
                  style: TextStyle(
                    fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ),

        body: Column(
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
                      l10n.customers,
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
                      AppIcons.customers,
                      size: 23,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // FIXED SEARCH
            // =================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBar(
                controller: _searchController,
                hintText: l10n.searchNameOrPhone,
                leading: const Icon(AppIcons.search, size: 21),
                onChanged: (value) {
                  setState(() {
                    _search = value.trim().toLowerCase();
                  });
                },
                trailing: [
                  if (_search.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _search = '';
                        });
                      },
                      icon: const Icon(AppIcons.close, size: 20),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =================================================
            // FIXED ACTIVE / ARCHIVED
            // =================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 240,
                  child: SegmentedButton<bool>(
                    expandedInsets: EdgeInsets.zero,
                    selectedIcon: const Icon(AppIcons.check, size: 18),
                    style: ButtonStyle(
                      visualDensity: const VisualDensity(
                        horizontal: -1,
                        vertical: -2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      textStyle: WidgetStateProperty.resolveWith<TextStyle?>((
                        states,
                      ) {
                        final selected = states.contains(WidgetState.selected);

                        return theme.textTheme.labelLarge?.copyWith(
                          fontWeight: isKhmer
                              ? selected
                                    ? FontWeight.w600
                                    : FontWeight.w500
                              : selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        );
                      }),
                    ),
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        icon: const Icon(AppIcons.customers, size: 18),
                        label: Text(
                          l10n.active,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(AppIcons.archive, size: 18),
                        label: Text(
                          l10n.archived,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (value) {
                      setState(() {
                        _showArchived = value.first;
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // ONLY CUSTOMER LIST SCROLLS
            //
            // Both lists remain alive.
            // =================================================
            Expanded(
              child: IndexedStack(
                index: _showArchived ? 1 : 0,
                children: [
                  _buildCustomerList(
                    stream: _activeCustomersStream,
                    archived: false,
                  ),
                  _buildCustomerList(
                    stream: _archivedCustomersStream,
                    archived: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER CARD
// ============================================================

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.archived,
    required this.showPhone,
    required this.onTap,
  });

  final Customer customer;
  final bool archived;
  final bool showPhone;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sale>>(
      stream: SaleService.instance.watchSalesForCustomer(customer.id),
      builder: (context, saleSnapshot) {
        if (!saleSnapshot.hasData) {
          return _CustomerCardContent(
            customer: customer,
            archived: archived,
            showPhone: showPhone,
            loadingBalance: true,
            balanceError: saleSnapshot.hasError,
            khrBalance: 0,
            usdBalance: 0,
            onTap: onTap,
          );
        }

        final sales = saleSnapshot.data!;

        return StreamBuilder<List<CustomerPayment>>(
          stream: PaymentService.instance.watchPaymentsForCustomer(customer.id),
          builder: (context, paymentSnapshot) {
            if (!paymentSnapshot.hasData) {
              return _CustomerCardContent(
                customer: customer,
                archived: archived,
                showPhone: showPhone,
                loadingBalance: true,
                balanceError: paymentSnapshot.hasError,
                khrBalance: 0,
                usdBalance: 0,
                onTap: onTap,
              );
            }

            var khrBalance = 0;
            var usdBalance = 0;

            // =================================================
            // SALES ADD TO DEBT
            // =================================================

            for (final sale in sales) {
              if (sale.status != 'active') {
                continue;
              }

              if (sale.currency == MoneyCurrency.khr) {
                khrBalance += sale.totalMinor;
              } else {
                usdBalance += sale.totalMinor;
              }
            }

            // =================================================
            // PAYMENTS SUBTRACT FROM DEBT
            // =================================================

            for (final payment in paymentSnapshot.data!) {
              if (payment.status != 'active') {
                continue;
              }

              if (payment.appliedCurrency == MoneyCurrency.khr) {
                khrBalance -= payment.appliedAmountMinor;
              } else {
                usdBalance -= payment.appliedAmountMinor;
              }
            }

            if (khrBalance < 0) {
              khrBalance = 0;
            }

            if (usdBalance < 0) {
              usdBalance = 0;
            }

            return _CustomerCardContent(
              customer: customer,
              archived: archived,
              showPhone: showPhone,
              loadingBalance: false,
              balanceError: false,
              khrBalance: khrBalance,
              usdBalance: usdBalance,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}

// ============================================================
// CUSTOMER CARD CONTENT
// ============================================================

class _CustomerCardContent extends StatelessWidget {
  const _CustomerCardContent({
    required this.customer,
    required this.archived,
    required this.showPhone,
    required this.loadingBalance,
    required this.balanceError,
    required this.khrBalance,
    required this.usdBalance,
    required this.onTap,
  });

  final Customer customer;
  final bool archived;
  final bool showPhone;

  final bool loadingBalance;
  final bool balanceError;

  final int khrBalance;
  final int usdBalance;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              // =================================================
              // AVATAR
              // =================================================
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  customer.name.trim().isEmpty
                      ? '?'
                      : customer.name.trim()[0].toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              // =================================================
              // NAME / DUPLICATE PHONE
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),

                    if (showPhone) ...[
                      const SizedBox(height: 3),

                      Row(
                        children: [
                          Icon(
                            AppIcons.phone,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              customer.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // OUTSTANDING BALANCE
              // =================================================
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 125),
                child: _BalanceDisplay(
                  loading: loadingBalance,
                  error: balanceError,
                  khrBalance: khrBalance,
                  usdBalance: usdBalance,
                ),
              ),

              const SizedBox(width: 7),

              // =================================================
              // TRAILING
              // =================================================
              if (archived)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    AppIcons.archive,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                const Icon(AppIcons.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BALANCE
// ============================================================

class _BalanceDisplay extends StatelessWidget {
  const _BalanceDisplay({
    required this.loading,
    required this.error,
    required this.khrBalance,
    required this.usdBalance,
  });

  final bool loading;
  final bool error;

  final int khrBalance;
  final int usdBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    if (error) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    if (loading) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final hasKhr = khrBalance > 0;

    final hasUsd = usdBalance > 0;

    if (!hasKhr && !hasUsd) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasKhr)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              MoneyUtils.format(khrBalance, MoneyCurrency.khr),
              maxLines: 1,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        if (hasKhr && hasUsd) const SizedBox(height: 2),

        if (hasUsd)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              MoneyUtils.format(usdBalance, MoneyCurrency.usd),
              maxLines: 1,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// EMPTY / ERROR MESSAGE
// ============================================================

class _CustomerMessage extends StatelessWidget {
  const _CustomerMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isKhmer = Localizations.localeOf(context).languageCode == 'km';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 32, color: colors.onPrimaryContainer),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: isKhmer ? FontWeight.w500 : FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
