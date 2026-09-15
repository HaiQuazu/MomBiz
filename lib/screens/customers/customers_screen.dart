import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../../services/customer_service.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  Future<void> _openAddCustomer(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerFormScreen(),
      ),
    );
  }

  Future<void> _openEditCustomer(
    BuildContext context,
    Customer customer,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(
          customer: customer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCustomer(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Customer'),
      ),
      body: StreamBuilder<List<Customer>>(
        stream: CustomerService.instance.watchCustomers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load customers.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No customers yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap “Add Customer” to create the first customer.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
            ),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
            ),
            itemBuilder: (context, index) {
              final customer = customers[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    customer.name.isEmpty
                        ? '?'
                        : customer.name[0].toUpperCase(),
                  ),
                ),
                title: Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: customer.phone.isEmpty
                    ? const Text('No phone number')
                    : Text(customer.phone),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () => _openEditCustomer(
                  context,
                  customer,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
