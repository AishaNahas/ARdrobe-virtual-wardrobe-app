import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import 'wardrobe_dashboard.dart';
import '../widgets/gradient_text.dart';

class LocationScreen extends StatefulWidget {
  final String username;
  final String email;

  const LocationScreen({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLocationSubmit() async {
    if (_cityController.text.isEmpty || _countryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both city and country')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert place name to coordinates
      final locationQuery =
          '${_cityController.text}, ${_countryController.text}';
      final locations = await locationFromAddress(locationQuery);

      if (locations.isEmpty) {
        throw Exception('Location not found');
      }

      // Get the first location (most relevant)
      final location = locations.first;

      // Format coordinates as "latitude,longitude"
      final coordinates = '${location.latitude},${location.longitude}';

      // Update user's location in Firestore
      await _authService.updateUserLocation(widget.email, coordinates);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WardrobeDashboard(
            email: widget.email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Name
              const GradientText('ARdrobe'),
              const SizedBox(height: 40),
              // Greeting and info
              Text(
                'Hey ${widget.username}! To get weather-based outfit suggestions based on your location, please enter your city and country.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B4B4B),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can always update your location in the profile',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Location Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // City TextField
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'City',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.location_city_outlined,
                              color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Country TextField
                      TextField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          hintText: 'Country',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.public_outlined,
                              color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLocationSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: const Color(0xFFA4D3A0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text(
                                  'CONTINUE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
