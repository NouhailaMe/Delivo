import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 12));

      return fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return mapFromPlacemark(
          latitude: latitude,
          longitude: longitude,
          place: placemarks.first,
        );
      }
    } catch (_) {}

    return {
      'latitude': latitude,
      'longitude': longitude,
      'street': '',
      'city': '',
      'country': '',
      'fullAddress': 'Pinned location',
    };
  }

  static Map<String, dynamic> mapFromPlacemark({
    required double latitude,
    required double longitude,
    required Placemark place,
  }) {
    final street = place.street?.trim() ?? '';
    final city = place.locality?.trim().isNotEmpty == true
        ? place.locality!.trim()
        : (place.subAdministrativeArea ?? '').trim();
    final country = (place.country ?? '').trim();
    final fullAddress = [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');

    return {
      'latitude': latitude,
      'longitude': longitude,
      'street': street,
      'city': city,
      'country': country,
      'fullAddress': fullAddress.isNotEmpty ? fullAddress : 'Pinned location',
    };
  }

  static Stream<Map<String, dynamic>?> watchUserLocation(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final location = data['location'];
      if (location is Map<String, dynamic>) return location;
      if (location is Map) return Map<String, dynamic>.from(location);
      return null;
    });
  }

  static Future<Map<String, dynamic>?> getSavedLocation(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    final location = data['location'];
    if (location is Map<String, dynamic>) return location;
    if (location is Map) return Map<String, dynamic>.from(location);
    return null;
  }

  static Future<void> saveUserLocation({
    required String uid,
    required Map<String, dynamic> location,
  }) {
    return _db.collection('users').doc(uid).set({
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getCurrentOrSavedLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final current = await getUserLocation();
    if (current != null && uid != null) {
      await saveUserLocation(uid: uid, location: current);
      return current;
    }
    if (uid != null) {
      return getSavedLocation(uid);
    }
    return null;
  }

  static Future<void> saveCoordinatesForCurrentUser({
    required double latitude,
    required double longitude,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final mapped = await fromCoordinates(latitude: latitude, longitude: longitude);
    await saveUserLocation(uid: uid, location: mapped);
  }
}
