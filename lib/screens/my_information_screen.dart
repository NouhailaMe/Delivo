import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'change_password_screen.dart';
import 'change_phone_screen.dart';
import 'payment_methods_screen.dart';
import 'manage_privacy_screen.dart';
import '../services/user_profile_service.dart';

class MyInformationScreen extends StatefulWidget {
  const MyInformationScreen({super.key});

  @override
  State<MyInformationScreen> createState() => _MyInformationScreenState();
}

class _MyInformationScreenState extends State<MyInformationScreen> {
  static const navy = Color(0xFF0F172A);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final name = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : UserProfileService.displayNameFromEmail(email);
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final trimmedName = _nameController.text.trim();
      final trimmedEmail = _emailController.text.trim();

      // Update display name
      await user.updateDisplayName(trimmedName);
      // Update email if changed
      if (trimmedEmail.isNotEmpty && trimmedEmail != user.email) {
        await user.verifyBeforeUpdateEmail(trimmedEmail);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A verification email has been sent to your new address.'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Color(0xFF0D8A6A),
          ),
        );
      }

      await UserProfileService.updateUserFields(
        uid: user.uid,
        fields: {
          'name': trimmedName,
          if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Editable Name
            _editableField(
              icon: Icons.person_outline,
              label: 'Name',
              controller: _nameController,
            ),

            // Editable Email
            _editableField(
              icon: Icons.email_outlined,
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _saveChanges,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
              ),
            ),

            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 4),

            // Change password
            _infoItem(
              icon: Icons.lock_outline,
              title: 'Change password',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),

            // Change phone number
            _infoItem(
              icon: Icons.phone_outlined,
              title: 'Change phone number',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePhoneScreen()),
              ),
            ),

            // Payment methods
            _infoItem(
              icon: Icons.credit_card_outlined,
              title: 'Payment methods',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              ),
            ),

            // Manage privacy
            _infoItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Manage privacy',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManagePrivacyScreen()),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _editableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: navy),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.edit, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: navy),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
