import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCard {
  final String id;
  final String type;
  final String last4;
  final String name;
  final String expiry;

  const PaymentCard({
    required this.id,
    required this.type,
    required this.last4,
    required this.name,
    required this.expiry,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'last4': last4,
      'name': name,
      'expiry': expiry,
    };
  }

  static PaymentCard fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PaymentCard(
      id: doc.id,
      type: (data['type'] ?? '').toString(),
      last4: (data['last4'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      expiry: (data['expiry'] ?? '').toString(),
    );
  }
}
