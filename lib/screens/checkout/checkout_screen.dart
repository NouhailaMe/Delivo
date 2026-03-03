import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../location/location_picker_screen.dart';
import '../orders/order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const navy = Color(0xFF0F172A);
  static const green = Color(0xFF0D8A6A);

  final _orderService = OrderService();
  Map<String, dynamic>? _selectedAddress;
  String _selectedPayment = 'Cash';
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final address = await LocationService.getCurrentOrSavedLocation();
    if (!mounted) return;
    setState(() => _selectedAddress = address);
  }

  Future<void> _changeAddress() async {
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: (_selectedAddress?['latitude'] as num?)?.toDouble() ?? 33.5898,
          initialLng: (_selectedAddress?['longitude'] as num?)?.toDouble() ?? -7.6039,
        ),
      ),
    );

    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await LocationService.saveUserLocation(uid: uid, location: picked);
    }

    if (!mounted) return;
    setState(() => _selectedAddress = picked);
  }

  Future<void> _placeOrder(CartService cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose delivery location.')),
      );
      return;
    }

    setState(() => _placingOrder = true);

    try {
      final serviceFee = cart.totalPrice * 0.05;
      final total = cart.totalPrice + serviceFee;
      final orderId = await _orderService.createOrder(
        userId: user.uid,
        restaurantId: cart.restaurantId ?? '',
        restaurantName: cart.restaurantName ?? 'Restaurant',
        items: cart.items.map((e) => e.toMap()).toList(),
        productsSubtotal: cart.totalPrice,
        serviceFee: serviceFee,
        total: total,
        paymentMethod: _selectedPayment,
        deliveryAddress: _selectedAddress!,
      );

      cart.clearCart();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to place order now.')),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final serviceFee = cart.totalPrice * 0.05;
    final total = cart.totalPrice + serviceFee;
    final lat = (_selectedAddress?['latitude'] as num?)?.toDouble() ?? 33.5898;
    final lng = (_selectedAddress?['longitude'] as num?)?.toDouble() ?? -7.6039;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: navy),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
        children: [
          _sectionTitle('Your order'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} product${cart.itemCount > 1 ? 's' : ''} from ${cart.restaurantName ?? 'Restaurant'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${item.quantity} x ${item.name}',
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Delivery options'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: navy),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Standard · 20-30 min',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Payment method'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _cardDecoration(),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPayment,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedPayment = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Delivery address'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 170,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.delivo',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 38,
                              height: 38,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 34,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (_selectedAddress?['fullAddress'] ?? 'Choose your location').toString(),
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _changeAddress,
                      icon: const Icon(Icons.edit_outlined, color: navy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _summaryRow('Products', '${cart.totalPrice.toStringAsFixed(2)} MAD'),
                _summaryRow('Delivery', 'FREE'),
                _summaryRow('Services', '${serviceFee.toStringAsFixed(2)} MAD'),
                const Divider(height: 22),
                _summaryRow(
                  'TOTAL',
                  '${total.toStringAsFixed(2)} MAD',
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _placingOrder ? null : () => _placeOrder(cart),
            child: _placingOrder
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Pay to order',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: navy,
        fontWeight: FontWeight.w800,
        fontSize: 30,
        height: 1,
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: navy,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 22 : 18,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: navy,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 22 : 18,
            ),
          ),
        ],
      ),
    );
  }
}
