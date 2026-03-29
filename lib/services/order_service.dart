import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const pickedUp = 'picked_up';
  static const onTheWay = 'on_the_way';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const activeForUser = [
    pending,
    accepted,
    pickedUp,
    onTheWay,
  ];

  static const activeForDriver = [
    accepted,
    pickedUp,
    onTheWay,
  ];
}

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> availableOrders() {
    return _orders.where('status', isEqualTo: OrderStatus.pending).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userOrders(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> activeUserOrders(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> driverActiveOrders(
    String driverId,
  ) {
    return _orders.where('driverId', isEqualTo: driverId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> orderById(String orderId) {
    return _orders.doc(orderId).snapshots();
  }

  Future<String> createOrder({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required double productsSubtotal,
    required double deliveryFee,
    required double serviceFee,
    required double total,
    required String paymentMethod,
    required String deliveryOption,
    Map<String, dynamic>? paymentCard,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final ref = _orders.doc();

    await ref.set({
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items,
      'itemsCount': items.fold<int>(
        0,
        (itemCount, item) => itemCount + ((item['quantity'] as num?)?.toInt() ?? 1),
      ),
      'productsSubtotal': productsSubtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'total': total,
      'paymentMethod': paymentMethod,
      'deliveryOption': deliveryOption,
      if (paymentCard != null) 'paymentCard': paymentCard,
      'status': OrderStatus.pending,
      'driverId': null,
      'driverLat': null,
      'driverLng': null,
      'deliveryAddress': deliveryAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> acceptOrder({
    required String orderId,
    required String driverId,
    required double driverLat,
    required double driverLng,
  }) {
    return _orders.doc(orderId).update({
      'driverId': driverId,
      'driverLat': driverLat,
      'driverLng': driverLng,
      'status': OrderStatus.accepted,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) {
    return _orders.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == OrderStatus.delivered)
        'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDriverLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) {
    return _orders.doc(orderId).update({
      'driverLat': lat,
      'driverLng': lng,
      'driverUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> cancelOrder({
    required String orderId,
    required String userId,
  }) async {
    return _db.runTransaction<bool>((transaction) async {
      final ref = _orders.doc(orderId);
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return false;

      final data = snapshot.data() ?? const <String, dynamic>{};
      final status = (data['status'] ?? '').toString();
      final owner = (data['userId'] ?? '').toString();
      if (status != OrderStatus.pending || owner != userId) {
        return false;
      }

      transaction.update(ref, {
        'status': OrderStatus.cancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
