import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../services/firestore_service.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_sheet.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final String restaurantId;
  final String name;
  final String category;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.name,
    required this.category,
  });

  static const navy = Color(0xFF0F172A);
  static const green = Color(0xFF0D8A6A);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService().getRestaurantById(restaurantId),
            builder: (context, snapshot) {
              final restaurant = snapshot.data?.data() ?? const {};

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      restaurant: restaurant,
                      fallbackName: name,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _InfoSection(
                      restaurant: restaurant,
                      category: category,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                    sliver: _ProductsGrid(
                      restaurantId: restaurantId,
                      restaurantName: (restaurant['name'] ?? name).toString(),
                    ),
                  ),
                ],
              );
            },
          ),
          if (!cart.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: Text(
                  'Go to cart  ·  ${cart.totalPrice.toStringAsFixed(2)} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final String fallbackName;

  const _Header({
    required this.restaurant,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final cover = restaurant['coverImage']?.toString();
    final logo = restaurant['logoUrl']?.toString();
    final displayName = (restaurant['name'] ?? fallbackName).toString();
    final fallbackCover = _fallbackCoverUrl(displayName);
    final fallbackAssetLogo = _logoAssetForName(displayName);

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          Positioned.fill(
            child: cover != null && cover.isNotEmpty
                ? Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(
                      fallbackCover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(),
                    ),
                  )
                : Image.network(
                    fallbackCover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackCover(),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _roundIcon(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _roundIcon(icon: Icons.search),
                  const SizedBox(width: 8),
                  _roundIcon(icon: Icons.favorite_border),
                  const SizedBox(width: 8),
                  _roundIcon(icon: Icons.more_horiz),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 18,
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: logo != null && logo.isNotEmpty
                        ? Image.network(
                            logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _logoFallback(displayName),
                          )
                        : _logoFallback(displayName, assetLogo: fallbackAssetLogo),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: RestaurantDetailsScreen.navy),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      color: const Color(0xFF132A52),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.white70,
          size: 64,
        ),
      ),
    );
  }

  Widget _logoFallback(String name, {String? assetLogo}) {
    if (assetLogo != null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: SvgPicture.asset(assetLogo),
      );
    }

    return Container(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'R',
          style: const TextStyle(
            color: RestaurantDetailsScreen.navy,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
      ),
    );
  }

  String _fallbackCoverUrl(String name) {
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

class _InfoSection extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final String category;

  const _InfoSection({
    required this.restaurant,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final duration = (restaurant['deliveryTime'] ?? '20-30 min').toString();
    final rating = ((restaurant['rating'] as num?) ?? 4.8).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  icon: Icons.thumb_up_alt_outlined,
                  value: rating,
                  subtitle: 'Top rated',
                ),
              ),
              Expanded(
                child: _stat(
                  icon: Icons.schedule,
                  value: duration,
                  subtitle: 'Delivery',
                ),
              ),
              Expanded(
                child: _stat(
                  icon: Icons.local_shipping_outlined,
                  value: 'FREE',
                  subtitle: 'Fee',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _tab(category.isNotEmpty ? category : 'Products', selected: true),
                const SizedBox(width: 10),
                _tab('Popular'),
                const SizedBox(width: 10),
                _tab('New'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Products',
            style: TextStyle(
              color: RestaurantDetailsScreen.navy,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: RestaurantDetailsScreen.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: RestaurantDetailsScreen.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _tab(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? RestaurantDetailsScreen.navy : const Color(0xFFE6E7EB),
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : RestaurantDetailsScreen.navy,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const _ProductsGrid({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getRestaurantProducts(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'No products yet.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = docs[index];
              final data = doc.data();
              data['id'] = doc.id;

              return _ProductCard(
                data: data,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => ProductDetailsSheet(
                      productData: data,
                      restaurantId: restaurantId,
                      restaurantName: restaurantName,
                    ),
                  );
                },
              );
            },
            childCount: docs.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.67,
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ProductCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final image = data['imageUrl']?.toString();
    final price = (data['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: image != null && image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              )
                            : _imageFallback(),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.add, color: RestaurantDetailsScreen.navy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RestaurantDetailsScreen.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${price.toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Icon(
        Icons.fastfood,
        color: Color(0xFF6B7280),
        size: 36,
      ),
    );
  }
}
