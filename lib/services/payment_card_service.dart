import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/payment_card.dart';

class PaymentCardService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _cardsRef(String uid) {
    return _db.collection('users').doc(uid).collection('payment_cards');
  }

  static Stream<List<PaymentCard>> streamCards(String uid) {
    return _cardsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PaymentCard.fromDoc).toList());
  }

  static Future<PaymentCard> addCard({
    required String uid,
    required String type,
    required String last4,
    required String name,
    required String expiry,
  }) async {
    final ref = _cardsRef(uid).doc();
    final card = PaymentCard(
      id: ref.id,
      type: type,
      last4: last4,
      name: name,
      expiry: expiry,
    );

    await ref.set({
      ...card.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return card;
  }

  static Future<void> deleteCard({
    required String uid,
    required String cardId,
  }) {
    return _cardsRef(uid).doc(cardId).delete();
  }

  static Future<List<PaymentCard>> fetchCards(String uid) async {
    final snap = await _cardsRef(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(PaymentCard.fromDoc).toList();
  }

  static String? currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
