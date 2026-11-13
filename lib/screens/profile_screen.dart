import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wardrobe_service.dart';
import '../services/calendar_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  const ProfileScreen({super.key, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final WardrobeService _wardrobeService = WardrobeService();
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _wardrobeCount = 0;
  int _favoritesCount = 0;
  List<Map<String, dynamic>> _upcomingEvents = [];
  String? _location;
  bool _editingLocation = false;
  bool _editingUsername = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getUserDetails(widget.email);
    final items = await _wardrobeService.getWardrobeItems(widget.email);
    final favs = items.where((item) => item.isFavorite).toList();
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    final events = await _calendarService.getEvents(widget.email).first;
    final upcoming = events
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))) && e.date.isBefore(weekFromNow))
        .map((e) => {'title': e.title, 'date': e.date})
        .toList();
    setState(() {
      _userData = user;
      _wardrobeCount = items.length;
      _favoritesCount = favs.length;
      _upcomingEvents = upcoming;
      _location = user?['location'] ?? '';
      _locationController.text = _location ?? '';
      _isLoading = false;
    });
  }

  Future<void> _updateLocation() async {
    final newLoc = _locationController.text.trim();
    if (newLoc.isEmpty) return;
    setState(() => _isLoading = true);
    // Find user by email and update location by userId
    final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
    if (userDoc.docs.isNotEmpty) {
      final userId = userDoc.docs.first.id;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'location': newLoc});
    }
    setState(() {
      _location = newLoc;
      _editingLocation = false;
      _isLoading = false;
    });
    _fetchProfileData();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final coords = "${pos.latitude},${pos.longitude}";
      _locationController.text = coords;
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  Future<void> _showLocationDialog() async {
    _cityController.clear();
    _countryController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF3E0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Location', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(hintText: 'City'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(hintText: 'Country'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA4D3A0)),
              onPressed: () async {
                final city = _cityController.text.trim();
                final country = _countryController.text.trim();
                if (city.isEmpty || country.isEmpty) return;
                setState(() => _isLoading = true);
                try {
                  // Use geocoding to get lat/lng
                  List<Location> locations = await locationFromAddress('$city, $country');
                  if (locations.isNotEmpty) {
                    final loc = locations.first;
                    final coords = "${loc.latitude},${loc.longitude}";
                    // Save to Firestore
                    final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
                    if (userDoc.docs.isNotEmpty) {
                      final userId = userDoc.docs.first.id;
                      await FirebaseFirestore.instance.collection('users').doc(userId).update({'location': coords});
                    }
                    setState(() {
                      _location = coords;
                      _editingLocation = false;
                    });
                    _fetchProfileData();
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update location: $e')),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditUsernameDialog() async {
    _usernameController.text = _userData?['username'] ?? '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF3E0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Username', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: 'Enter new username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFA4D3A0)),
              onPressed: () async {
                final newUsername = _usernameController.text.trim();
                if (newUsername.isEmpty) return;
                setState(() => _isLoading = true);
                try {
                  final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
                  if (userDoc.docs.isNotEmpty) {
                    final userId = userDoc.docs.first.id;
                    await FirebaseFirestore.instance.collection('users').doc(userId).update({'username': newUsername});
                  }
                  setState(() {
                    _userData?['username'] = newUsername;
                  });
                  _fetchProfileData();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update username: $e')),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseFirestore.instance.terminate();
    await FirebaseFirestore.instance.clearPersistence();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4B4B)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard', arguments: widget.email);
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Color(0xFF4B4B4B), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFA4D3A0),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _userData?['username'] ?? '',
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4B4B4B)),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFFA4D3A0)),
                                          onPressed: _showEditUsernameDialog,
                                          tooltip: 'Edit Username',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFA4D3A0), size: 18),
                                  const SizedBox(width: 4),
                                  _editingLocation
                                      ? Flexible(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _locationController,
                                                  decoration: const InputDecoration(hintText: 'Enter new location'),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.my_location, color: Color(0xFFA4D3A0)),
                                                onPressed: _getCurrentLocation,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.location_city, color: Color(0xFFA4D3A0)),
                                                onPressed: _showLocationDialog,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.check, color: Colors.green),
                                                onPressed: _updateLocation,
                                              ),
                                            ],
                                          ),
                                        )
                                      : Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(child: Text(_location ?? '', style: const TextStyle(fontSize: 16))),
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18),
                                                onPressed: () => setState(() => _editingLocation = true),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Counts Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox('Wardrobe', _wardrobeCount, Colors.blueAccent),
                      _buildStatBox('Favorites', _favoritesCount, Colors.pinkAccent),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Upcoming Events
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _upcomingEvents.isEmpty
                            ? const Text('No upcoming events.')
                            : Column(
                                children: _upcomingEvents
                                    .map((e) => ListTile(
                                          leading: const Icon(Icons.event, color: Color(0xFFA4D3A0)),
                                          title: Text(e['title']),
                                          subtitle: Text(e['date'].toString().substring(0, 16)),
                                        ))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.black),
                    label: const Text('Logout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA4D3A0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 4, email: widget.email),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 15, color: color)),
        ],
      ),
    );
  }
}
