import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicart_models.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import 'checkout_screen.dart';
import 'invoices_screen.dart';

// 1. The Database Provider
final inventoryProvider = FutureProvider<List<Medicine>>((ref) async {
  return DatabaseService().medicinesBox.values.toList();
});

// 2. NEW: The Search State Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});

  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  Future<void> _deleteMedicine(Medicine med) async {
    // Delete from Hive
    await DatabaseService().deleteMedicine(med);
    
    // Refresh the UI list
    ref.invalidate(inventoryProvider);
    
    // Confirm to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} removed from inventory'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final inventoryAsyncValue = ref.watch(inventoryProvider);
    final cartItems = ref.watch(cartProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // The Header
          const SliverAppBar(
            backgroundColor: Color(0xFF09090B),
            expandedHeight: 100,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Inventory',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
            ),
          ),
          
          // NEW: The Premium Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4)),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ),
          ),
          
          // The Inventory List
          inventoryAsyncValue.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent))),
            ),
            data: (allMedicines) {
              if (allMedicines.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines found.\nImport a CSV or add one manually.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // NEW: Filter the medicines based on the search query
              final medicines = allMedicines.where((med) {
                final name = med.name?.toLowerCase() ?? '';
                return name.contains(searchQuery.toLowerCase());
              }).toList();

              if (medicines.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No results found for "$searchQuery"',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  ),
                );
              }
            
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final med = medicines[index];
                      final cartItemIndex = cartItems.indexWhere((item) => item.medicine.key == med.key);
                      final int cartQty = cartItemIndex != -1 ? cartItems[cartItemIndex].quantity : 0;
                  return Dismissible(
                        key: Key(med.key.toString()), 
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.redAccent,
                          margin: const EdgeInsets.symmetric(vertical: 4), 
                          child: const Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) {
                          _deleteMedicine(med); // Fired perfectly for this specific item
                        },
  
  // ---> YOUR ORIGINAL GESTURE DETECTOR GOES HERE <---
                    child:GestureDetector(
                        onTap: () {
                          // Opens the sheet in Edit Mode!
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => _AddMedicineSheet(existingMedicine: med),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: cartQty > 0 ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.white.withOpacity(0.05)
                            ),
                          ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  med.name ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cartQty > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'In Cart: $cartQty',
                                    style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '₹${med.price?.toStringAsFixed(2)}  •  Batch: ${med.batchNumber ?? 'N/A'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ),
                          trailing: cartQty > 0
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: Colors.white.withOpacity(0.5),
                                      onPressed: () => ref.read(cartProvider.notifier).decrementMedicine(med),
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '$cartQty',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      color: const Color(0xFF3B82F6),
                                      onPressed: () => ref.read(cartProvider.notifier).addMedicine(med),
                                    ),
                                
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    color: const Color(0xFF3B82F6),
                                    onPressed: () => ref.read(cartProvider.notifier).addMedicine(med),
                                  ),
                                ),
                        ),
                      )
                    )
                      );
                    },
                    childCount: medicines.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Floating Dock (Unchanged)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDockButton(
                  icon: Icons.receipt_long_rounded,
                  tooltip: 'History',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen())),
                ),
                const SizedBox(width: 4),
                _buildDockButton(
                  icon: Icons.add_box_outlined,
                  tooltip: 'Add Medicine',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const _AddMedicineSheet(),
                    );
                  },
                ),
                const SizedBox(width: 4),
                _buildDockButton(
                  icon: Icons.file_download_outlined,
                  tooltip: 'Import CSV',
                  onTap: () async {
                    final dbService = DatabaseService();
                    await dbService.importMedicinesFromCSV();
                    ref.invalidate(inventoryProvider);
                  },
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (cartItems.isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                        if (cartItems.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${cartItems.fold(0, (sum, item) => sum + item.quantity)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white.withOpacity(0.8)),
      onPressed: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.white.withOpacity(0.1),
    );
  }
}

// ============================================================================
// UPDATED: The Smart Add/Edit Modal Sheet
// ============================================================================
class _AddMedicineSheet extends ConsumerStatefulWidget {
  final Medicine? existingMedicine; // NEW: Accepts a medicine if we are editing

  const _AddMedicineSheet({this.existingMedicine}); 

  @override
  ConsumerState<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends ConsumerState<_AddMedicineSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchController = TextEditingController();

  final Color cardColor = const Color(0xFF0A2E38); 
  final Color primaryColor = const Color(0xFF00E5FF);
  final Color borderColor = Colors.white.withOpacity(0.05);

  @override
  void initState() {
    super.initState();
    // NEW: If we passed a medicine, pre-fill the form!
    if (widget.existingMedicine != null) {
      _nameController.text = widget.existingMedicine!.name ?? '';
      _priceController.text = widget.existingMedicine!.price?.toStringAsFixed(2) ?? '';
      _batchController.text = widget.existingMedicine!.batchNumber ?? '';
    }
  }

  Future<void> _saveMedicine() async {
    if (_nameController.text.trim().isEmpty) return;

    final medToSave = widget.existingMedicine ?? Medicine();
    
    medToSave
      ..name = _nameController.text.trim()
      ..price = double.tryParse(_priceController.text) ?? 0.0
      ..batchNumber = _batchController.text.trim();

    // 1. Save to Hive
    await DatabaseService().saveMedicine(medToSave);

    // 2. Refresh the UI list
    ref.invalidate(inventoryProvider); 

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingMedicine != null 
              ? '${medToSave.name} updated successfully' 
              : '${medToSave.name} added to inventory'),
          backgroundColor: cardColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _deleteMedicine(Medicine med) async {
    // 1. Delete from Hive
    await DatabaseService().deleteMedicine(med);
    
    // 2. Refresh the UI list
    ref.invalidate(inventoryProvider);
    
    // 3. Confirm to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.name} removed from inventory'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingMedicine != null; // Check what mode we are in

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding, left: 24, right: 24, top: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF041C23), Color(0xFF0A2E38)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isEditing ? 'Edit Medicine' : 'Add Medicine', // Dynamic Title
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildPremiumTextField(controller: _nameController, label: 'Medicine Name', icon: Icons.medication_outlined),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPremiumTextField(controller: _priceController, label: 'Price (₹)', icon: Icons.currency_rupee, isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPremiumTextField(controller: _batchController, label: 'Batch No.', icon: Icons.qr_code),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _saveMedicine,
              child: Text(isEditing ? 'Update Inventory' : 'Save to Inventory', // Dynamic Button
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    // ... (Keep your exact existing TextField code here) ...
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor)),
      ),
    );
  }
}