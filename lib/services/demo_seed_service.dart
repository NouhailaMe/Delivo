import 'package:cloud_firestore/cloud_firestore.dart';

class DemoSeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _done = false;

  static Future<void> ensureSeeded() async {
    if (_done) return;
    _done = true;

    // Clean up old Ramadan entries that may still exist in Firestore
    await _cleanupRamadan();

    await _seedHomeCategories();
    await _seedHomeFeatured();
    await _seedCategoryItems();
    await _seedRestaurants();
    await _seedProducts();
  }

  static Future<void> _cleanupRamadan() async {
    try {
      // Remove ramadan subcategory
      await _db
          .collection('home_categories')
          .doc('food')
          .collection('subcategories')
          .doc('ramadan')
          .delete();
      // Remove ramadan featured entry
      await _db.collection('home_featured').doc('ramadan').delete();
      // Remove ramadan category item
      // (food_starbucks was mistakenly tagged as ramadan subcategory — fixed via merge)
    } catch (_) {
      // Ignore if documents don't exist
    }
  }

  static Future<void> _seedHomeCategories() async {
    final categories = <String, Map<String, dynamic>>{
      'food': {
        'key': 'food',
        'label': 'Food',
        'iconAsset': 'assets/icons/category_food.svg',
        'themeColor': '#0F172A',
        'order': 1,
      },
      'groceries': {
        'key': 'groceries',
        'label': 'Groceries',
        'iconAsset': 'assets/icons/category_groceries.svg',
        'themeColor': '#0F172A',
        'order': 2,
      },
      'shops': {
        'key': 'shops',
        'label': 'Shops',
        'iconAsset': 'assets/icons/category_shops.svg',
        'themeColor': '#0F172A',
        'order': 3,
      },
      'pharmacy': {
        'key': 'pharmacy',
        'label': 'Parapharmacy & Beauty',
        'iconAsset': 'assets/icons/category_pharmacy.svg',
        'themeColor': '#0F172A',
        'order': 4,
      },
      'delivery': {
        'key': 'delivery',
        'label': 'Package Delivery',
        'iconAsset': 'assets/icons/category_delivery.svg',
        'themeColor': '#0F172A',
        'order': 5,
      },
    };

    for (final entry in categories.entries) {
      await _db.collection('home_categories').doc(entry.key).set(
            entry.value,
            SetOptions(merge: true),
          );
    }

    final subcategories = <String, List<Map<String, dynamic>>>{
      'food': [
        {
          'key': 'promotions',
          'label': 'Promotions',
          'iconAsset': 'assets/icons/sub_promo.svg',
          'order': 1,
        },
        {
          'key': 'burgers',
          'label': 'Burgers',
          'iconAsset': 'assets/icons/sub_burger.svg',
          'order': 2,
        },
        {
          'key': 'sandwich',
          'label': 'Sandwich',
          'iconAsset': 'assets/icons/sub_sandwich.svg',
          'order': 3,
        },
        {
          'key': 'mcdonalds',
          'label': "McDonald's",
          'iconAsset': 'assets/icons/sub_burger.svg',
          'order': 4,
        },
      ],
      'groceries': [
        {'key': 'promotions', 'label': 'Promotions', 'iconAsset': 'assets/icons/sub_promo.svg', 'order': 1},
        {'key': 'market', 'label': 'Market', 'iconAsset': 'assets/icons/category_groceries.svg', 'order': 2},
      ],
      'shops': [
        {'key': 'fashion', 'label': 'Fashion', 'iconAsset': 'assets/icons/category_shops.svg', 'order': 1},
        {'key': 'gifts', 'label': 'Gifts', 'iconAsset': 'assets/icons/sub_promo.svg', 'order': 2},
      ],
      'pharmacy': [
        {'key': 'beauty', 'label': 'Beauty', 'iconAsset': 'assets/icons/category_pharmacy.svg', 'order': 1},
        {'key': 'parapharmacy', 'label': 'Parapharmacy', 'iconAsset': 'assets/icons/category_pharmacy.svg', 'order': 2},
      ],
      'delivery': [
        {'key': 'documents', 'label': 'Documents', 'iconAsset': 'assets/icons/category_delivery.svg', 'order': 1},
        {'key': 'packages', 'label': 'Packages', 'iconAsset': 'assets/icons/category_delivery.svg', 'order': 2},
      ],
    };

    for (final category in subcategories.entries) {
      for (final sub in category.value) {
        await _db
            .collection('home_categories')
            .doc(category.key)
            .collection('subcategories')
            .doc(sub['key'] as String)
            .set(sub, SetOptions(merge: true));
      }
    }
  }

  static Future<void> _seedHomeFeatured() async {
    final featured = <String, Map<String, dynamic>>{
      'mcdonalds': {
        'name': "McDonald's",
        'logoAsset': 'assets/stores/burger_king.svg',
        'order': 1,
      },
      'saladbox': {
        'name': 'Saladbox',
        'logoAsset': 'assets/stores/starbucks.svg',
        'order': 2,
      },
      'burger_king': {
        'name': 'Burger King',
        'logoAsset': 'assets/stores/burger_king.svg',
        'order': 3,
      },
      'beauty_success': {
        'name': 'Beauty Success',
        'logoAsset': 'assets/icons/category_pharmacy.svg',
        'order': 4,
      },
    };

    for (final entry in featured.entries) {
      await _db.collection('home_featured').doc(entry.key).set(
            entry.value,
            SetOptions(merge: true),
          );
    }
  }

  static Future<void> _seedCategoryItems() async {
    final items = <String, Map<String, dynamic>>{
      'food_kfc': {
        'categoryKey': 'food',
        'name': 'KFC',
        'subcategory': 'burgers',
        'rating': 89,
        'ordersCount': '1k+',
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'promoted': true,
        'promoText': '-36% some items',
        'imageUrl':
            'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/kfc.svg',
        'restaurantId': 'kfc',
        'priority': 1,
      },
      'food_burger_king': {
        'categoryKey': 'food',
        'name': 'Burger King',
        'subcategory': 'burgers',
        'rating': 93,
        'ordersCount': '1k+',
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'promoted': true,
        'promoText': '-47% some items',
        'imageUrl':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/burger_king.svg',
        'restaurantId': 'burger_king',
        'priority': 2,
      },
      'food_pizza_hut': {
        'categoryKey': 'food',
        'name': 'Pizza Hut',
        'subcategory': 'sandwich',
        'rating': 95,
        'ordersCount': '900+',
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/pizza_hut.svg',
        'restaurantId': 'pizza_hut',
        'priority': 3,
      },
      'food_starbucks': {
        'categoryKey': 'food',
        'name': 'Starbucks',
        'subcategory': 'sandwich',
        'rating': 90,
        'ordersCount': '500+',
        'deliveryTime': '15-20 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/starbucks.svg',
        'restaurantId': 'starbucks',
        'priority': 4,
      },
      'food_mcdonalds': {
        'categoryKey': 'food',
        'name': "McDonald's",
        'subcategory': 'mcdonalds',
        'rating': 92,
        'ordersCount': '2k+',
        'deliveryTime': '10-20 min',
        'freeDelivery': true,
        'promoted': true,
        'promoText': '-20% Big Mac',
        'imageUrl':
            'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/burger_king.svg',
        'restaurantId': 'mcdonalds',
        'priority': 5,
      },
      'groceries_carrefour': {
        'categoryKey': 'groceries',
        'name': 'Carrefour',
        'subcategory': 'market',
        'rating': 94,
        'ordersCount': '1k+',
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/carrefour.svg',
        'restaurantId': 'carrefour',
        'priority': 1,
      },
      'groceries_marjane': {
        'categoryKey': 'groceries',
        'name': 'Marjane',
        'subcategory': 'market',
        'rating': 92,
        'ordersCount': '800+',
        'deliveryTime': '20-35 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1604719312566-8912e9c8a213?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/stores/marjane.svg',
        'restaurantId': 'marjane',
        'priority': 2,
      },
      'shops_beauty': {
        'categoryKey': 'shops',
        'name': 'Beauty Success',
        'subcategory': 'fashion',
        'rating': 91,
        'ordersCount': '300+',
        'deliveryTime': '25-35 min',
        'freeDelivery': false,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/icons/category_pharmacy.svg',
        'priority': 1,
      },
      'pharmacy_para': {
        'categoryKey': 'pharmacy',
        'name': 'Parapharmacy Plus',
        'subcategory': 'parapharmacy',
        'rating': 96,
        'ordersCount': '300+',
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/icons/category_pharmacy.svg',
        'priority': 1,
      },
      'delivery_package': {
        'categoryKey': 'delivery',
        'name': 'Quick Package',
        'subcategory': 'packages',
        'rating': 97,
        'ordersCount': '200+',
        'deliveryTime': '15-25 min',
        'freeDelivery': false,
        'promoted': true,
        'promoText': 'Fast pickup',
        'imageUrl':
            'https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=1200&q=80',
        'logoAsset': 'assets/icons/category_delivery.svg',
        'priority': 1,
      },
    };

    for (final entry in items.entries) {
      await _db.collection('category_items').doc(entry.key).set(
            entry.value,
            SetOptions(merge: true),
          );
    }
  }

  static Future<void> _seedRestaurants() async {
    final restaurants = <String, Map<String, dynamic>>{
      'kfc': {
        'name': 'KFC',
        'category': 'Fast Food',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.6,
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=1200&q=80',
      },
      'burger_king': {
        'name': 'Burger King',
        'category': 'Fast Food',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.7,
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80',
      },
      'pizza_hut': {
        'name': 'Pizza Hut',
        'category': 'Pizza',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.8,
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80',
      },
      'starbucks': {
        'name': 'Starbucks',
        'category': 'Coffee',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.5,
        'deliveryTime': '15-20 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80',
      },
      'carrefour': {
        'name': 'Carrefour',
        'category': 'Groceries',
        'categoryKey': 'groceries',
        'deliveryType': 'delivery',
        'rating': 4.6,
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
      },
      'marjane': {
        'name': 'Marjane',
        'category': 'Groceries',
        'categoryKey': 'groceries',
        'deliveryType': 'delivery',
        'rating': 4.4,
        'deliveryTime': '20-35 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1604719312566-8912e9c8a213?auto=format&fit=crop&w=1200&q=80',
      },
      'mcdonalds': {
        'name': "McDonald's",
        'category': 'Fast Food',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.7,
        'deliveryTime': '10-20 min',
        'freeDelivery': true,
        'coverImage':
            'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=1200&q=80',
      },
    };

    for (final entry in restaurants.entries) {
      await _db.collection('restaurants').doc(entry.key).set(
            entry.value,
            SetOptions(merge: true),
          );
    }
  }

  static Future<void> _seedProducts() async {
    final products = <String, List<Map<String, dynamic>>>{
      'kfc': [
        {
          'id': 'zinger_burger',
          'name': 'Zinger Burger',
          'price': 58.0,
          'description': 'Crispy chicken burger with spicy sauce.',
          'imageUrl':
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
        },
      ],
      'burger_king': [
        {
          'id': 'whopper',
          'name': 'Whopper',
          'price': 62.0,
          'description': 'Flame grilled burger with fresh vegetables.',
          'imageUrl':
              'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
        },
      ],
      'pizza_hut': [
        {
          'id': 'pepperoni_pizza',
          'name': 'Pepperoni Pizza',
          'price': 89.0,
          'description': 'Classic pizza with pepperoni and cheese.',
          'imageUrl':
              'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=900&q=80',
        },
      ],
      'starbucks': [
        {
          'id': 'caffe_latte',
          'name': 'Caffe Latte',
          'price': 38.0,
          'description': 'Smooth espresso with steamed milk.',
          'imageUrl':
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
        },
      ],
      'mcdonalds': [
        {
          'id': 'big_mac',
          'name': 'Big Mac',
          'price': 52.0,
          'description': 'Iconic double-patty burger with special sauce, lettuce and cheese.',
          'imageUrl':
              'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=900&q=80',
        },
        {
          'id': 'mcflurry',
          'name': 'McFlurry',
          'price': 22.0,
          'description': 'Creamy soft-serve ice cream with mix-in toppings.',
          'imageUrl':
              'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=900&q=80',
        },
        {
          'id': 'fries_large',
          'name': 'Large Fries',
          'price': 18.0,
          'description': 'Golden crispy French fries, lightly salted.',
          'imageUrl':
              'https://images.unsplash.com/photo-1576107232684-1279f390859f?auto=format&fit=crop&w=900&q=80',
        },
      ],
    };

    for (final restaurant in products.entries) {
      for (final product in restaurant.value) {
        await _db
            .collection('restaurants')
            .doc(restaurant.key)
            .collection('products')
            .doc(product['id'] as String)
            .set(product, SetOptions(merge: true));
      }
    }
  }
}
