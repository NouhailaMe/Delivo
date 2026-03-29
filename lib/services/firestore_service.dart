import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getHomeCategories() {
    return _db.collection('home_categories').orderBy('order').snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getHomeCategoryById(
    String categoryId,
  ) {
    return _db.collection('home_categories').doc(categoryId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHomeCategorySubcategories(
    String categoryId,
  ) {
    return _db
        .collection('home_categories')
        .doc(categoryId)
        .collection('subcategories')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getHomeFeaturedStores() {
    return _db.collection('home_featured').orderBy('order').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoryItems(String categoryKey) {
    return _db
        .collection('category_items')
        .where('categoryKey', isEqualTo: categoryKey)
        .snapshots();
  }

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
