class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic> options;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.options,
  });

  double get total => price * quantity;
}
