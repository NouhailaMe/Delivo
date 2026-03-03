import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  void addToCart({
    required CartItem item,
    required String restaurantName,
  }) {
    if (_restaurantId != null && _restaurantId != item.restaurantId) {
      clearCart();
    }

    _restaurantId = item.restaurantId;
    _restaurantName = restaurantName;

    final existingIndex = _items.indexWhere(
      (it) =>
          it.productId == item.productId &&
          _sameOptions(it.options, item.options),
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
      return;
    }

    final index = _items.indexOf(item);
    if (index < 0) return;

    _items[index].quantity = quantity;
    notifyListeners();
  }

  void increment(CartItem item) => updateQuantity(item, item.quantity + 1);

  void decrement(CartItem item) => updateQuantity(item, item.quantity - 1);

  void removeItem(CartItem item) {
    _items.remove(item);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }

  Map<String, dynamic> toOrderPayload() {
    return {
      'restaurantId': _restaurantId,
      'restaurantName': _restaurantName,
      'items': _items.map((item) => item.toMap()).toList(),
      'itemsCount': itemCount,
      'productsSubtotal': totalPrice,
    };
  }

  bool _sameOptions(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final left = a[key];
      final right = b[key];
      if (left is List && right is List) {
        if (left.length != right.length) return false;
        for (var i = 0; i < left.length; i++) {
          if (left[i] != right[i]) return false;
        }
      } else if (left != right) {
        return false;
      }
    }
    return true;
  }
}
