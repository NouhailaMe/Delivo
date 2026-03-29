import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_card_service.dart';
import '../../models/payment_card.dart';
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
  String _selectedDelivery = 'Standard';
  bool _placingOrder = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  String? _selectedCardId;
  PaymentCard? _selectedCard;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    super.dispose();
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
      final deliveryFee = _deliveryFeeFor(_selectedDelivery);
      final total = cart.totalPrice + serviceFee + deliveryFee;

      Map<String, dynamic>? paymentCard;
      if (_selectedPayment == 'Card') {
        var card = _selectedCard;
        if (card == null && _cardNumberController.text.trim().isNotEmpty) {
          card = await _saveCardFromForm(user.uid);
          if (!mounted) return;
          if (card == null) {
            setState(() => _placingOrder = false);
            return;
          }
          setState(() {
            _selectedCard = card;
            _selectedCardId = card?.id;
          });
        }

        if (card == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or add a card.')),
          );
          setState(() => _placingOrder = false);
          return;
        }

        paymentCard = {
          'id': card.id,
          ...card.toMap(),
        };
      }
      final orderId = await _orderService.createOrder(
        userId: user.uid,
        restaurantId: cart.restaurantId ?? '',
        restaurantName: cart.restaurantName ?? 'Restaurant',
        items: cart.items.map((e) => e.toMap()).toList(),
        productsSubtotal: cart.totalPrice,
        deliveryFee: deliveryFee,
        serviceFee: serviceFee,
        total: total,
        paymentMethod: _selectedPayment,
        deliveryOption: _selectedDelivery,
        paymentCard: paymentCard,
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
    final deliveryFee = _deliveryFeeFor(_selectedDelivery);
    final total = cart.totalPrice + serviceFee + deliveryFee;
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
            child: Column(
              children: [
                _deliveryTile(
                  label: 'Standard',
                  eta: '20-30 min',
                  fee: 0,
                ),
                const Divider(height: 18),
                _deliveryTile(
                  label: 'Express',
                  eta: '10-15 min',
                  fee: 10,
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
                  setState(() {
                    _selectedPayment = value;
                    if (value != 'Card') {
                      _selectedCard = null;
                      _selectedCardId = null;
                    }
                  });
                },
              ),
            ),
          ),
          if (_selectedPayment == 'Card') ...[
            const SizedBox(height: 12),
            _cardSelectionSection(),
          ],
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
                _summaryRow(
                  'Delivery',
                  deliveryFee == 0 ? 'FREE' : '${deliveryFee.toStringAsFixed(2)} MAD',
                ),
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

  Widget _deliveryTile({
    required String label,
    required String eta,
    required double fee,
  }) {
    return RadioListTile<String>(
      value: label,
      groupValue: _selectedDelivery,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedDelivery = value);
      },
      title: Text(
        '$label - $eta',
        style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
      ),
      secondary: Text(
        fee == 0 ? 'FREE' : '+${fee.toStringAsFixed(0)} MAD',
        style: TextStyle(
          color: fee == 0 ? const Color(0xFF0D8A6A) : navy,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _cardSelectionSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('Please log in to manage cards.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved cards',
            style: TextStyle(fontWeight: FontWeight.w700, color: navy),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<PaymentCard>>(
            stream: PaymentCardService.streamCards(uid),
            builder: (context, snapshot) {
              final cards = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (cards.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('No saved cards yet.'),
                );
              }
              return Column(
                children: cards.map((card) {
                  return RadioListTile<String>(
                    value: card.id,
                    groupValue: _selectedCardId,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCardId = value;
                        _selectedCard = card;
                      });
                    },
                    title: Text('${card.type} **** ${card.last4}'),
                    subtitle: Text(
                      '${card.name}${card.expiry.isNotEmpty ? '  -  ${card.expiry}' : ''}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Add a new card',
            style: TextStyle(fontWeight: FontWeight.w700, color: navy),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Card number'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardNameController,
            decoration: _inputDecoration('Cardholder name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardExpiryController,
            keyboardType: TextInputType.datetime,
            decoration: _inputDecoration('Expiry (MM/YY)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final card = await _saveCardFromForm(uid);
                if (!mounted || card == null) return;
                setState(() {
                  _selectedCard = card;
                  _selectedCardId = card.id;
                });
              },
              child: const Text('Save card'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  double _deliveryFeeFor(String option) {
    return option == 'Express' ? 10.0 : 0.0;
  }

  Future<PaymentCard?> _saveCardFromForm(String uid) async {
    final cleaned = _cardNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid card number')),
      );
      return null;
    }

    final last4 = cleaned.substring(cleaned.length - 4);
    final name = _cardNameController.text.trim().isNotEmpty
        ? _cardNameController.text.trim()
        : 'Cardholder';
    final expiry = _cardExpiryController.text.trim();

    final card = await PaymentCardService.addCard(
      uid: uid,
      type: 'Card',
      last4: last4,
      name: name,
      expiry: expiry,
    );

    if (!mounted) return card;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card saved'),
        backgroundColor: Color(0xFF0D8A6A),
      ),
    );
    return card;
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
