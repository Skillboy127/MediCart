import 'package:flutter/material.dart';
import 'invoices_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Add this import at the top


// ... inside your DashboardScreen build method ...

      appBar: AppBar(
        title: const Text(
          'MediCart Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Invoice History',
            icon: const Icon(Icons.history, color: Colors.blue), // The new button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InvoicesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _QuickStatsCard(),
            const SizedBox(height: 24),
            Text(
              'Recent Invoices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Placeholder for 5 recent bills
                itemBuilder: (context, index) {
                  return _InvoiceTile(index: index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Create Invoice Screen
        },
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
    );
  }
}

// A reusable widget for the top stats (e.g., today's revenue)
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Billings',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '₹ 12,450', // Formatted for INR
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(Icons.analytics_outlined, color: Colors.white, size: 40),
        ],
      ),
    );
  }
}

// A reusable widget for individual list items
class _InvoiceTile extends StatelessWidget {
  final int index;
  const _InvoiceTile({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.person_outline),
        ),
        title: Text('Patient Name ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Sent via SMS • 10:30 AM'),
        trailing: const Text(
          '₹ 850',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}