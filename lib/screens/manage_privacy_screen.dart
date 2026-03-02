import 'package:flutter/material.dart';

class ManagePrivacyScreen extends StatelessWidget {
  const ManagePrivacyScreen({super.key});

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
          'Manage privacy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: const [
          _PrivacyItem('Allow notifications'),
          _PrivacyItem('Location access'),
          _PrivacyItem('Personalized offers'),
          _PrivacyItem('Data analytics'),
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final String label;
  const _PrivacyItem(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Switch(value: true, onChanged: (_) {}),
        ],
      ),
    );
  }
}
