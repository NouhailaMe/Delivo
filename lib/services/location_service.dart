import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  /// Check & request permission safely
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get full location with timeout
  static Future<Map<String, dynamic>?> getUserLocation() async {
    try {
      bool hasPermission =
          await requestLocationPermission();

      if (!hasPermission) return null;

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      Placemark place = placemarks.first;

      return {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "city": place.locality ?? "",
        "street": place.street ?? "",
        "fullAddress":
            "${place.locality ?? ""}, ${place.street ?? ""}",
      };
    } catch (e) {
      return null;
    }
  }
}