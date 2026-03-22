import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/medicart_models.dart';
import '../services/database_service.dart';
import 'dart:io';

// ============================================================================
// NEW: The "Optimistic Update" Engine (Zero Flicker!)
// ============================================================================
class InvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    final invoices = DatabaseService().invoicesBox.values.toList();
    invoices.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
    return invoices;
  }

  Future<void> deleteInvoice(BuildContext context, WidgetRef ref, Invoice invoice) async {
    final originalList = state.value ?? [];
    state = AsyncData(originalList.where((i) => i.key != invoice.key).toList());

    bool isUndoPressed = false;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF18181B),
        content: Text('Deleted bill for ${invoice.patientName}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF00E5FF),
          onPressed: () {
            isUndoPressed = true;
            state = AsyncData(originalList);
          },
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 5));
    if (!isUndoPressed) {
      await DatabaseService().deleteInvoice(invoice);
    }
  }

  Future<void> togglePaidStatus(Invoice invoice) async {
    invoice.isPaid = !invoice.isPaid;
    await invoice.save(); 
    state = AsyncData([
      for (final i in state.value ?? <Invoice>[])
        if (i.key == invoice.key) invoice else i
    ]);
  }
}
    


final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, List<Invoice>>(InvoicesNotifier.new);

// ============================================================================
// THE UI
// ============================================================================
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  // --- Premium Medical Theme Colors ---
  final Color bgColor = const Color(0xFF041C23); // Deep Surgical Teal
  final Color cardColor = const Color(0xFF0A2E38); // Rich Teal for Cards
  final Color primaryColor = const Color(0xFF00E5FF); // Medical Cyan
  final Color borderColor = const Color(0x0DFFFFFF); // White at 5% opacity
  final Color successColor = const Color(0xFF10B981); // Emerald green
  final Color pendingColor = const Color(0xFFF59E0B); // Amber

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsyncValue = ref.watch(invoicesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF041C23), Color(0xFF0A2E38)], // The subtle medical gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 120,
              floating: true,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 48, bottom: 16),
                title: Text(
                  'Bill History',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                ),
              ),
            ),

            invoicesAsyncValue.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent))),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No bills generated yet.',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final invoice = invoices[index];
                        final dateStr = invoice.date != null
                            ? DateFormat('dd MMM yyyy').format(invoice.date!)
                            : 'Unknown Date';

                        return Dismissible(
                          key: Key(invoice.key.toString()),
                          direction: DismissDirection.endToStart,
                          
                          // NEW: The Sleek, Ultra-Dark Deletion Background
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A0808), // Very deep, subtle maroon
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Delete', style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(width: 8),
                                Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.8), size: 28),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            // Triggers the instant Optimistic update
                            ref.read(invoicesProvider.notifier).deleteInvoice(context, ref, invoice);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Bill removed from records'),
                                backgroundColor: cardColor,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              )
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (invoice.imagePath != null && invoice.imagePath!.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog.fullscreen(
                                    backgroundColor: Colors.black,
                                    child: Stack(
                                      children: [
                                        Center(child: Image.file(File(invoice.imagePath!))),
                                        Positioned(
                                          top: 40, 
                                          left: 20, 
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No image saved for this older bill.'))
                                );
                              }
                            },
                            // This is your original Container that holds the invoice info!
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        invoice.patientName ?? 'Unknown',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (invoice.isPaid ? successColor : pendingColor).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: (invoice.isPaid ? successColor : pendingColor).withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        invoice.isPaid ? 'PAID' : 'PENDING',
                                        style: TextStyle(
                                          color: invoice.isPaid ? successColor : pendingColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                                    Text('#${invoice.billNumber}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, fontFamily: 'monospace')),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(color: Color(0x0DFFFFFF), height: 1),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currencyFormat.format(invoice.grandTotal ?? 0),
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                    ),
                                    GestureDetector(
                                      onTap: () => ref.read(invoicesProvider.notifier).togglePaidStatus(invoice),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: invoice.isPaid ? Colors.transparent : primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: invoice.isPaid ? borderColor : primaryColor.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              invoice.isPaid ? Icons.undo_rounded : Icons.check_circle_outline,
                                              size: 18,
                                              color: invoice.isPaid ? Colors.white.withOpacity(0.5) : primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              invoice.isPaid ? 'Unmark' : 'Mark Paid',
                                              style: TextStyle(
                                                color: invoice.isPaid ? Colors.white.withOpacity(0.5) : primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        );
                      },
                      childCount: invoices.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}