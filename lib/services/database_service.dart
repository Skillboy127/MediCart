import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/medicart_models.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register the blueprints we just generated
    Hive.registerAdapter(MedicineAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    
    // Open the storage boxes
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox<Invoice>('invoices');
  }

  Box<Medicine> get medicinesBox => Hive.box<Medicine>('medicines');
  Box<Invoice> get invoicesBox => Hive.box<Invoice>('invoices');

  // --- Helper Methods to keep your UI clean ---
  
  Future<void> saveMedicine(Medicine med) async {
    if (med.isInBox) {
      await med.save(); // Updates if it already exists
    } else {
      await medicinesBox.add(med); // Adds new
    }
  }
  Future<void> deleteMedicine(Medicine med) async {
    await med.delete(); // Hive automatically removes it from the box
  }

  Future<void> saveInvoice(Invoice invoice) async {
    await invoicesBox.add(invoice);
  }

  Future<void> deleteInvoice(Invoice invoice) async {
    await invoice.delete();
  }

  // --- CSV Import ---
  Future<void> importMedicinesFromCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

        if (result != null) {
      File file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      
      // Normalize line endings
      final normalized = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      
      List<List<dynamic>> csvTable = const CsvToListConverter(
        eol: '\n',
      ).convert(normalized);

      if (csvTable.isNotEmpty && csvTable.first[0].toString().toLowerCase().contains('name')) {
        csvTable.removeAt(0); // Skip header
      }

      for (var row in csvTable) {
        if (row.isNotEmpty && row[0].toString().trim().isNotEmpty) {
          final med = Medicine()
            ..name = row[0].toString().trim()
            ..price = double.tryParse(row[1].toString().trim()) ?? 0.0
            ..batchNumber = row.length > 2 ? row[2].toString().trim() : 'N/A';
          await medicinesBox.add(med);
        }
      }
    }
  }
}