import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/order_service.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  static const navy = Color(0xFF0F172A);
  static const green = Color(0xFF0D8A6A);

  final _orderService = OrderService();
  StreamSubscription<Position>? _positionSub;
  String? _liveOrderId;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String? get _driverId => FirebaseAuth.instance.currentUser?.uid;

  Future<Position?> _currentPosition() async {
    final granted = await LocationService.requestLocationPermission();
    if (!granted) return null;
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    final driverId = _driverId;
    if (driverId == null) return;

    final pos = await _currentPosition();
    if (pos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission required.')),
      );
      return;
    }

    await _orderService.acceptOrder(
      orderId: orderId,
      driverId: driverId,
      driverLat: pos.latitude,
      driverLng: pos.longitude,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order accepted.')),
    );
  }

  Future<void> _updateLocationNow(String orderId) async {
    final pos = await _currentPosition();
    if (pos == null) return;
    await _orderService.updateDriverLocation(
      orderId: orderId,
      lat: pos.latitude,
      lng: pos.longitude,
    );
  }

  Future<void> _toggleLive(String orderId) async {
    if (_liveOrderId == orderId) {
      await _positionSub?.cancel();
      _positionSub = null;
      if (!mounted) return;
      setState(() => _liveOrderId = null);
      return;
    }

    final granted = await LocationService.requestLocationPermission();
    if (!granted) return;

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 15,
      ),
    ).listen((position) async {
      await _orderService.updateDriverLocation(
        orderId: orderId,
        lat: position.latitude,
        lng: position.longitude,
      );
    });

    if (!mounted) return;
    setState(() => _liveOrderId = orderId);
  }

  Future<void> _advanceStatus(String orderId, String currentStatus) async {
    String next = currentStatus;
    if (currentStatus == OrderStatus.accepted) next = OrderStatus.pickedUp;
    if (currentStatus == OrderStatus.pickedUp) next = OrderStatus.onTheWay;
    if (currentStatus == OrderStatus.onTheWay) next = OrderStatus.delivered;

    if (next == currentStatus) return;
    await _orderService.updateStatus(orderId: orderId, status: next);
    if (next == OrderStatus.delivered && _liveOrderId == orderId) {
      await _toggleLive(orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = _driverId;
    if (driverId == null) {
      return const Scaffold(
        body: Center(child: Text('Driver not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          const Text(
            'Available orders',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _orderService.availableOrders(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _empty('No pending orders');
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  return _OrderCard(
                    title: (data['restaurantName'] ?? 'Restaurant').toString(),
                    subtitle:
                        '${((data['itemsCount'] as num?)?.toInt() ?? 0)} item(s) · ${((data['total'] as num?) ?? 0).toStringAsFixed(2)} MAD',
                    actionLabel: 'Accept',
                    actionColor: green,
                    onAction: () => _acceptOrder(doc.id),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'My active orders',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _orderService.driverActiveOrders(driverId),
            builder: (context, snapshot) {
              final docs = (snapshot.data?.docs ?? [])
                  .where((doc) {
                    final status = (doc.data()['status'] ?? '').toString();
                    return OrderStatus.activeForDriver.contains(status);
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
                return _empty('No active delivery');
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final status = (data['status'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                          (data['restaurantName'] ?? 'Restaurant').toString(),
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${_statusLabel(status)}',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateLocationNow(doc.id),
                                child: const Text('Update location now'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _liveOrderId == doc.id ? Colors.grey : navy,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _toggleLive(doc.id),
                                child: Text(
                                  _liveOrderId == doc.id
                                      ? 'Stop live'
                                      : 'Start live',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          onPressed: () => _advanceStatus(doc.id, status),
                          child: Text(_nextStatusLabel(status)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  String _nextStatusLabel(String status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Mark picked up';
      case OrderStatus.pickedUp:
        return 'Mark on the way';
      case OrderStatus.onTheWay:
        return 'Mark delivered';
      default:
        return 'Update status';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      default:
        return status;
    }
  }
}

class _OrderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  const _OrderCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: _DeliveryDashboardScreenState.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _DeliveryDashboardScreenState.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
