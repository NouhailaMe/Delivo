import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String category;

  const CategoryScreen({
    super.key,
    required this.category, required String title,
  });

  List<String> _options() {
    switch (category) {
      case 'restaurants':
        return ['Restaurants', 'Healthy Food', 'Zero Sugar'];
      case 'market':
        return ['Marjane', 'Carrefour', 'BIM'];
      case 'pharmacy':
        return ['Parapharmacy', 'Beauty'];
      case 'courier':
        return ['Packages', 'Documents'];
      default:
        return ['Anything'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // 🔙 BACK BUTTON
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const Spacer(),

            // ⭕ SUB-CATEGORIES (DYNAMIC)
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: options.map((label) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.store,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              }).toList(),
            ),

            const Spacer(),

            // 📌 CATEGORY TITLE
            Text(
              category.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
