import 'package:flutter/material.dart';

class ManagePrivacyScreen extends StatefulWidget {
  const ManagePrivacyScreen({super.key});

  @override
  State<ManagePrivacyScreen> createState() => _ManagePrivacyScreenState();
}

class _ManagePrivacyScreenState extends State<ManagePrivacyScreen> {
  static const navy = Color(0xFF0F172A);

  final Map<String, bool> _settings = {
    'Allow notifications': true,
    'Location access': true,
    'Personalized offers': true,
    'Data analytics': false,
    'Share usage data': false,
  };

  void _toggle(String key) {
    setState(() => _settings[key] = !(_settings[key] ?? false));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_settings[key] == true ? '✅ Enabled' : '🔕 Disabled'}: $key',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage privacy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 30),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Control how DELIVO uses your data',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          ..._settings.entries.map((entry) => _PrivacyItem(
                label: entry.key,
                description: _descriptionFor(entry.key),
                value: entry.value,
                onChanged: (_) => _toggle(entry.key),
              )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Privacy settings saved!'),
                    backgroundColor: Color(0xFF0D8A6A),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save preferences', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  String _descriptionFor(String label) {
    switch (label) {
      case 'Allow notifications':
        return 'Receive order updates and promotions';
      case 'Location access':
        return 'Find restaurants near you';
      case 'Personalized offers':
        return 'Get deals tailored to your taste';
      case 'Data analytics':
        return 'Help us improve the app anonymously';
      case 'Share usage data':
        return 'Share data with our partners';
      default:
        return '';
    }
  }
}

class _PrivacyItem extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyItem({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ManagePrivacyScreenState.navy,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF0D8A6A),
          ),
        ],
      ),
    );
  }
}
