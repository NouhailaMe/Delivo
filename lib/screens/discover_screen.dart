import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'location/location_picker_screen.dart';
import 'restaurants/restaurant_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const navy = Color(0xFF0F172A);
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  final List<_TrendingItem> _crowdPleasers = const [
    _TrendingItem(
      rank: 1,
      name: 'Pizza Hut',
      restaurantId: 'pizza_hut',
      rating: '95%',
      promo: '-15% on selected pizzas',
      logoAsset: 'assets/stores/pizza_hut.svg',
    ),
    _TrendingItem(
      rank: 2,
      name: 'KFC',
      restaurantId: 'kfc',
      rating: '98%',
      promo: 'Free delivery',
      logoAsset: 'assets/stores/kfc.svg',
    ),
    _TrendingItem(
      rank: 3,
      name: 'Burger King',
      restaurantId: 'burger_king',
      rating: '94%',
      promo: 'Combo offers',
      logoAsset: 'assets/stores/burger_king.svg',
    ),
  ];

  final List<_LogoStore> _topRestaurants = const [
    _LogoStore(name: 'Pizza Hut', restaurantId: 'pizza_hut', logoAsset: 'assets/stores/pizza_hut.svg'),
    _LogoStore(name: 'KFC', restaurantId: 'kfc', logoAsset: 'assets/stores/kfc.svg'),
    _LogoStore(name: 'Burger King', restaurantId: 'burger_king', logoAsset: 'assets/stores/burger_king.svg'),
    _LogoStore(name: 'Starbucks', restaurantId: 'starbucks', logoAsset: 'assets/stores/starbucks.svg'),
  ];

  final List<_BigCardStore> _lovedByLocals = const [
    _BigCardStore(
      name: 'Quick',
      restaurantId: 'quick',
      rating: '90%',
      duration: '5-15 min',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/c/c3/Quick_Burger_hamburgers_and_fries.jpg',
    ),
    _BigCardStore(
      name: "McDonald's",
      restaurantId: 'mcdonalds',
      rating: '92%',
      duration: '10-20 min',
      imageUrl:
          'https://images.unsplash.com/photo-1561758033-d89a9ad46330?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeLocation(Map<String, dynamic>? current) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: (current?['latitude'] as num?)?.toDouble() ?? 33.5898,
          initialLng: (current?['longitude'] as num?)?.toDouble() ?? -7.6039,
        ),
      ),
    );

    if (picked == null) return;
    await LocationService.saveUserLocation(uid: user.uid, location: picked);
  }

  void _openRestaurant(String restaurantId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurantId: restaurantId,
          name: name,
          category: 'Food',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final locationStream = uid == null
        ? const Stream<Map<String, dynamic>?>.empty()
        : LocationService.watchUserLocation(uid);

    final search = _searchController.text.trim().toLowerCase();
    final filteredCards = _lovedByLocals
        .where((store) => store.name.toLowerCase().contains(search))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: locationStream,
          builder: (context, snapshot) {
            final location = snapshot.data;
            final address = (location?['fullAddress'] ?? 'Choose your location').toString();

            return ListView(
              padding: const EdgeInsets.only(bottom: 22),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () => _changeLocation(location),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, color: navy, size: 18),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    address,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: navy),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Discover',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                              ),
                            ),
                          ),
                          // 🔍 Search button
                          GestureDetector(
                            onTap: () => setState(() => _showSearchBar = !_showSearchBar),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showSearchBar) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search restaurants…',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70),
                                    onPressed: () => setState(() => _searchController.clear()),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (search.isNotEmpty) ...[
                  _sectionTitle('Search results', 'Restaurants matching "$search"'),
                  const SizedBox(height: 12),
                  _searchResults(search),
                ],
                if (search.isEmpty) ...[
                  _sectionTitle('Crowd-pleasers', 'Consistently trending, week after week'),
                  SizedBox(
                    height: 260,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      children: _crowdPleasers
                          .map((item) => GestureDetector(
                                onTap: () => _openRestaurant(item.restaurantId, item.name),
                                child: Container(
                                  width: 320,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: _rankItem(item),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle('Top restaurants', 'Most ordered in your city'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      children: _topRestaurants
                          .map((store) => GestureDetector(
                                onTap: () => _openRestaurant(store.restaurantId, store.name),
                                child: Container(
                                  width: 132,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                          ),
                                          child: SvgPicture.asset(store.logoAsset),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFCD4A),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Free',
                                          style: TextStyle(fontWeight: FontWeight.w700, color: navy),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Loved by locals', 'Currently popular near you'),
                  const SizedBox(height: 8),
                  ...filteredCards.map((store) => GestureDetector(
                        onTap: () => _openRestaurant(store.restaurantId, store.name),
                        child: _largeStoreCard(store),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _searchResults(String search) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getRestaurants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var docs = snapshot.data?.docs ?? [];
        if (search.isNotEmpty) {
          final query = search.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            return name.contains(query) || category.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text('No restaurants found.'),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] ?? 'Restaurant').toString();
            final duration = (data['deliveryTime'] ?? '20-30 min').toString();
            final rating = ((data['rating'] as num?) ?? 4.6).toStringAsFixed(1);
            final cover = data['coverImage']?.toString();

            return GestureDetector(
              onTap: () => _openRestaurant(doc.id, name),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: cover != null && cover.isNotEmpty
                            ? Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _searchImageFallback(),
                              )
                            : _searchImageFallback(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rating $rating - $duration',
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: navy),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _searchImageFallback() {
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, color: Color(0xFF9CA3AF), size: 40),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: navy,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankItem(_TrendingItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${item.rank}',
                  style: const TextStyle(
                    fontSize: 30,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(item.logoAsset),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    Text(
                      '👍 ${item.rating}',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCD4A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.promo,
              style: const TextStyle(fontWeight: FontWeight.w700, color: navy),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeStoreCard(_BigCardStore store) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                store.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE5E7EB),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: navy,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👍 ${store.rating} • ${store.duration} • Free',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingItem {
  final int rank;
  final String name;
  final String restaurantId;
  final String rating;
  final String promo;
  final String logoAsset;

  const _TrendingItem({
    required this.rank,
    required this.name,
    required this.restaurantId,
    required this.rating,
    required this.promo,
    required this.logoAsset,
  });
}

class _LogoStore {
  final String name;
  final String restaurantId;
  final String logoAsset;

  const _LogoStore({
    required this.name,
    required this.restaurantId,
    required this.logoAsset,
  });
}

class _BigCardStore {
  final String name;
  final String restaurantId;
  final String rating;
  final String duration;
  final String imageUrl;

  const _BigCardStore({
    required this.name,
    required this.restaurantId,
    required this.rating,
    required this.duration,
    required this.imageUrl,
  });
}
