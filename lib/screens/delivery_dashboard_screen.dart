import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final driverUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Dashboard"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No pending orders"),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {

              final order = orders[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Order ID: ${order.id}"),
                  subtitle: Text(
                      "Total: ${order['total']} MAD"),
                  trailing: ElevatedButton(
                    onPressed: () async {

                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(order.id)
                          .update({
                        'driverId': driverUid,
                        'status': 'accepted',
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                              Text("Order Accepted"),
                        ),
                      );
                    },
                    child: const Text("Accept"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}