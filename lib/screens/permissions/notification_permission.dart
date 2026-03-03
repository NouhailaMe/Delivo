import 'package:flutter/material.dart';
import 'location_permission.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/notification_service.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _loading = false;

  Future<void> _requestPermission() async {
    if (_loading) return;
    setState(() => _loading = true);
    final allowed = await NotificationService.init();
    if (!mounted) return;
    setState(() => _loading = false);

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are disabled. You can enable later in settings.'),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPermissionScreen(),
      ),
    );
  }

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
              onPressed: _loading ? null : _requestPermission,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Allow notifications'),
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
