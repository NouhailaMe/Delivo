import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } on FirebaseAuthException catch (e) {
      String message;

switch (e.code) {
  case 'invalid-credential':
    message = 'Email ou mot de passe incorrect';
    break;

  case 'user-not-found':
    message = 'Aucun compte trouvé avec cet email';
    break;

  case 'wrong-password':
    message = 'Mot de passe incorrect';
    break;

  case 'invalid-email':
    message = 'Adresse email invalide';
    break;

  case 'email-not-verified':
    message = 'Veuillez vérifier votre email avant de continuer';
    break;

  case 'network-request-failed':
    message = 'Problème de connexion internet';
    break;

  default:
    message = 'Erreur de connexion. Veuillez réessayer.';
}


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
