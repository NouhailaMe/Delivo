import 'package:flutter/material.dart';
import '../../services/phone_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../main_layout.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final _phoneAuthService = PhoneAuthService();
  bool _loading = false;

  Future<void> _verifyCode() async {
    setState(() => _loading = true);

    try {
      await _phoneAuthService.verifyCode(
        verificationId: widget.verificationId,
        smsCode: _codeController.text.trim(),
      );
      await UserProfileService.syncCurrentUser();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code incorrect')),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Enter the SMS code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SMS Code',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyCode,
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
