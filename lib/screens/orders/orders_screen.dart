import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../orders/order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: navy,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection('orders')
    .snapshots(),

        builder: (context, snapshot) {
          // ignore: avoid_print
          print("Snapshot data: ${snapshot.data}");

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No orders yet"),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {

              final order = orders[index];

              return Card(
                margin:
                    const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                      "Order ID: ${order.id.substring(0,6)}"),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Total: ${order['total']} MAD"),
                      Text(
                          "Status: ${order['status']}"),
                    ],
                  ),
                  trailing: const Icon(
                      Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(
                                orderId:
                                    order.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}