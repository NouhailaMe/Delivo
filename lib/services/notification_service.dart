import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future init() async {

    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print("Notification permission granted");
    }

    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
  }
}