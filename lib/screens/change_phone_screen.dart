import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/phone_auth_service.dart';
import '../services/user_profile_service.dart';


class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  static const navy = Color(0xFF0F172A);
  final _phoneController = TextEditingController();
  final _phoneAuthService = PhoneAuthService();
  String _countryCode = '+212';
  bool _loading = false;

  final List<Map<String, String>> _countries = const [
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Morocco'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        children: _countries.map((c) => ListTile(
          leading: Text(c['flag']!, style: const TextStyle(fontSize: 22)),
          title: Text(c['name']!),
          trailing: Text(c['code']!, style: const TextStyle(fontWeight: FontWeight.w700)),
          onTap: () {
            setState(() => _countryCode = c['code']!);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  String _normalizePhone() {
    final raw = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final noLeadingZero = raw.startsWith('0') ? raw.substring(1) : raw;
    return '$_countryCode$noLeadingZero';
  }

  Future<void> _savePhone() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }
    setState(() => _loading = true);
    final phoneNumber = _normalizePhone();

    await _phoneAuthService.sendCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _loading = false);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          UserProfileService.updateUserFields(
            uid: user.uid,
            fields: {'phone': phoneNumber},
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS sent to $phoneNumber — please verify')),
        );
        Navigator.pop(context);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      onTimeout: (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      },
    );
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
          'Change phone number',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your new phone number',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(_countryCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _loading ? null : _savePhone,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_loading ? 'Sending…' : 'Send verification SMS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
