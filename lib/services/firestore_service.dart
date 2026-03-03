import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getRestaurants() {
    return _db
        .collection('restaurants')
        .orderBy('name')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRestaurantById(
    String restaurantId,
  ) {
    return _db.collection('restaurants').doc(restaurantId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRestaurantProducts(
    String restaurantId,
  ) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('products')
        .orderBy('name')
        .snapshots();
  }
}
