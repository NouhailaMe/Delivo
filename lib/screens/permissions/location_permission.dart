import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_signup_screen.dart';
import '../../services/location_service.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends State<LocationPermissionScreen> {

  bool isLoading = false;

  Future<void> handleEnableLocation() async {

    if (isLoading) return;

    setState(() => isLoading = true);

    final locationData =
        await LocationService.getUserLocation();

    if (!mounted) return;

    if (locationData != null) {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "location": locationData,
        }, SetOptions(merge: true));
      }

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginSignupScreen(),
        ),
      );

    } else {

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Unable to get location. Please enable GPS."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            SvgPicture.asset(
              'assets/stickers/location.svg',
              height: 220,
            ),

            const SizedBox(height: 40),

            const Text(
              'Enable location',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'We use your location to show nearby stores and delivery options.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                minimumSize:
                    const Size(double.infinity, 48),
              ),
              onPressed:
                  isLoading ? null : handleEnableLocation,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Use my current location'),
            ),

            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginSignupScreen(),
                        ),
                      );
                    },
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
