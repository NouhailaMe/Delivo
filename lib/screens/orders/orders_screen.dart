import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../cart/cart_screen.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cart = context.watch<CartService>();
    final service = OrderService();

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your orders')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: navy,
                height: 0.95,
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.activeUserOrders(uid),
              builder: (context, snapshot) {
                final docs = (snapshot.data?.docs ?? [])
                    .where((doc) {
                      final status = (doc.data()['status'] ?? '').toString();
                      return OrderStatus.activeForUser.contains(status);
                    })
                    .toList()
                  ..sort((a, b) {
                    final left = a.data()['createdAt'];
                    final right = b.data()['createdAt'];
                    if (left is Timestamp && right is Timestamp) {
                      return right.compareTo(left);
                    }
                    return 0;
                  });
                if (docs.isEmpty) {
                  return _emptyTrackCard();
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    return _ActiveOrderCard(
                      data: data,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(orderId: doc.id),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Continue your order',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: navy,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                if (!cart.isEmpty)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (cart.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'No items in cart. Add products from restaurants to continue.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            else
              _ContinueOrderCard(
                cart: cart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFF3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history, size: 34, color: Color(0xFF475569)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Need to review past orders or reorder?\nCheck your order history',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTrackCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFF0F2F5),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Track your orders',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your ongoing orders will be listed here',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ActiveOrderCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? '').toString();
    final total = ((data['total'] as num?) ?? 0).toDouble();
    final restaurant = (data['restaurantName'] ?? 'Restaurant').toString();
    final itemsCount = (data['itemsCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: OrdersScreen.navy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant,
                    style: const TextStyle(
                      color: OrdersScreen.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemsCount item${itemsCount > 1 ? 's' : ''} · ${_label(status)}',
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
            Text(
              '${total.toStringAsFixed(2)} MAD',
              style: const TextStyle(
                color: OrdersScreen.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  static String _label(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted by courier';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      default:
        return status;
    }
  }
}

class _ContinueOrderCard extends StatelessWidget {
  final CartService cart;
  final VoidCallback onTap;

  const _ContinueOrderCard({
    required this.cart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu, color: OrdersScreen.navy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cart.restaurantName ?? 'Restaurant',
                    style: const TextStyle(
                      color: OrdersScreen.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
            Text(
              '${cart.totalPrice.toStringAsFixed(2)} MAD',
              style: const TextStyle(
                color: OrdersScreen.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
