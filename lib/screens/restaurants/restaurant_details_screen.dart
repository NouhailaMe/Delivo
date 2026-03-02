import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_service.dart';
import '../orders/orders_screen.dart';
import '../products/product_details_sheet.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final String restaurantId;
  final String name;
  final String category;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.name,
    required this.category,
  });

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>(); // ✅ FIX

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _header(context),
              Expanded(child: _products(context)),
            ],
          ),

          /// 🟢 GO TO CART BUTTON
          if (!cart.isEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0FA958),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdersScreen(),
                    ),
                  );
                },
                child: Text(
                  'Go to cart • ${cart.totalPrice.toStringAsFixed(0)} MAD',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _products(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirestoreService().getRestaurantProducts(restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: products.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            return ListTile(
              title: Text(data['name']),
              subtitle: Text('${data['price']} MAD'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ProductDetailsSheet(
                      productData: data,
                      restaurantId: restaurantId,
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}