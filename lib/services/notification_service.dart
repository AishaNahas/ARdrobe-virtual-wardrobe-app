import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import 'weather_service.dart';

class NotificationService {
  final WeatherService _weatherService = WeatherService();

  Future<Map<String, dynamic>?> getOutfitSuggestion(
    List<WardrobeItem> wardrobeItems,
    String location,
  ) async {
    try {
      print('👕 Getting outfit suggestion for location: $location');

      // Parse location coordinates (assuming location is stored as "lat,lon")
      final coordinates = location.split(',');
      if (coordinates.length != 2) {
        print('❌ Invalid location format: $location');
        return null;
      }

      final lat = double.parse(coordinates[0]);
      final lon = double.parse(coordinates[1]);
      print('📍 Parsed coordinates: $lat, $lon');

      // Get current weather
      final weather = await _weatherService.getWeatherByLocation(lat, lon);
      final currentSeason =
          _weatherService.getSeasonFromWeather(weather['temperature']);
      print('🌤️ Current season based on weather: $currentSeason');

      // Filter items by current season
      final seasonalItems =
          wardrobeItems.where((item) => item.season == currentSeason).toList();
      print('👗 Found ${seasonalItems.length} items for $currentSeason season');

      if (seasonalItems.isEmpty) {
        print('❌ No items found for current season');
        return null;
      }

      // Separate items into categories
      final onePieceItems = seasonalItems
          .where((item) =>
              item.type == 'Dresses' ||
              item.type == 'Abayas' ||
              item.type == 'Jumpsuits')
          .toList();

      final bottomItems = seasonalItems
          .where((item) => item.type == 'Pants' || item.type == 'Skirts')
          .toList();

      final topItems = seasonalItems
          .where((item) =>
              item.type == 'Tops' ||
              item.type == 'Shirts' ||
              item.type == 'Hoodies' ||
              item.type == 'Cardigans')
          .toList();

      // Randomly select items for the outfit
      seasonalItems.shuffle();
      List<WardrobeItem> outfit = [];

      // Try to create a one-piece outfit first
      if (onePieceItems.isNotEmpty) {
        outfit = [onePieceItems[0]];
        print('✅ Selected one-piece outfit');
      }
      // If no one-piece items, try to create a two-piece outfit
      else if (bottomItems.isNotEmpty && topItems.isNotEmpty) {
        outfit = [bottomItems[0], topItems[0]];
        print('✅ Selected two-piece outfit');
      }
      // If no suitable combinations, take any items
      else {
        outfit = seasonalItems.take(2).toList();
        print('✅ Selected fallback outfit');
      }

      return {
        'weather': weather,
        'outfit': outfit,
        'season': currentSeason,
      };
    } catch (e) {
      print('❌ Error getting outfit suggestion: $e');
      return null;
    }
  }

  void showOutfitSuggestionDialog(
    BuildContext context,
    Map<String, dynamic> suggestion,
    VoidCallback onTryOn,
  ) {
    print('🎨 Showing outfit suggestion dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Weather Info
              Row(
                children: [
                  Image.network(
                    'https://openweathermap.org/img/wn/${suggestion['weather']['icon']}@2x.png',
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${suggestion['weather']['temperature'].round()}°C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B4B4B),
                        ),
                      ),
                      Text(
                        suggestion['weather']['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Outfit Suggestion
              const Text(
                'Suggested Outfit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              const SizedBox(height: 12),
              // Outfit Items
              ...suggestion['outfit'].map<Widget>((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4B4B4B),
                                ),
                              ),
                              Text(
                                item.color,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onTryOn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA4D3A0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Try On',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
