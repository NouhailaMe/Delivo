import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../widgets/favorite_button.dart';

class ProductDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String restaurantId;
  final String restaurantName;

  const ProductDetailsSheet({
    super.key,
    required this.productData,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  int quantity = 1;
  final Map<String, dynamic> selectedOptions = {};

  String get productId => (widget.productData['id'] ?? '').toString();
  String get name => (widget.productData['name'] ?? '').toString();
  String get description => (widget.productData['description'] ?? '').toString();
  String? get imageUrl => widget.productData['imageUrl']?.toString();
  double get price => (widget.productData['price'] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _circleIcon(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _heroImage(),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${price.toStringAsFixed(2)} MAD',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description.isEmpty ? 'No description available.' : description,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _quantityBox(),
                    const SizedBox(height: 26),
                    _OptionsSection(
                      restaurantId: widget.restaurantId,
                      productId: productId,
                      selectedOptions: selectedOptions,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Others also bought',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RelatedProducts(
                      restaurantId: widget.restaurantId,
                      restaurantName: widget.restaurantName,
                      currentProductId: productId,
                      onSelect: (data) {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => ProductDetailsSheet(
                            productData: data,
                            restaurantId: widget.restaurantId,
                            restaurantName: widget.restaurantName,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D8A6A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _addToCart,
                  child: Text(
                    'Add $quantity for ${(price * quantity).toStringAsFixed(2)} MAD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroImage() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  )
                : _imageFallback(),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: FavoriteButton(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              productId: productId,
              name: name,
              imageUrl: imageUrl,
              price: price,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quantityBox() {
    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EBF0),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
              icon: const Icon(Icons.remove, size: 28),
            ),
            Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => quantity++),
              icon: const Icon(Icons.add, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood,
        size: 52,
        color: Color(0xFF6B7280),
      ),
    );
  }

  void _addToCart() {
    context.read<CartService>().addToCart(
          item: CartItem(
            productId: productId,
            restaurantId: widget.restaurantId,
            name: name,
            imageUrl: imageUrl,
            price: price,
            quantity: quantity,
            options: selectedOptions,
          ),
          restaurantName: widget.restaurantName,
        );

    Navigator.pop(context);
  }
}

class _OptionsSection extends StatelessWidget {
  final String restaurantId;
  final String productId;
  final Map<String, dynamic> selectedOptions;
  final VoidCallback onChanged;

  const _OptionsSection({
    required this.restaurantId,
    required this.productId,
    required this.selectedOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('products')
          .doc(productId)
          .collection('options')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString();
            final values = List<String>.from(data['values'] ?? const []);
            final type = (data['type'] ?? 'single').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (type == 'single')
                      ...values.map(
                        (value) => RadioListTile<String>(
                          dense: true,
                          value: value,
                          groupValue: selectedOptions[doc.id] as String?,
                          title: Text(value),
                          onChanged: (newValue) {
                            if (newValue == null) return;
                            selectedOptions[doc.id] = newValue;
                            onChanged();
                          },
                        ),
                      ),
                    if (type == 'multiple')
                      ...values.map(
                        (value) => CheckboxListTile(
                          dense: true,
                          value: (selectedOptions[doc.id] as List<dynamic>? ?? const [])
                              .contains(value),
                          title: Text(value),
                          onChanged: (selected) {
                            final list = (selectedOptions[doc.id] as List<dynamic>? ?? [])
                                .map((e) => e.toString())
                                .toList();
                            if (selected == true) {
                              if (!list.contains(value)) list.add(value);
                            } else {
                              list.remove(value);
                            }
                            selectedOptions[doc.id] = list;
                            onChanged();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RelatedProducts extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String currentProductId;
  final void Function(Map<String, dynamic>) onSelect;

  const _RelatedProducts({
    required this.restaurantId,
    required this.restaurantName,
    required this.currentProductId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('products')
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs
                .where((doc) => doc.id != currentProductId)
                .take(6)
                .toList() ??
            [];

        if (docs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              data['id'] = docs[index].id;
              final imageUrl = data['imageUrl']?.toString();
              final name = (data['name'] ?? '').toString();
              final price = (data['price'] as num?)?.toDouble() ?? 0;
              final productId = (data['id'] ?? '').toString();

              return GestureDetector(
                onTap: () => onSelect(data),
                child: SizedBox(
                  width: 155,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _fallbackCard(),
                                      )
                                    : _fallbackCard(),
                              ),
                            ),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: FavoriteButton(
                                  restaurantId: restaurantId,
                                  restaurantName: restaurantName,
                                  productId: productId,
                                  name: name,
                                  imageUrl: imageUrl,
                                  price: price,
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: InkWell(
                                onTap: () => _addToCart(context, productId, name, imageUrl, price),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(Icons.add, color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _addToCart(
    BuildContext context,
    String productId,
    String name,
    String? imageUrl,
    double price,
  ) {
    context.read<CartService>().addToCart(
          item: CartItem(
            productId: productId,
            restaurantId: restaurantId,
            name: name,
            imageUrl: imageUrl,
            price: price,
            quantity: 1,
            options: const {},
          ),
          restaurantName: restaurantName,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added to cart')),
    );
  }

  Widget _fallbackCard() {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
