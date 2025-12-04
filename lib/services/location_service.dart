// services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Por favor, habilite a localização no smartphone.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('A permissão de localização foi negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'A permissão de localização foi negada permanentemente. Habilite nas configurações do seu celular.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
