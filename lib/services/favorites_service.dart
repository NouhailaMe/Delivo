import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? currentUserId() => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) {
    return _db.collection('users').doc(uid).collection('favorite_products');
  }

  static String favoriteId({
    required String restaurantId,
    required String productId,
  }) {
    return '${restaurantId}_$productId';
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> favoriteDocStream({
    required String uid,
    required String favoriteId,
  }) {
    return _favoritesRef(uid).doc(favoriteId).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> favoritesStream(String uid) {
    return _favoritesRef(uid).orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> toggleFavorite({
    required String uid,
    required String restaurantId,
    required String restaurantName,
    required String productId,
    required String name,
    String? imageUrl,
    required double price,
  }) async {
    final favId = favoriteId(restaurantId: restaurantId, productId: productId);
    final ref = _favoritesRef(uid).doc(favId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return;
    }

    await ref.set({
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
