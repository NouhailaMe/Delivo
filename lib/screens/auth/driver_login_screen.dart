import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../delivery_dashboard_screen.dart';
import '../../services/user_profile_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() =>
      _DriverLoginScreenState();
}

class _DriverLoginScreenState
    extends State<DriverLoginScreen> {
  static const forcedDriverEmail = UserProfileService.driverEmail;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> loginDriver() async {
    try {
      setState(() => isLoading = true);

      final credential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      final email = credential.user!.email?.toLowerCase();

      if (email == forcedDriverEmail) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
          'role': 'driver',
          'email': forcedDriverEmail,
          'name': UserProfileService.displayNameFromEmail(forcedDriverEmail),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      final userData = userDoc.data() ?? const <String, dynamic>{};
      final role = (userData['role'] ?? '').toString();

      if (!userDoc.exists ||
          role != 'driver') {

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Access denied. Not a driver.")),
        );

        return;
      }

      await UserProfileService.syncCurrentUser(
        explicitRole: 'driver',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DeliveryDashboardScreen(),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Driver Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: emailController,
              decoration:
                  const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(
                labelText: "Password",
              ),
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: loginDriver,
                    child:
                        const Text("Login"),
                  ),
          ],
        ),
      ),
    );
  }
}
