import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_signup_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const navy = Color(0xFF0F172A);
  static const green = Color(0xFF0D8A6A);

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Admin Dashboard'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('orders').snapshots(),
        builder: (context, ordersSnap) {
          if (!ordersSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('users').snapshots(),
            builder: (context, usersSnap) {
              if (!usersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('restaurants').snapshots(),
                builder: (context, restaurantsSnap) {
                  if (!restaurantsSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = ordersSnap.data!.docs;
                  final users = usersSnap.data!.docs;
                  final restaurants = restaurantsSnap.data!.docs;

                  final drivers = users.where((doc) {
                    final role = (doc.data()['role'] ?? '').toString().toLowerCase();
                    return role == 'driver';
                  }).toList();

                  final totalUsers = users.length;
                  final totalOrders = orders.length;
                  final totalRevenue = orders.fold<double>(0, (sum, doc) {
                    final data = doc.data();
                    if ((data['status'] ?? '') == 'cancelled') return sum;
                    return sum + ((data['total'] as num?)?.toDouble() ?? 0);
                  });

                  final orderStats = _buildDailyStats(
                    orders.map((doc) => doc.data()).toList(),
                    field: 'createdAt',
                    include: (data) => (data['status'] ?? '') != 'cancelled',
                  );
                  final userStats = _buildDailyStats(
                    users.map((doc) => doc.data()).toList(),
                    field: 'createdAt',
                  );

                  final ordersByRestaurant = <String, int>{};
                  for (final doc in orders) {
                    final data = doc.data();
                    if ((data['status'] ?? '') == 'cancelled') continue;
                    final id = (data['restaurantId'] ?? '').toString();
                    if (id.isEmpty) continue;
                    ordersByRestaurant[id] = (ordersByRestaurant[id] ?? 0) + 1;
                  }

                  final restaurantRows = restaurants.map((doc) {
                    final data = doc.data();
                    final id = doc.id;
                    final name = (data['name'] ?? 'Restaurant').toString();
                    final count = ordersByRestaurant[id] ?? 0;
                    return _RankRow(title: name, value: '$count orders');
                  }).toList()
                    ..sort((a, b) => b.numericValue.compareTo(a.numericValue));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _metricCard('Users', totalUsers.toString())),
                          const SizedBox(width: 12),
                          Expanded(child: _metricCard('Orders', totalOrders.toString())),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _metricCard(
                        'Revenue',
                        '${totalRevenue.toStringAsFixed(2)} MAD',
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Orders Growth (7 days)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      _BarChart(data: orderStats, color: green),
                      const SizedBox(height: 18),
                      const Text(
                        'New Buyers (7 days)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      _BarChart(data: userStats, color: navy),
                      const SizedBox(height: 22),
                      const Text(
                        'Delivery Employees',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      if (drivers.isEmpty)
                        const _EmptyCard(text: 'No delivery employees yet.')
                      else
                        ...drivers.map((doc) {
                          final data = doc.data();
                          final name = (data['name'] ?? 'Driver').toString();
                          final email = (data['email'] ?? '').toString();
                          return _InfoTile(title: name, subtitle: email);
                        }),
                      const SizedBox(height: 22),
                      const Text(
                        'Stores In The App',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      if (restaurantRows.isEmpty)
                        const _EmptyCard(text: 'No restaurants yet.')
                      else
                        ...restaurantRows,
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static List<_BarPoint> _buildDailyStats(
    List<Map<String, dynamic>> docs, {
    required String field,
    bool Function(Map<String, dynamic> data)? include,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final counts = {for (final d in days) _dayKey(d): 0};

    for (final data in docs) {
      if (include != null && !include(data)) continue;
      final dt = _toDate(data[field]);
      if (dt == null) continue;
      final key = _dayKey(dt);
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return days
        .map((d) => _BarPoint(
              day: d,
              value: counts[_dayKey(d)] ?? 0,
            ))
        .toList();
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  Widget _metricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_BarPoint> data;
  final Color color;

  const _BarChart({
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((e) => e.value).fold<int>(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((point) {
          final height = (point.value / maxValue) * 120;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _weekday(point.day),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _weekday(DateTime dt) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[dt.weekday - 1];
  }
}

class _BarPoint {
  final DateTime day;
  final int value;

  _BarPoint({
    required this.day,
    required this.value,
  });
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: AdminDashboardScreen.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminDashboardScreen.navy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String title;
  final String value;

  const _RankRow({
    required this.title,
    required this.value,
  });

  int get numericValue {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminDashboardScreen.navy,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminDashboardScreen.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
    );
  }
}
