import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/favorites_service.dart';
import 'restaurants/restaurant_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          foregroundColor: navy,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Please log in to view favorites.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Favorites'),
        foregroundColor: navy,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FavoritesService.favoritesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, size: 72, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 12),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: navy),
                  ),
                  SizedBox(height: 6),
                  Text('Tap the heart on a product to save it'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = (data['name'] ?? '').toString();
              final imageUrl = data['imageUrl']?.toString();
              final restaurantName = (data['restaurantName'] ?? 'Restaurant').toString();
              final restaurantId = (data['restaurantId'] ?? '').toString();
              final price = (data['price'] as num?)?.toDouble() ?? 0;

              return GestureDetector(
                onTap: restaurantId.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailsScreen(
                              restaurantId: restaurantId,
                              name: restaurantName,
                              category: 'Products',
                            ),
                          ),
                        );
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _imageFallback(),
                                )
                              : _imageFallback(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: navy,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurantName,
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${price.toStringAsFixed(2)} MAD',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('favorite_products')
                              .doc(docs[index].id)
                              .delete();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, color: Color(0xFF9CA3AF)),
    );
  }
}
