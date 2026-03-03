import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/order_service.dart';
import '../services/user_profile_service.dart';
import 'auth/login_signup_screen.dart';
import 'my_information_screen.dart';
import 'orders/order_tracking_screen.dart';
import 'orders/orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const navy = Color(0xFF0F172A);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
      (_) => false,
    );
  }

  Future<void> _trackActiveOrder(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .get();

    if (!context.mounted) return;

    QueryDocumentSnapshot<Map<String, dynamic>>? activeDoc;
    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] ?? '').toString();
      if (OrderStatus.activeForUser.contains(status)) {
        activeDoc = doc;
        break;
      }
    }

    if (activeDoc != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: activeDoc!.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active orders')),
      );
    }
  }

  Future<void> _shareAndEarn(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final code = uid.length > 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase();
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Referral code copied: $code')),
    );
  }

  void _promocodes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Promocodes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy),
            ),
            SizedBox(height: 12),
            _PromoTile(code: 'WELCOME10', desc: '10% off your next order'),
            _PromoTile(code: 'FREEDEL', desc: 'Free delivery for 1 order'),
          ],
        ),
      ),
    );
  }

  void _faq(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _FaqScreen()),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This action is permanent. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Please log in again then retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'no-email';
    final name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : UserProfileService.displayNameFromEmail(email);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Hello, $name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle('Account'),
              _menuItem(
                context: context,
                icon: Icons.receipt_long,
                label: 'My orders',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              _menuItem(
                context: context,
                icon: Icons.local_shipping,
                label: 'Track active order',
                onTap: () => _trackActiveOrder(context),
              ),
              _menuItem(
                context: context,
                icon: Icons.person_outline,
                label: 'My information',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyInformationScreen()),
                ),
              ),
              _menuItem(
                context: context,
                icon: Icons.card_giftcard,
                label: 'Share and earn!',
                onTap: () => _shareAndEarn(context),
              ),
              _menuItem(
                context: context,
                icon: Icons.local_offer_outlined,
                label: 'Promocodes',
                onTap: () => _promocodes(context),
              ),
              _menuItem(
                context: context,
                icon: Icons.help_outline,
                label: 'FAQ',
                onTap: () => _faq(context),
              ),
              const SizedBox(height: 8),
              _menuItem(
                context: context,
                icon: Icons.delete_outline,
                label: 'Delete my account',
                isDanger: true,
                onTap: () => _deleteAccount(context),
              ),
              _menuItem(
                context: context,
                icon: Icons.logout,
                label: 'Log out',
                isDanger: true,
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? Colors.red : navy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDanger ? Colors.red : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  final String code;
  final String desc;

  const _PromoTile({
    required this.code,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.w700, color: ProfileScreen.navy),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(desc)),
        ],
      ),
    );
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ProfileScreen.navy,
        title: const Text('FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FaqTile(
            title: 'How do I track my order?',
            answer: 'Open Orders tab and tap your active order.',
          ),
          _FaqTile(
            title: 'How do I change my address?',
            answer: 'Tap the location chip at top and pick a new location on map.',
          ),
          _FaqTile(
            title: 'How do I contact support?',
            answer: 'Use Help from profile or contact your project admin.',
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String answer;

  const _FaqTile({
    required this.title,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: ProfileScreen.navy,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
