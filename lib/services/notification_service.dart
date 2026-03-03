import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<bool> init() async {

    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    final token = await _firebaseMessaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'notification': {
          'enabled': allowed,
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }

    return allowed;
  }
}
