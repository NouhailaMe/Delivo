import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/favorites_service.dart';

class FavoriteButton extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final String productId;
  final String name;
  final String? imageUrl;
  final double price;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const FavoriteButton({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.activeColor = const Color(0xFFEF4444),
    this.inactiveColor = const Color(0xFF0F172A),
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FavoritesService.currentUserId();
    if (uid == null) {
      return IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save favorites.')),
          );
        },
        icon: Icon(Icons.favorite_border, color: inactiveColor, size: size),
      );
    }

    final favId = FavoritesService.favoriteId(
      restaurantId: restaurantId,
      productId: productId,
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FavoritesService.favoriteDocStream(uid: uid, favoriteId: favId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data?.exists == true;
        return IconButton(
          onPressed: () async {
            await FavoritesService.toggleFavorite(
              uid: uid,
              restaurantId: restaurantId,
              restaurantName: restaurantName,
              productId: productId,
              name: name,
              imageUrl: imageUrl,
              price: price,
            );
          },
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? activeColor : inactiveColor,
            size: size,
          ),
        );
      },
    );
  }
}
