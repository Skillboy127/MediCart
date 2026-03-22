import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicart_models.dart';

class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({required this.medicine, this.quantity = 1});
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addMedicine(Medicine med) {
    final stateCopy = [...state];
    final existingIndex = stateCopy.indexWhere((item) => item.medicine.key == med.key);
    
    if (existingIndex != -1) {
      // Create a new instance to ensure Riverpod registers the state change
      stateCopy[existingIndex] = CartItem(
        medicine: med, 
        quantity: stateCopy[existingIndex].quantity + 1
      );
    } else {
      stateCopy.add(CartItem(medicine: med));
    }
    state = stateCopy;
  }

  // NEW: The subtraction logic
  void decrementMedicine(Medicine med) {
    final stateCopy = [...state];
    final existingIndex = stateCopy.indexWhere((item) => item.medicine.key == med.key);
    
    if (existingIndex != -1) {
      if (stateCopy[existingIndex].quantity > 1) {
        // Reduce quantity
        stateCopy[existingIndex] = CartItem(
          medicine: med, 
          quantity: stateCopy[existingIndex].quantity - 1
        );
      } else {
        // Remove completely if it hits 0
        stateCopy.removeAt(existingIndex);
      }
      state = stateCopy;
    }
  }

  void removeMedicine(Medicine med) {
    state = state.where((item) => item.medicine.key != med.key).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);