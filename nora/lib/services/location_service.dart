import 'package:geolocator/geolocator.dart';

class LocationService {
  // Vérifier les permissions
  static Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  // Obtenir la position actuelle
  static Future<Position?> getCurrentPosition() async {
    bool hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erreur position: $e');
      return null;
    }
  }

  // Calculer la distance entre deux points (en mètres)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Formater la distance
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Obtenir le temps estimé (basé sur la distance, 30km/h moyenne)
  static String getEstimatedTime(double distanceInMeters) {
    double timeInMinutes = (distanceInMeters / 1000) * 2; // 30 km/h = 2 min/km
    if (timeInMinutes < 1) return 'Moins d\'1 min';
    if (timeInMinutes < 60) return '${timeInMinutes.toInt()} min';
    return '${(timeInMinutes / 60).toInt()} h ${(timeInMinutes % 60).toInt()} min';
  }
}