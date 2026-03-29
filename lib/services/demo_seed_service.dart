import 'package:cloud_firestore/cloud_firestore.dart';

class DemoSeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _done = false;

  static Future<void> ensureSeeded() async {
    if (_done) return;
    _done = true;

    // Clean up old Ramadan entries that may still exist in Firestore
    await _cleanupRamadan();
    await _cleanupDeprecatedRestaurants();

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

  static Future<void> _cleanupDeprecatedRestaurants() async {
    try {
      await _db.collection('category_items').doc('food_otacos').delete();
      await _db.collection('restaurants').doc('otacos').delete();
      await _db
          .collection('home_categories')
          .doc('food')
          .collection('subcategories')
          .doc('tacos')
          .delete();
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
        {
          'key': 'pizza',
          'label': 'Pizza',
          'iconAsset': 'assets/icons/sub_sandwich.svg',
          'order': 5,
        },
        {
          'key': 'coffee',
          'label': 'Coffee',
          'iconAsset': 'assets/icons/sub_sandwich.svg',
          'order': 6,
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
    const staleFeaturedIds = ['saladbox', 'beauty_success'];
    for (final id in staleFeaturedIds) {
      try {
        await _db.collection('home_featured').doc(id).delete();
      } catch (_) {
        // Ignore if missing.
      }
    }

    final featured = <String, Map<String, dynamic>>{
      'kfc': {
        'name': 'KFC',
        'logoAsset': 'assets/stores/kfc.svg',
        'order': 1,
      },
      'burger_king': {
        'name': 'Burger King',
        'logoAsset': 'assets/stores/burger_king.svg',
        'order': 2,
      },
      'pizza_hut': {
        'name': 'Pizza Hut',
        'logoAsset': 'assets/stores/pizza_hut.svg',
        'order': 3,
      },
      'starbucks': {
        'name': 'Starbucks',
        'logoAsset': 'assets/stores/starbucks.svg',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/d/d6/Starbucks_logo.jpg',
        'order': 4,
      },
      'mcdonalds': {
        'name': "McDonald's",
        'logoAsset': '',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/5/50/McDonald%27s_SVG_logo.svg',
        'order': 5,
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
            'https://upload.wikimedia.org/wikipedia/commons/a/a5/KFC_Zinger.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/c/c8/Whopper.jpg',
        'logoAsset': 'assets/stores/burger_king.svg',
        'restaurantId': 'burger_king',
        'priority': 2,
      },
      'food_pizza_hut': {
        'categoryKey': 'food',
        'name': 'Pizza Hut',
        'subcategory': 'pizza',
        'rating': 95,
        'ordersCount': '900+',
        'deliveryTime': '20-30 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://upload.wikimedia.org/wikipedia/commons/d/d1/Pepperoni_pizza.jpg',
        'logoAsset': 'assets/stores/pizza_hut.svg',
        'restaurantId': 'pizza_hut',
        'priority': 3,
      },
      'food_starbucks': {
        'categoryKey': 'food',
        'name': 'Starbucks',
        'subcategory': 'coffee',
        'rating': 90,
        'ordersCount': '500+',
        'deliveryTime': '15-20 min',
        'freeDelivery': true,
        'promoted': false,
        'promoText': '',
        'imageUrl':
            'https://upload.wikimedia.org/wikipedia/commons/f/f9/Caffe_Latte.jpg',
        'logoAsset': 'assets/stores/starbucks.svg',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/d/d6/Starbucks_logo.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/9/9a/Big_Mac_hamburger.jpg',
        'logoAsset': '',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/5/50/McDonald%27s_SVG_logo.svg',
        'restaurantId': 'mcdonalds',
        'priority': 5,
      },
      'food_quick': {
        'categoryKey': 'food',
        'name': 'Quick',
        'subcategory': 'burgers',
        'rating': 94,
        'ordersCount': '700+',
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'promoted': true,
        'promoText': '-20% some items',
        'imageUrl':
            'https://upload.wikimedia.org/wikipedia/commons/c/c3/Quick_Burger_hamburgers_and_fries.jpg',
        'logoAsset': '',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Quick_restaurant_logo.png',
        'restaurantId': 'quick',
        'priority': 6,
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
            'https://upload.wikimedia.org/wikipedia/commons/a/a5/KFC_Zinger.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/c/c8/Whopper.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/d/d1/Pepperoni_pizza.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/f/f9/Caffe_Latte.jpg',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/d/d6/Starbucks_logo.jpg',
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
            'https://upload.wikimedia.org/wikipedia/commons/9/9a/Big_Mac_hamburger.jpg',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/5/50/McDonald%27s_SVG_logo.svg',
      },
      'quick': {
        'name': 'Quick',
        'category': 'Fast Food',
        'categoryKey': 'food',
        'deliveryType': 'takeaway',
        'rating': 4.6,
        'deliveryTime': '15-25 min',
        'freeDelivery': true,
        'coverImage':
            'https://upload.wikimedia.org/wikipedia/commons/c/c3/Quick_Burger_hamburgers_and_fries.jpg',
        'logoUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Quick_restaurant_logo.png',
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
          'name': 'Original Recipe Chicken',
          'price': 58.0,
          'description': 'Classic KFC fried chicken with signature seasoning.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/4/4b/KFC_Fried_chicken.jpg',
        },
      ],
      'burger_king': [
        {
          'id': 'whopper',
          'name': 'Whopper',
          'price': 62.0,
          'description': 'Flame grilled burger with fresh vegetables.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/c/c8/Whopper.jpg',
        },
      ],
      'pizza_hut': [
        {
          'id': 'pepperoni_pizza',
          'name': 'Pepperoni Pizza',
          'price': 89.0,
          'description': 'Classic pizza with pepperoni and cheese.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/d/d1/Pepperoni_pizza.jpg',
        },
      ],
      'starbucks': [
        {
          'id': 'caffe_latte',
          'name': 'Caffe Latte',
          'price': 38.0,
          'description': 'Smooth espresso with steamed milk.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/f/f9/Caffe_Latte.jpg',
        },
      ],
      'mcdonalds': [
        {
          'id': 'big_mac',
          'name': 'Big Mac',
          'price': 52.0,
          'description': 'Iconic double-patty burger with special sauce, lettuce and cheese.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/9/9a/Big_Mac_hamburger.jpg',
        },
        {
          'id': 'mcflurry',
          'name': 'McFlurry',
          'price': 22.0,
          'description': 'Creamy soft-serve ice cream with mix-in toppings.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/9/94/McFlurry_%2810910146423%29.jpg',
        },
        {
          'id': 'fries_large',
          'name': 'Large Fries',
          'price': 18.0,
          'description': 'Golden crispy French fries, lightly salted.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/8/83/French_Fries.JPG',
        },
      ],
      'quick': [
        {
          'id': 'quick_burger',
          'name': 'Quick Burger',
          'price': 55.0,
          'description': 'Signature burger with fries and sauce.',
          'imageUrl':
              'https://upload.wikimedia.org/wikipedia/commons/c/c3/Quick_Burger_hamburgers_and_fries.jpg',
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
