import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.length;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  /// ✅ ADD TO CART
  void addToCart(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  /// ✅ REMOVE ITEM
  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  /// ✅ CLEAR CART
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}