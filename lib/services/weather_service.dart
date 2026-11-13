import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey =
      '4dd33ce6d14fc5d482d62474a38d3705'; // Replace with your API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> getWeatherByLocation(
      double lat, double lon) async {
    try {
      print('🌤️ Fetching weather for coordinates: $lat, $lon');
      final response = await http.get(Uri.parse(
          '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ Weather data received: ${data['weather'][0]['description']} at ${data['main']['temp']}°C');
        return {
          'temperature': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
        };
      } else {
        print('❌ Weather API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching weather: $e');
      throw Exception('Error fetching weather: $e');
    }
  }

  String getSeasonFromWeather(double temperature) {
    print('🌡️ Determining season for temperature: $temperature°C');
    String season;
    if (temperature >= 25) {
      season = 'Summer';
    } else if (temperature >= 15) {
      season = 'Spring';
    } else if (temperature >= 5) {
      season = 'Fall';
    } else {
      season = 'Winter';
    }
    print('✅ Determined season: $season');
    return season;
  }
}
