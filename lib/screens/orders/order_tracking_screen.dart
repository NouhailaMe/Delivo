import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const navy = Color(0xFF0F172A);
  final _mapController = MapController();
  final _service = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _service.orderById(widget.orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? const <String, dynamic>{};
          final status = (data['status'] ?? '').toString();
          final driverId = (data['driverId'] ?? '').toString();
          final deliveryAddress = (data['deliveryAddress'] is Map)
              ? Map<String, dynamic>.from(data['deliveryAddress'] as Map)
              : const <String, dynamic>{};
          final canCancel =
              status == OrderStatus.pending && (driverId.isEmpty);

          final deliveryLat = (deliveryAddress['latitude'] as num?)?.toDouble() ??
              (data['deliveryLat'] as num?)?.toDouble() ??
              33.5898;
          final deliveryLng = (deliveryAddress['longitude'] as num?)?.toDouble() ??
              (data['deliveryLng'] as num?)?.toDouble() ??
              -7.6039;

          final driverLat = (data['driverLat'] as num?)?.toDouble() ?? deliveryLat;
          final driverLng = (data['driverLng'] as num?)?.toDouble() ?? deliveryLng;

          final driverPosition = LatLng(driverLat, driverLng);
          final deliveryPosition = LatLng(deliveryLat, deliveryLng);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(driverPosition, 14);
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: driverPosition,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.delivo',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [driverPosition, deliveryPosition],
                        color: const Color(0xFF0D8A6A),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: deliveryPosition,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.home_filled,
                          color: Colors.red,
                          size: 34,
                        ),
                      ),
                      Marker(
                        point: driverPosition,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Color(0xFF0D8A6A),
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: navy),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleFor(status),
                        style: const TextStyle(
                          color: navy,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitleFor(status),
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        (deliveryAddress['fullAddress'] ?? 'Delivery address').toString(),
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressPills(current: status),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                canCancel ? navy : const Color(0xFF9CA3AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: canCancel
                              ? () => _cancelOrder(context, widget.orderId)
                              : null,
                          child: const Text(
                            'Cancel Order',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
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

  String _titleFor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Searching courier';
      case OrderStatus.cancelled:
        return 'Order cancelled';
      case OrderStatus.accepted:
        return 'Courier accepted';
      case OrderStatus.pickedUp:
        return 'Order picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return 'Tracking order';
    }
  }

  String _subtitleFor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Your order is waiting for a courier to accept it.';
      case OrderStatus.cancelled:
        return 'Your order was cancelled before a courier accepted it.';
      case OrderStatus.accepted:
        return 'The courier is heading to the restaurant.';
      case OrderStatus.pickedUp:
        return 'The courier picked your order.';
      case OrderStatus.onTheWay:
        return 'Courier is moving to your location.';
      case OrderStatus.delivered:
        return 'Enjoy your meal.';
      default:
        return 'Live updates appear here.';
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order'),
        content: const Text('Do you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final userId = _service.currentUserId;
    if (userId == null) return;

    final ok = await _service.cancelOrder(orderId: orderId, userId: userId);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot cancel after courier accepts')),
      );
    }
  }
}

class _ProgressPills extends StatelessWidget {
  final String current;

  const _ProgressPills({required this.current});

  static const steps = [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(current);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: steps.map((step) {
        final active = currentIndex >= steps.indexOf(step);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0D8A6A) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _label(step),
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(String step) {
    switch (step) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return step;
    }
  }
}
