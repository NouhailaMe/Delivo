import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../location/location_picker_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'restaurant_details_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  static const navy = Color(0xFF0F172A);
  final _searchController = TextEditingController();
  String _sortBy = 'Top rated';
  bool _takeawayOnly = false;

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final locationStream = uid == null
        ? const Stream<Map<String, dynamic>?>.empty()
        : LocationService.watchUserLocation(uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: locationStream,
          builder: (context, locationSnapshot) {
            final location = locationSnapshot.data;
            final address = (location?['fullAddress'] ?? 'Choose your location').toString();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: navy),
                      ),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _changeLocation(location),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9ECF3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 17, color: navy),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    child: Text(
                                      address,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: navy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down, color: navy),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService().getRestaurants(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data?.docs ?? [];
                      final search = _searchController.text.trim().toLowerCase();
                      if (search.isNotEmpty) {
                        docs = docs.where((doc) {
                          final data = doc.data();
                          final name = (data['name'] ?? '').toString().toLowerCase();
                          final category = (data['category'] ?? '').toString().toLowerCase();
                          return name.contains(search) || category.contains(search);
                        }).toList();
                      }

                      if (_takeawayOnly) {
                        docs = docs.where((doc) {
                          final data = doc.data();
                          return data['deliveryType']?.toString().toLowerCase() == 'takeaway';
                        }).toList();
                      }

                      if (_sortBy == 'Top rated') {
                        docs.sort((a, b) {
                          final left = (a.data()['rating'] as num?)?.toDouble() ?? 0;
                          final right = (b.data()['rating'] as num?)?.toDouble() ?? 0;
                          return right.compareTo(left);
                        });
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
                        children: [
                          const Text(
                            'Restaurants',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: navy,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search restaurants',
                              hintStyle: const TextStyle(color: Color(0xFF8B919E)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B919E)),
                              filled: true,
                              fillColor: const Color(0xFFEFF1F4),
                              contentPadding: const EdgeInsets.symmetric(vertical: 2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(34),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 42,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _filterChip(
                                  label: 'Sort by: $_sortBy',
                                  selected: true,
                                  onTap: () {
                                    setState(() {
                                      _sortBy = _sortBy == 'Top rated'
                                          ? 'Delivery time'
                                          : 'Top rated';
                                    });
                                  },
                                ),
                                const SizedBox(width: 10),
                                _filterChip(
                                  label: 'Takeaway',
                                  selected: _takeawayOnly,
                                  onTap: () => setState(() => _takeawayOnly = !_takeawayOnly),
                                ),
                                const SizedBox(width: 10),
                                _filterChip(
                                  label: 'Reset',
                                  selected: false,
                                  onTap: () {
                                    setState(() {
                                      _sortBy = 'Top rated';
                                      _takeawayOnly = false;
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${docs.length} result${docs.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (docs.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text('No restaurants found.'),
                            ),
                          ...docs.map((doc) {
                            final data = doc.data();
                            return _RestaurantCard(
                              data: data,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailsScreen(
                                      restaurantId: doc.id,
                                      name: (data['name'] ?? '').toString(),
                                      category: (data['category'] ?? '').toString(),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? navy : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['coverImage']?.toString();
    final name = (data['name'] ?? 'Restaurant').toString();
    final duration = (data['deliveryTime'] ?? '20-30 min').toString();
    final freeDelivery = (data['freeDelivery'] as bool?) ?? true;
    final fallbackCover = _fallbackCoverForName(name);
    final logoUrl = data['logoUrl']?.toString();
    final logoAsset = _logoAssetForName(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.network(
                                fallbackCover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              ),
                            )
                          : Image.network(
                              fallbackCover,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(),
                            ),
                    ),
                    if ((logoUrl != null && logoUrl.isNotEmpty) || logoAsset != null)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _logoWidget(logoUrl, logoAsset),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _RestaurantsScreenState.navy,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  duration,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (freeDelivery) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: _RestaurantsScreenState.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFF132A52),
      child: const Center(
        child: Icon(
          Icons.storefront,
          color: Colors.white70,
          size: 48,
        ),
      ),
    );
  }

  Widget _logoWidget(String? url, String? asset) {
    if (url != null && url.isNotEmpty) {
      if (url.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          url,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox.shrink(),
        );
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (asset != null) {
      return SvgPicture.asset(asset);
    }
    return const SizedBox.shrink();
  }

  String _fallbackCoverForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1200&q=80';
    }
    if (n.contains('burger')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1200&q=80';
    }
    if (n.contains('kfc') || n.contains('chicken')) {
      return 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?auto=format&fit=crop&w=1200&q=80';
    }
    if (n.contains('starbucks') || n.contains('coffee')) {
      return 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80';
    }
    return 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=1200&q=80';
  }

  String? _logoAssetForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza hut')) return 'assets/stores/pizza_hut.svg';
    if (n.contains('kfc')) return 'assets/stores/kfc.svg';
    if (n.contains('burger king')) return 'assets/stores/burger_king.svg';
    if (n.contains('starbucks')) return 'assets/stores/starbucks.svg';
    if (n.contains('carrefour')) return 'assets/stores/carrefour.svg';
    if (n.contains('marjane')) return 'assets/stores/marjane.svg';
    return null;
  }
}
