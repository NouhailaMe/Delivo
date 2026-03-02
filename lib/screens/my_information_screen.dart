import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'change_phone_screen.dart';
import 'payment_methods_screen.dart';
import 'manage_privacy_screen.dart';

class MyInformationScreen extends StatelessWidget {
  const MyInformationScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          _infoItem(
            icon: Icons.person_outline,
            title: 'Jaguar',
            subtitle: 'Name',
          ),

          _infoItem(
            icon: Icons.email_outlined,
            title: 'kodjoceasar@gmail.com',
            subtitle: 'Email',
          ),

          _infoItem(
            icon: Icons.lock_outline,
            title: 'Change password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          _infoItem(
            icon: Icons.phone_outlined,
            title: 'Change phone number',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePhoneScreen(),
                ),
              );
            },
          ),

          _infoItem(
            icon: Icons.credit_card_outlined,
            title: 'Payment methods',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentMethodsScreen(),
                ),
              );
            },
          ),

          _infoItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Manage privacy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagePrivacyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔹 SINGLE ROW ITEM (FIXED)
  Widget _infoItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap, // ✅ THIS WAS MISSING
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
