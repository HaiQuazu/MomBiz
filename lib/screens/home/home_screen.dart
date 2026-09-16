import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import 'dashboard_screen.dart';
import '../sales/sale_form_screen.dart';
import '../settings/exchange_rate_screen.dart';
import '../queue/chick_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openNewSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SaleFormScreen()),
    );
  }

  int _selectedIndex = 0;

  void _openCustomers() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.egg_alt_outlined),
            selectedIcon: Icon(Icons.egg_alt),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'More',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 24),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text(
                'Products',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Animal feed, vaccine, fertilizer and more'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(Icons.logout_rounded),
              title: const Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await AuthService.instance.signOut();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(Icons.currency_exchange_rounded),
              title: const Text(
                'Exchange rate',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('NBC official USD / KHR rate'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExchangeRateScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
