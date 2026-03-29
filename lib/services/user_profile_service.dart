import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String driverEmail = 'nouha37127@gmail.com';

  static String displayNameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return 'User';
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'User';
    final normalized = localPart.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    if (normalized.isEmpty) return 'User';
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static Future<void> syncUser({
    required User user,
    String? explicitRole,
  }) async {
    final isDriverEmail = user.email?.toLowerCase() == driverEmail;
    final role = explicitRole ?? (isDriverEmail ? 'driver' : 'customer');

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': (user.displayName?.trim().isNotEmpty == true)
          ? user.displayName!.trim()
          : displayNameFromEmail(user.email),
      'phone': user.phoneNumber,
      'role': role,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> syncCurrentUser({String? explicitRole}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await syncUser(user: user, explicitRole: explicitRole);
  }

  static Future<void> updateUserFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    if (fields.isEmpty) return;
    await _db.collection('users').doc(uid).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
