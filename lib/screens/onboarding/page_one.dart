import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPageOne extends StatelessWidget {
  const OnboardingPageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DELIVO',
            style: TextStyle(
              fontSize: 32,
              letterSpacing: 4,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),

          // Placeholder for illustration (sticker)
          SvgPicture.asset(
              'assets/stickers/onboarding_delivery.svg',
              height: 220,
          ),


          const SizedBox(height: 40),
          const Text(
            'Explore local stores',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Find nearby restaurants, shops, and markets around you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
