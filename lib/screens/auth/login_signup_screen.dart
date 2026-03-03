import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/phone_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/ellipse_clipper.dart';
import 'driver_login_screen.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final TextEditingController _phoneController = TextEditingController();

  String _countryCode = '+212';
  String _countryFlag = 'MA';
  bool _loading = false;

  final List<Map<String, String>> _countries = const [
    {'code': '+212', 'flag': 'MA', 'name': 'Morocco'},
    {'code': '+33', 'flag': 'FR', 'name': 'France'},
    {'code': '+1', 'flag': 'US', 'name': 'USA'},
    {'code': '+44', 'flag': 'UK', 'name': 'United Kingdom'},
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
      builder: (_) {
        return ListView(
          children: _countries.map((country) {
            return ListTile(
              title: Text(country['name']!),
              trailing: Text(country['code']!),
              leading: Text(country['flag']!),
              onTap: () {
                setState(() {
                  _countryCode = country['code']!;
                  _countryFlag = country['flag']!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  String _normalizePhone() {
    final raw = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final noLeadingZero = raw.startsWith('0') ? raw.substring(1) : raw;
    return '$_countryCode$noLeadingZero';
  }

  Future<void> _sendSmsCode() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(verificationId: verificationId),
          ),
        );
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

  Future<void> _goHomeAfterSync() async {
    await UserProfileService.syncCurrentUser();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _loading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _goHomeAfterSync();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      setState(() => _loading = true);

      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Facebook login cancelled')),
        );
        return;
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );
      await _auth.signInWithCredential(credential);
      await _goHomeAfterSync();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              ClipPath(
                clipper: EllipseClipper(),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 40),
                  child: SvgPicture.asset(
                    'assets/logo/delivo_logo.svg',
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Start with your phone number',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(_countryFlag),
                            const SizedBox(width: 6),
                            Text(_countryCode),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _loading ? null : _sendSmsCode,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Continue with SMS'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('or with'),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _socialButton(
                      text: 'Continue with Google',
                      background: Colors.white,
                      textColor: Colors.black,
                      iconWidget: SvgPicture.asset('assets/icons/google.svg', height: 20),
                      border: true,
                      onTap: _signInWithGoogle,
                    ),
                    const SizedBox(height: 12),
                    _socialButton(
                      text: 'Continue with Facebook',
                      background: const Color(0xFF1877F2),
                      textColor: Colors.white,
                      icon: Icons.facebook,
                      onTap: _signInWithFacebook,
                    ),
                    const SizedBox(height: 12),
                    _socialButton(
                      text: 'Continue with Email',
                      background: Colors.white,
                      textColor: const Color(0xFF0F172A),
                      icon: Icons.email,
                      border: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                        );
                      },
                      child: const Text('Delivery driver login'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required Color background,
    required Color textColor,
    IconData? icon,
    Widget? iconWidget,
    required VoidCallback onTap,
    bool border = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: border ? const BorderSide(color: Colors.grey) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _loading ? null : onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null) iconWidget,
            if (icon != null) Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
