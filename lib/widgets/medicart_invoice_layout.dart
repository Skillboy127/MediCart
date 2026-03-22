import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MediCartInvoiceWidget extends StatelessWidget {
  final String patientName;
  final String billNumber;
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final double discount;

  const MediCartInvoiceWidget({
    super.key,
    required this.patientName,
    required this.billNumber,
    required this.date,
    required this.items,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    double subtotal = items.fold(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['qty'] ?? 1)));
    double grandTotal = subtotal - discount;

    return Container(
      width: 400, // Standard sharing width
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Text('Your Bill', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text('Bill No: $billNumber', style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Customer: $patientName', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Date: ${DateFormat('dd-MMM-yyyy').format(date)}', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          const Divider(color: Colors.black26, thickness: 1),
          
          // Items List
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
    if (item['batch'] != null && item['batch'].toString().trim().isNotEmpty)
      Text('[Batch No: ${item['batch']}]', style: const TextStyle(fontSize: 12, color: Colors.black54)),
  ],
),
                Text('${item['qty']} @ ₹${item['price'].toStringAsFixed(2)} = ₹${(item['qty'] * item['price']).toStringAsFixed(2)}', 
                     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
              ],
            ),
          )),

          const Divider(color: Colors.black26, thickness: 1),
          const SizedBox(height: 10),
          _buildTotalRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
          _buildTotalRow('Discount:', '-₹${discount.toStringAsFixed(2)}'),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
              Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 40),
          
          // Footer / Consultant Info
          const Text('Consultant: Dr. Sanjay Gupta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
          const Text('PAN NO. AFWPG3331H', style: TextStyle(fontSize: 13, color: Colors.black)),
          const Text('KMC Reg. No. - 32020', style: TextStyle(fontSize: 13, color: Colors.black)),
          const SizedBox(height: 40),
          const Center(
            child: Text('Get well soon !', style: TextStyle(fontSize: 14, color: Colors.black38, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}