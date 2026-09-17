import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/sale.dart';
import '../../services/customer_service.dart';
import '../../services/payment_service.dart';
import '../../services/sale_service.dart';
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

    // Keep both Active and Archived
    // streams subscribed all the time.
    //
    // Switching the segmented button
    // now only changes which cached
    // list is visible.
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
            icon: Icons.error_outline_rounded,
            title: l10n.couldNotLoadCustomers,
            message: l10n.pleaseTryAgain,
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCustomers = snapshot.data!;

        // Count duplicate names.
        //
        // Phone is only displayed when
        // duplicate names need to be
        // distinguished.
        final nameCounts = <String, int>{};

        for (final customer in allCustomers) {
          final key = _nameKey(customer);

          if (key.isEmpty) {
            continue;
          }

          nameCounts[key] = (nameCounts[key] ?? 0) + 1;
        }

        final customers = allCustomers.where((customer) {
          if (_search.isEmpty) {
            return true;
          }

          return customer.name.toLowerCase().contains(_search) ||
              customer.phone.toLowerCase().contains(_search);
        }).toList();

        if (customers.isEmpty) {
          return _CustomerMessage(
            icon: archived
                ? Icons.archive_outlined
                : Icons.people_outline_rounded,
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

        return ListView.separated(
          key: PageStorageKey(
            archived ? 'archived_customers_list' : 'active_customers_list',
          ),
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
              onTap: () => _openCustomer(customer),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        floatingActionButton: _showArchived
            ? null
            : FloatingActionButton.extended(
                heroTag: 'customers_add_customer',
                onPressed: _addCustomer,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l10n.addCustomer),
              ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------
            // HEADER
            // -----------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.customers,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),

                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      size: 25,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // -----------------------
            // SEARCH
            // -----------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBar(
                controller: _searchController,
                hintText: l10n.searchNameOrPhone,
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
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
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------
            // ACTIVE / ARCHIVED
            // -----------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.people_outline_rounded),
                      label: Text(l10n.active),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(l10n.archived),
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

            const SizedBox(height: 16),

            // -----------------------
            // BOTH LISTS STAY ALIVE
            // -----------------------
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
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  customer.name.trim().isEmpty
                      ? '?'
                      : customer.name.trim()[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (showPhone) ...[
                      const SizedBox(height: 3),

                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              customer.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

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

              if (archived)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.archive_outlined, size: 19),
                )
              else
                const Icon(Icons.chevron_right_rounded, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final colors = Theme.of(context).colorScheme;

    if (error) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
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
          Text(
            MoneyUtils.format(khrBalance, MoneyCurrency.khr),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),

        if (hasKhr && hasUsd) const SizedBox(height: 2),

        if (hasUsd)
          Text(
            MoneyUtils.format(usdBalance, MoneyCurrency.usd),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

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
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: colors.onPrimaryContainer),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 5),

            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
