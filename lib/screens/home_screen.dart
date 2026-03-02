import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> restaurants = const [
    {'name': 'Local Market', 'type': 'Groceries'},
    {'name': 'Fresh Bakery', 'type': 'Bakery'},
    {'name': 'Italian Corner', 'type': 'Restaurant'},
    {'name': 'Pharma Plus', 'type': 'Pharmacy'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Stores')),
      body: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final item = restaurants[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(item['name']!),
              subtitle: Text(item['type']!),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}
