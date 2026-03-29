import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/demo_seed_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../location/location_picker_screen.dart';
import '../restaurants/restaurant_details_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirestoreService();
  late final Future<void> _seedFuture;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _seedFuture = DemoSeedService.ensureSeeded();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _changeLocation(
    BuildContext context, {
    required String uid,
    required Map<String, dynamic>? location,
  }) async {
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: (location?['latitude'] as num?)?.toDouble() ?? 33.5898,
          initialLng: (location?['longitude'] as num?)?.toDouble() ?? -7.6039,
        ),
      ),
    );
    if (picked == null) return;
    await LocationService.saveUserLocation(uid: uid, location: picked);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final locationStream = uid == null
        ? const Stream<Map<String, dynamic>?>.empty()
        : LocationService.watchUserLocation(uid);

    return FutureBuilder<void>(
      future: _seedFuture,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: SafeArea(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: locationStream,
              builder: (context, locationSnapshot) {
                final location = locationSnapshot.data;
                final address =
                    (location?['fullAddress'] ?? 'Choose your location').toString();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0F172A), Color(0xFF162B52)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(38),
                          bottomRight: Radius.circular(38),
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: uid == null
                                ? null
                                : () => _changeLocation(
                                      context,
                                      uid: uid,
                                      location: location,
                                    ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: HomeScreen.navy,
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 190),
                                    child: Text(
                                      address,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: HomeScreen.navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: HomeScreen.navy),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _db.getHomeCategories(),
                            builder: (context, snapshot) {
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const SizedBox(
                                  height: 230,
                                  child: Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                );
                              }

                              return AnimatedBuilder(
                                animation: _floatController,
                                builder: (context, _) {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (docs.isNotEmpty)
                                            _CategoryBubble(
                                              doc: docs[0],
                                              index: 0,
                                              value: _floatController.value,
                                            ),
                                          const SizedBox(width: 16),
                                          if (docs.length > 1)
                                            _CategoryBubble(
                                              doc: docs[1],
                                              index: 1,
                                              value: _floatController.value,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          for (var i = 2; i < docs.length; i++) ...[
                                            _CategoryBubble(
                                              doc: docs[i],
                                              index: i,
                                              value: _floatController.value,
                                            ),
                                            if (i != docs.length - 1) const SizedBox(width: 10),
                                          ],
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'These are for you',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: HomeScreen.navy,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 14),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _db.getHomeFeaturedStores(),
                            builder: (context, snapshot) {
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) return const SizedBox.shrink();

                              return SizedBox(
                                height: 148,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: docs.map((doc) {
                                    final data = doc.data();
                                    final restaurantId = doc.id;
                                    final name = (data['name'] ?? '').toString();
                                    return GestureDetector(
                                      onTap: () {
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
                                      },
                                      child: _FeaturedCard(
                                        name: name,
                                        logoAsset: (data['logoAsset'] ?? '').toString(),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _promoBanner(),
                          const SizedBox(height: 22),
                          const Text(
                            'Popular in food',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: HomeScreen.navy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _db.getCategoryItems('food'),
                            builder: (context, snapshot) {
                              final docs = snapshot.data?.docs ?? [];
                              docs.sort((a, b) {
                                final left = (a.data()['priority'] as num?)?.toInt() ?? 999;
                                final right = (b.data()['priority'] as num?)?.toInt() ?? 999;
                                return left.compareTo(right);
                              });
                              final take = docs.take(3).toList();

                              return Column(
                                children: take.map((doc) {
                                  final data = doc.data();
                                  final restaurantId = (data['restaurantId'] ?? '').toString();
                                  return GestureDetector(
                                    onTap: () {
                                      if (restaurantId.isEmpty) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RestaurantDetailsScreen(
                                            restaurantId: restaurantId,
                                            name: (data['name'] ?? '').toString(),
                                            category: 'Food',
                                          ),
                                        ),
                                      );
                                    },
                                    child: _StoreRow(
                                      name: (data['name'] ?? '').toString(),
                                      logoAsset: (data['logoAsset'] ?? '').toString(),
                                      rating: ((data['rating'] as num?) ?? 0).toInt(),
                                      duration: (data['deliveryTime'] ?? '').toString(),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _promoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    height: 1,
                  ),
                ),
                Text(
                  'in DELIVO',
                  style: TextStyle(
                    color: Color(0xFFFFCD4A),
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No minimum purchase',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_shipping,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final int index;
  final double value;

  const _CategoryBubble({
    required this.doc,
    required this.index,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final label = (data['label'] ?? 'Category').toString();
    final iconAsset = (data['iconAsset'] ?? '').toString();
    final wave = math.sin((value * 2 * math.pi) + (index * 0.7)) * 4;
    final scale = 1 + (math.sin((value * 2 * math.pi) + index) * 0.02);

    return Transform.translate(
      offset: Offset(0, wave),
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryScreen(
                  categoryId: doc.id,
                  categoryLabel: label,
                ),
              ),
            );
          },
          child: SizedBox(
            width: 106,
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(13),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: SvgPicture.asset(iconAsset),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE2EF), width: 1.5),
                    ),
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: HomeScreen.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String name;
  final String logoAsset;

  const _FeaturedCard({
    required this.name,
    required this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SvgPicture.asset(logoAsset),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeScreen.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  final String name;
  final String logoAsset;
  final int rating;
  final String duration;

  const _StoreRow({
    required this.name,
    required this.logoAsset,
    required this.rating,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(logoAsset),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: HomeScreen.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('👍 $rating% · $duration'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECF1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Free',
              style: TextStyle(
                color: HomeScreen.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
