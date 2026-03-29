import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/demo_seed_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../location/location_picker_screen.dart';
import '../restaurants/restaurant_details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryId;
  final String categoryLabel;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const navy = Color(0xFF0F172A);
  final _db = FirestoreService();
  final _searchController = TextEditingController();

  String? _selectedSubcategory;
  bool _onlyPromotions = false;
  bool _takeaway = false;
  String _sortBy = 'Top rated';

  @override
  void initState() {
    super.initState();
    DemoSeedService.ensureSeeded();
  }

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
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: locationStream,
          builder: (context, locationSnapshot) {
            final location = locationSnapshot.data;
            final address = (location?['fullAddress'] ?? 'Choose your location').toString();

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.getHomeCategoryById(widget.categoryId),
              builder: (context, categorySnapshot) {
                final category = categorySnapshot.data?.data() ?? {};
                final title = (category['label'] ?? widget.categoryLabel).toString();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.getCategoryItems(widget.categoryId),
                  builder: (context, itemsSnapshot) {
                    var items = itemsSnapshot.data?.docs ?? [];
                    final search = _searchController.text.trim().toLowerCase();

                    if (search.isNotEmpty) {
                      items = items.where((doc) {
                        final data = doc.data();
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        return name.contains(search);
                      }).toList();
                    }

                    if (_selectedSubcategory != null) {
                      items = items.where((doc) {
                        final sub = (doc.data()['subcategory'] ?? '').toString();
                        return sub == _selectedSubcategory;
                      }).toList();
                    }

                    if (_onlyPromotions) {
                      items = items.where((doc) => doc.data()['promoted'] == true).toList();
                    }

                    if (_takeaway) {
                      items = items
                          .where((doc) => (doc.data()['deliveryTime'] ?? '')
                              .toString()
                              .contains('min'))
                          .toList();
                    }

                    if (_sortBy == 'Top rated') {
                      items.sort((a, b) {
                        final left = (a.data()['rating'] as num?)?.toDouble() ?? 0;
                        final right = (b.data()['rating'] as num?)?.toDouble() ?? 0;
                        return right.compareTo(left);
                      });
                    } else {
                      items.sort((a, b) {
                        final left = (a.data()['priority'] as num?)?.toInt() ?? 999;
                        final right = (b.data()['priority'] as num?)?.toInt() ?? 999;
                        return left.compareTo(right);
                      });
                    }

                    final promoted =
                        items.where((e) => e.data()['promoted'] == true).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Row(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                          constraints: const BoxConstraints(maxWidth: 160),
                                          child: Text(
                                            address,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: navy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, color: navy),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search in $title',
                            hintStyle: const TextStyle(color: Color(0xFF8B919E)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF8B919E)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFFDCE1ED)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFFDCE1ED)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _subcategoryRow(),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _chip(
                                label: _onlyPromotions ? 'Promotions ✓' : 'Promotions',
                                selected: _onlyPromotions,
                                onTap: () => setState(() => _onlyPromotions = !_onlyPromotions),
                              ),
                              const SizedBox(width: 8),
                              _chip(
                                label: _takeaway ? 'Takeaway ✓' : 'Takeaway',
                                selected: _takeaway,
                                onTap: () => setState(() => _takeaway = !_takeaway),
                              ),
                              const SizedBox(width: 8),
                              _chip(
                                label: 'Sort by: $_sortBy',
                                selected: false,
                                onTap: () => setState(() {
                                  _sortBy =
                                      _sortBy == 'Top rated' ? 'Recommended' : 'Top rated';
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (promoted.isNotEmpty) ...[
                          const Text(
                            'Popular Brands',
                            style: TextStyle(
                              color: navy,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 250,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: promoted.map((doc) {
                                return SizedBox(
                                  width: 330,
                                  child: _StoreCard(
                                    data: doc.data(),
                                    onTap: () => _openRestaurant(context, doc.data(), title),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const Text(
                          'All Stores',
                          style: TextStyle(
                            color: navy,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDCE1ED)),
                            ),
                            child: const Text('No stores for these filters.'),
                          ),
                        ...items.map((doc) {
                          final data = doc.data();
                          return _StoreCard(
                            data: data,
                            onTap: () => _openRestaurant(context, data, title),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openRestaurant(
    BuildContext context,
    Map<String, dynamic> data,
    String categoryTitle,
  ) {
    final restaurantId = (data['restaurantId'] ?? '').toString();
    if (restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This store is not linked yet.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurantId: restaurantId,
          name: (data['name'] ?? '').toString(),
          category: categoryTitle,
        ),
      ),
    );
  }

  Widget _subcategoryRow() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.getHomeCategorySubcategories(widget.categoryId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        docs.sort((a, b) {
          final left = (a.data()['order'] as num?)?.toInt() ?? 999;
          final right = (b.data()['order'] as num?)?.toInt() ?? 999;
          return left.compareTo(right);
        });

        return SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: docs.map((doc) {
              final data = doc.data();
              final key = (data['key'] ?? '').toString();
              final selected = _selectedSubcategory == key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubcategory = selected ? null : key;
                  });
                },
                child: Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF0F172A) : Colors.white,
                          border: Border.all(color: const Color(0xFFDCE1ED)),
                          shape: BoxShape.circle,
                        ),
                        child: ColorFiltered(
                          colorFilter: selected
                              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: SvgPicture.asset((data['iconAsset'] ?? '').toString()),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (data['label'] ?? '').toString(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: navy,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE1ED)),
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

class _StoreCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _StoreCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Store').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final rating = ((data['rating'] as num?) ?? 0).toInt();
    final orders = (data['ordersCount'] ?? '').toString();
    final duration = (data['deliveryTime'] ?? '').toString();
    final promo = (data['promoText'] ?? '').toString();
    final logoAsset = (data['logoAsset'] ?? '').toString();
    final logoUrl = (data['logoUrl'] ?? '').toString();
    final free = (data['freeDelivery'] as bool?) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE1ED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 168,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE5E7EB),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
                if (promo.isNotEmpty)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        promo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (logoUrl.isNotEmpty || logoAsset.isNotEmpty)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _logoWidget(logoUrl, logoAsset),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: _CategoryScreenState.navy,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '👍 $rating% ($orders) · $duration',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (free) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF1FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: _CategoryScreenState.navy,
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
          ],
        ),
      ),
    );
  }

  Widget _logoWidget(String url, String asset) {
    if (url.isNotEmpty) {
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
    if (asset.isNotEmpty) {
      return SvgPicture.asset(asset);
    }
    return const SizedBox.shrink();
  }
}
