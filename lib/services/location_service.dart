import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org/search';

  // Get place suggestions
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String input) async {
    if (input.length < 2) return [];

    final response = await http.get(
      Uri.parse(
          '$baseUrl?format=json&q=$input&limit=5&addressdetails=1&featuretype=city'),
      headers: {
        'User-Agent': 'ARdrobe_App/1.0', // Required by Nominatim's usage policy
        'Accept': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);
      return results.map((place) {
        final String name = place['display_name'] ?? '';
        final String placeId = place['place_id']?.toString() ?? '';
        return PlaceSuggestion(name, placeId);
      }).toList();
    }
    return [];
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(Position position) async {
    final response = await http.get(
      Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1'),
      headers: {'User-Agent': 'ARdrobe_App/1.0', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['display_name'];
    }
    return null;
  }
}

class PlaceSuggestion {
  final String description;
  final String placeId;

  PlaceSuggestion(this.description, this.placeId);
}
