import 'dart:math';

/// Utility class for distance calculations and formatting.
class DistanceUtils {
  /// Calculates the distance between two points on the Earth using the Haversine formula.
  /// 
  /// Returns the distance in kilometers rounded to 1 decimal place.
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Radius of the earth in km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return double.parse(distance.toStringAsFixed(1));
  }

  /// Formats a distance in kilometers to a user-friendly string.
  /// 
  /// Example: 0.8 km or 12.3 km.
  static String formatDistance(double km) {
    return '$km km';
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
