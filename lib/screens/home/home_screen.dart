import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../restaurants/restaurants_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔵 TOP NAVY BACKGROUND
          Container(
            height: size.height * 0.55,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 📄 MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 📍 ADDRESS
                  _addressPicker(),

                  const SizedBox(height: 20),

                  // 🔍 SEARCH
                  _searchBar(),

                  const SizedBox(height: 32),

                  // 🔘 CATEGORIES
                  _categories(context),

                  const SizedBox(height: 40),

                  // ⬜ WHITE SECTION
                  _whiteSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _addressPicker() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Your address',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'What can we get you?',
            prefixIcon: Icon(Icons.search, color: navy),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // 🔥 CATEGORIES WITH NAVIGATION
  Widget _categories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 24,
        runSpacing: 28,
        alignment: WrapAlignment.center,
        children: [
          _Category(
            label: 'Restaurants',
            icon: Icons.restaurant,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantsScreen(),
                ),
              );
            },
          ),
          const _Category(label: 'Market', icon: Icons.shopping_basket),
          const _Category(label: 'Shops', icon: Icons.store),
          const _Category(label: 'Pharmacy', icon: Icons.local_hospital),
          const _Category(label: 'Courier', icon: Icons.local_shipping),
          const _Category(label: 'Anything', icon: Icons.star),
        ],
      ),
    );
  }

  Widget _whiteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'These are for you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 🟢 STORES (STATIC FOR NOW)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _storeCard('Delivo Market', 'assets/icons/delivo_icon_viseVersa.svg'),
                _storeCard('Carrefour', 'assets/stores/carrefour.svg'),
                _storeCard('Starbucks', 'assets/stores/starbucks.svg'),
                _storeCard('Pizza Hut', 'assets/stores/pizza_hut.svg'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _promoBanner(),

          const SizedBox(height: 32),

          const Text(
            'Stores you might like',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _verticalStore('Burger King', 'assets/stores/burger_king.svg'),
          _verticalStore('KFC', 'assets/stores/kfc.svg'),
          _verticalStore('Marjane', 'assets/stores/marjane.svg'),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget _storeCard(String name, String asset) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 120,
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SvgPicture.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _promoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2E9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Free delivery in the WHOLE app\nNo minimum purchase',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: SvgPicture.asset(
              'assets/stickers/free_delivery.svg',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalStore(String name, String asset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: SvgPicture.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ================= CATEGORY =================

class _Category extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _Category({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: HomeScreen.navy, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
