class CartItem {
  final String productId;
  final String restaurantId;
  final String name;
  final String? imageUrl;
  final double price;
  int quantity;
  final Map<String, dynamic> options;

  CartItem({
    required this.productId,
    required this.restaurantId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.options,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'restaurantId': restaurantId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'options': options,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: (map['productId'] ?? '').toString(),
      restaurantId: (map['restaurantId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      imageUrl: map['imageUrl']?.toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      options: Map<String, dynamic>.from(map['options'] ?? const {}),
    );
  }
}
