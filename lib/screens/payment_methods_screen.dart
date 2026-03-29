import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  static const navy = Color(0xFF0F172A);

  final List<_PaymentCard> _cards = [];

  void _addCard() {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    String selectedType = 'Visa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add new card',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy),
              ),
              const SizedBox(height: 16),

              // Card type selector
              Row(
                children: ['Visa', 'Mastercard', 'CIH', 'Attijariwafa'].map((type) {
                  final selected = selectedType == type;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? navy : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : navy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              _modalField(controller: numberCtrl, label: 'Card number', keyboardType: TextInputType.number),
              _modalField(controller: nameCtrl, label: 'Cardholder name'),
              _modalField(controller: expiryCtrl, label: 'Expiry (MM/YY)', keyboardType: TextInputType.datetime),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (numberCtrl.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid card number')),
                      );
                      return;
                    }
                    final last4 = numberCtrl.text.replaceAll(' ', '');
                    setState(() {
                      _cards.add(_PaymentCard(
                        type: selectedType,
                        last4: last4.length >= 4 ? last4.substring(last4.length - 4) : last4,
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Cardholder',
                        expiry: expiryCtrl.text.trim(),
                      ));
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Card added successfully!'),
                        backgroundColor: Color(0xFF0D8A6A),
                      ),
                    );
                  },
                  child: const Text('Add card', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  IconData _cardIcon(String type) {
    switch (type) {
      case 'Visa':
        return Icons.credit_card;
      case 'Mastercard':
        return Icons.credit_card_outlined;
      default:
        return Icons.account_balance_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment methods',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Saved payment methods',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

          if (_cards.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card_off_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('No cards saved yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          ..._cards.asMap().entries.map((entry) {
            final card = entry.value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(_cardIcon(card.type), color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card.type} •••• ${card.last4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${card.name}${card.expiry.isNotEmpty ? '  ·  ${card.expiry}' : ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _cards.removeAt(entry.key));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card removed')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  ),
                ],
              ),
            );
          }),

          // Add card button
          GestureDetector(
            onTap: _addCard,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: navy),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Add new card',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: navy),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Other methods', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),

          _item(icon: Icons.account_balance_wallet_outlined, label: 'Cash on delivery', trailing: '✅ Active'),
          _item(icon: Icons.local_atm_outlined, label: 'Pay at counter', trailing: '✅ Active'),
        ],
      ),
    );
  }

  Widget _item({required IconData icon, required String label, String? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PaymentCard {
  final String type;
  final String last4;
  final String name;
  final String expiry;

  const _PaymentCard({
    required this.type,
    required this.last4,
    required this.name,
    required this.expiry,
  });
}
