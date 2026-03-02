import 'package:flutter/material.dart';
import '../home_screen.dart';

class SetAddressScreen extends StatelessWidget {
  const SetAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set delivery address'),
      ),
      body: Column(
        children: [
          // Fake map area (placeholder)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(
                child: Text(
                  'Map Placeholder',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),

          // Address details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current location',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sidi Bennour, Morocco',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text('Confirm address'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
