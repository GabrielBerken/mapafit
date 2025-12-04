import 'dart:convert';
import 'dart:developer';
import 'package:flutter_config/flutter_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
class PlacesService {
  Future<Map<String, dynamic>?> getPlaceDetails(LatLng position) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=50&key=${FlutterConfig.get('GOOGLE_MAPS_API_KEY')}';
    final response = await http.get(Uri.parse(url));
    log(Uri.parse(url).toString());
    
    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      log(responseBody);
      final Map<String, dynamic> data = json.decode(responseBody);
      if (data['results'].isNotEmpty) {
        return data['results'][0];
      }
    }
    return null;
  }
}
