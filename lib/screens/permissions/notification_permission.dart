import 'package:flutter/material.dart';
import 'location_permission.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sticker placeholder
            SvgPicture.asset(
  'assets/stickers/notification.svg',
  height: 220,
),

            const SizedBox(height: 40),
            const Text(
              'Track your orders',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Allow notifications to get real-time updates about your deliveries.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPermissionScreen(),
                  ),
                );
              },
              child: const Text('Allow notifications'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPermissionScreen(),
                  ),
                );
              },
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}
