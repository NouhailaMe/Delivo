import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 GET ALL RESTAURANTS
  Stream<QuerySnapshot> getRestaurants() {
    return _db.collection('restaurants').snapshots();
  }

  /// 🔥 GET PRODUCTS OF ONE RESTAURANT
  Stream<QuerySnapshot> getRestaurantProducts(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('products')
        .snapshots();
  }
}
