import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/medicart_invoice_layout.dart';
import '../models/medicart_models.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'invoices_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _patientNameController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final ScreenshotController _screenshotController = ScreenshotController();
  // Update your controller to start empty or with a placeholder
late TextEditingController _billNumberController;
String _getFinancialQuarter(DateTime date) {
  final month = date.month;
  if (month >= 4 && month <= 6) return 'Q1';
  if (month >= 7 && month <= 9) return 'Q2';
  if (month >= 10 && month <= 12) return 'Q3';
  return 'Q4'; // January, February, March
}

@override
void initState() {
  super.initState();
  _billNumberController = TextEditingController();
  _generateAutoBillNumber(); // Auto-generate on load
}

Future<void> _generateAutoBillNumber() async {
  final dbService = DatabaseService();
  final invoices = dbService.invoicesBox.values.toList();

  int nextNumber = 333; // default starting number

  if (invoices.isNotEmpty) {
    // Extract the numeric part from all saved bill numbers
    int maxFound = 0;
    for (final invoice in invoices) {
      final billNo = invoice.billNumber ?? '';
      // Extract number from format: DR/M/P/335/MM/QX/2526
      final parts = billNo.split('/');
      if (parts.length >= 4) {
        final num = int.tryParse(parts[3]);
        if (num != null && num > maxFound) {
          maxFound = num;
        }
      }
    }
    if (maxFound > 0) nextNumber = maxFound + 1;
  }

  final now = _selectedDate;
  final month = now.month.toString().padLeft(2, '0');
  final quarter = _getFinancialQuarter(now); // replaces the old one-liner

setState(() {
  _billNumberController.text = "DR/M/P/$nextNumber/$month/$quarter/2526";
});
  
}
  DateTime _selectedDate = DateTime.now();
  
  @override
  void dispose() {
    _patientNameController.dispose();
    _discountController.dispose();
    _billNumberController.dispose();
    super.dispose();
  }
  Future<void> _selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2101),
  );
  if (picked != null && picked != _selectedDate) {
    setState(() { _selectedDate = picked; });
  }
}
  // --- Premium UI Colors ---
  final Color bgColor = const Color(0xFF09090B);
  final Color cardColor = const Color(0xFF18181B);
  final Color primaryColor = const Color(0xFF3B82F6);
  final Color borderColor = Colors.white.withOpacity(0.05);

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    
    // Dynamic math calculations
    double subtotal = cartItems.fold(0, (sum, item) => sum + ((item.medicine.price ?? 0) * item.quantity));
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    double grandTotal = subtotal - discount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Review Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: cartItems.isEmpty 
        ? Center(
            child: Text(
              'Cart is empty',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
            ),
          )
        : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              children: [
                // In your ListView, add these two fields before the Patient Name:
                _buildPremiumTextField(
                  controller: _billNumberController,
                  label: 'Bill Number',
                  icon: Icons.numbers,
                ),
                const SizedBox(height: 16),
                // Date Picker Tile
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: _buildPremiumTextField(
                    controller: TextEditingController(text: DateFormat('dd-MMM-yyyy').format(_selectedDate)),
                    label: 'Bill Date',
                    icon: Icons.calendar_today,
                    enabled: false, // Prevents typing, forces the picker
                  ),
                ),
                const SizedBox(height: 16),
                // 1. Patient Details Input
                _buildPremiumTextField(
                  controller: _patientNameController,
                  label: 'Patient Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                
                // 2. Discount Input
                _buildPremiumTextField(
                  controller: _discountController,
                  label: 'Discount (₹)',
                  icon: Icons.local_offer_outlined,
                  isNumber: true,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'CART ITEMS',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),

                // 3. Cart Items List
                ...cartItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(item.medicine.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Qty: ${item.quantity}  x  ₹${item.medicine.price}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    ),
                    trailing: Text(
                      '₹${((item.medicine.price ?? 0) * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
              ],
            ),
          ),

          // 4. Premium Sticky Bottom Bar
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.8),
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSummaryRow('Subtotal', subtotal),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Discount', discount, isDiscount: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white10),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹${grandTotal.toStringAsFixed(2)}', style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Finalize Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => _generateAndShareBill(cartItems, subtotal, discount, grandTotal),
                        child: const Text('Generate & Share Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildPremiumTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isNumber = false,
    bool enabled = true, // NEW: Defaults to true
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled, // NEW: Connects to the parameter
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: enabled ? Colors.white : Colors.white.withOpacity(0.5)),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: cardColor,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
        Text(
          '${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(2)}',
          style: TextStyle(color: isDiscount ? Colors.redAccent : Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // --- Core Logic (Unchanged from our flawless build) ---
  
  Future<void> _generateAndShareBill(List<CartItem> cartItems, double subtotal, double discount, double grandTotal) async {
    if (_patientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a patient name'))
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use the custom Bill Number and Date from your controllers
      final String finalBillNo = _billNumberController.text;
      final DateTime finalDate = _selectedDate;

      // Prepare items for the Invoice Widget (including Batch Numbers)
      final formattedItems = cartItems.map((item) => {
  'name': item.medicine.name,
  'qty': item.quantity,
  'price': item.medicine.price,
  'batch': (item.medicine.batchNumber == null || 
             item.medicine.batchNumber!.trim().isEmpty || 
             item.medicine.batchNumber!.trim().toUpperCase() == 'N/A') 
            ? '' 
            : item.medicine.batchNumber!.trim(),
}).toList();

      // Capture the professional white bill
      final imageBytes = await _screenshotController.captureFromWidget(
        MediCartInvoiceWidget(
          patientName: _patientNameController.text,
          billNumber: finalBillNo,
          date: finalDate,
          items: formattedItems,
          discount: discount,
        ),
        context: context,
      );

      final directory = await getApplicationDocumentsDirectory();
      final imageFile = File('${directory.path}/MediCart_Bill_${finalBillNo.replaceAll('/', '_')}.png');
      await imageFile.writeAsBytes(imageBytes);

      // Save to History (using the same custom inputs)
      final dbService = DatabaseService();
      
      
      final newInvoice = Invoice()
        ..patientName = _patientNameController.text
        ..billNumber = finalBillNo 
        ..date = finalDate
        ..subtotal = subtotal
        ..discount = discount
        ..grandTotal = grandTotal
        ..isPaid = false
        ..imagePath = imageFile.path
        
        ..items = cartItems.map((item) => InvoiceItem()
            ..name = item.medicine.name
            ..qty = item.quantity
            ..price = item.medicine.price
          ).toList();
        

      await DatabaseService().saveInvoice(newInvoice);
      ref.invalidate(invoicesProvider);

      if (context.mounted) Navigator.pop(context);

      // Share via WhatsApp/System
      // ignore: deprecated_member_use
      Share.shareXFiles(
  [XFile(imageFile.path)],
  text: 'Hello ${_patientNameController.text},\nYour bill ($finalBillNo) is attached. Get well soon!',
);
// (Ensure you are using the latest syntax supported by your installed package version, often Share.shareXFiles is fine, but the warning suggests SharePlus.instance.share if it's the absolute newest version).

      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}