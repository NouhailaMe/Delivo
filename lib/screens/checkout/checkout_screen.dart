import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/cart_service.dart';
import '../orders/order_tracking_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  final MapController _mapController = MapController();

  LatLng selectedLocation = LatLng(33.5898, -7.6039);

  String selectedPayment = "Cash";
  bool isLoading = false;

Future<void> placeOrder(CartService cart) async {
  try {
    setState(() => isLoading = true);

    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc();

    await orderRef.set({
      'userId': FirebaseAuth.instance.currentUser!.uid,      'restaurantId': 'abc123',
      'total': cart.totalPrice,
      'status': 'preparing',
      'createdAt': Timestamp.now(),
      'paymentMethod': selectedPayment,
      'deliveryLat': selectedLocation.latitude,
      'deliveryLng': selectedLocation.longitude,
      'driverLat': 33.5905,
      'driverLng': -7.6045,
    });

    print("ORDER CREATED: ${orderRef.id}");

    cart.clearCart();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderTrackingScreen(orderId: orderRef.id),
      ),
    );

  } catch (e) {
    print("FIRESTORE ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error creating order"),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    final serviceFee = cart.totalPrice * 0.05;
    final finalTotal = cart.totalPrice + serviceFee;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Column(
        children: [

          /// 🗺 OPEN STREET MAP
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [

                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 15,
                    onPositionChanged: (position, _) {
                      selectedLocation = position.center!;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.delivo',
                    ),
                  ],
                ),

                const Icon(
                  Icons.location_pin,
                  size: 45,
                  color: Colors.red,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  const SizedBox(height: 10),

                  const ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text(
                      "Move the map to choose your delivery location",
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const Divider(),

                  /// 💳 PAYMENT
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: const Text("Payment Method"),
                    subtitle: Text(selectedPayment),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text("Cash"),
                              onTap: () {
                                setState(() {
                                  selectedPayment = "Cash";
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text("Card"),
                              onTap: () {
                                setState(() {
                                  selectedPayment = "Card";
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        summaryRow("Products",
                            "${cart.totalPrice.toStringAsFixed(2)} MAD"),
                        summaryRow("Delivery", "FREE"),
                        summaryRow("Services",
                            "${serviceFee.toStringAsFixed(2)} MAD"),
                        const SizedBox(height: 10),
                        summaryRow("TOTAL",
                            "${finalTotal.toStringAsFixed(2)} MAD",
                            isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF0FA958),
                              minimumSize:
                                  const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => placeOrder(cart),
                            child: const Text(
                              "Pay to order",
                              style:
                                  TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String title, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}