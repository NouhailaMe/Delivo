import 'package:flutter/material.dart';
import '../permissions/notification_permission.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPageThree extends StatelessWidget {
  const OnboardingPageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
  'assets/stickers/onboarding_tracking.svg',
  height: 220,
),

          const SizedBox(height: 40),
          const Text(
            'Delivered in minutes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our couriers pick up your order and bring it to you quickly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF0F172A),
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 48),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPermissionScreen(),
      ),
    );
  },
  child: const Text('Continue'),
),
        ],
      ),
    );
  }
}
