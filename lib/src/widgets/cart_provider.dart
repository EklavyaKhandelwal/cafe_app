import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final Map<MenuItem, int> _cartItems = {};

  Map<MenuItem, int> get cartItems => Map.unmodifiable(_cartItems);

  /// Adds one quantity of [item] to the cart.
  void addToCart(MenuItem item) {
    _cartItems[item] = (_cartItems[item] ?? 0) + 1;
    notifyListeners();
  }

  /// Removes one quantity of [item] from the cart.
  /// Removes the item completely if quantity becomes zero.
  void removeFromCart(MenuItem item) {
    if (_cartItems[item] != null) {
      if (_cartItems[item]! > 1) {
        _cartItems[item] = _cartItems[item]! - 1;
      } else {
        _cartItems.remove(item);
      }
      notifyListeners();
    }
  }

  /// Sets the quantity of [item] directly.
  /// Removes the item if [quantity] is zero or less.
  void setItemQuantity(MenuItem item, int quantity) {
    if (quantity <= 0) {
      _cartItems.remove(item);
    } else {
      _cartItems[item] = quantity;
    }
    notifyListeners();
  }

  /// Returns total number of items in the cart.
  int get totalItems =>
      _cartItems.values.fold(0, (previous, quantity) => previous + quantity);

  /// Calculates the total price of all items in the cart.
  double calculateTotal() {
    return _cartItems.entries.fold(
      0.0,
          (sum, entry) => sum + entry.key.price * entry.value,
    );
  }

  /// Clears the entire cart.
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
