import 'package:hive/hive.dart';

// This connects the generated file
part 'medicart_models.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  double? price;

  @HiveField(2)
  String? batchNumber;
}

@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)
  String? patientName;

  @HiveField(1)
  String? billNumber;

  @HiveField(2)
  DateTime? date;

  @HiveField(3)
  double? subtotal;

  @HiveField(4)
  double? discount;

  @HiveField(5)
  double? grandTotal;

  @HiveField(6)
  bool isPaid = false;

  @HiveField(7)
  List<InvoiceItem>? items;

  @HiveField(8)
  String? imagePath;
}

@HiveType(typeId: 2)
class InvoiceItem {
  @HiveField(0)
  String? name;

  @HiveField(1)
  int? qty;

  @HiveField(2)
  double? price;
}