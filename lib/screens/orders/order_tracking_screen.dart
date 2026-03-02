import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState
    extends State<OrderTrackingScreen> {

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    simulateDriver(); // 🔥 Demo movement
  }

  /// 🔥 SIMULATE DRIVER MOVEMENT (FOR DEMO)
  void simulateDriver() async {
    await Future.delayed(const Duration(seconds: 5));

    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
      'driverLat': 33.5920,
      'driverLng': -7.6010,
      'status': 'on_the_way',
    });

    await Future.delayed(const Duration(seconds: 5));

    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
      'driverLat': 33.5898,
      'driverLng': -7.6039,
      'status': 'delivered',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData ||
              snapshot.data!.data() == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final deliveryPosition = LatLng(
              data['deliveryLat'],
              data['deliveryLng']);

          final driverPosition = LatLng(
              data['driverLat'],
              data['driverLng']);

          final status = data['status'];

          /// 🔥 AUTO FOLLOW DRIVER
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(driverPosition, 15);
          });

          return Stack(
            children: [

              /// 🗺 MAP
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: driverPosition,
                  initialZoom: 15,
                ),
                children: [

                  /// MAP TILES
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName:
                        'com.example.delivo',
                  ),

                  /// ROUTE LINE
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          driverPosition,
                          deliveryPosition,
                        ],
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                  /// MARKERS
                  MarkerLayer(
                    markers: [

                      /// 🏠 DELIVERY LOCATION
                      Marker(
                        point: deliveryPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.home,
                          color: Colors.red,
                          size: 35,
                        ),
                      ),

                      /// 🚚 DRIVER
                      Marker(
                        point: driverPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.green,
                          size: 35,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// 🟢 STATUS CARD
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        "Order Status: $status",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Your driver is on the way 🚴",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}