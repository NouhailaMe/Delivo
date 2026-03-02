import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './orders/orders_screen.dart';
import './orders/order_tracking_screen.dart';
import 'my_information_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔵 TOP HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.close, color: Colors.white),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Help',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Hello, Jaguar!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _sectionTitle('Account'),

              /// 📦 My Orders
              _menuItem(
                context: context,
                icon: Icons.receipt_long,
                label: 'My orders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdersScreen(),
                    ),
                  );
                },
              ),

              /// 🚚 Track Active Order
              _menuItem(
                context: context,
                icon: Icons.local_shipping,
                label: 'Track active order',
                onTap: () async {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: 'uid123')
                      .where('status', isNotEqualTo: 'delivered')
                      .limit(1)
                      .get();

                  if (snapshot.docs.isNotEmpty) {
                    final orderId = snapshot.docs.first.id;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(orderId: orderId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No active orders"),
                      ),
                    );
                  }
                },
              ),

              /// 👤 My Information
              _menuItem(
                context: context,
                icon: Icons.person_outline,
                label: 'My information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyInformationScreen(),
                    ),
                  );
                },
              ),

              _menuItem(
                context: context,
                icon: Icons.card_giftcard,
                label: 'Share and earn!',
              ),
              _menuItem(
                context: context,
                icon: Icons.local_offer_outlined,
                label: 'Promocodes',
              ),
              _menuItem(
                context: context,
                icon: Icons.help_outline,
                label: 'FAQ',
              ),

              const SizedBox(height: 12),

              _menuItem(
                context: context,
                icon: Icons.delete_outline,
                label: 'Delete my account',
                isDanger: true,
              ),
              _menuItem(
                context: context,
                icon: Icons.logout,
                label: 'Log out',
                isDanger: true,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? Colors.red : navy,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDanger ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}