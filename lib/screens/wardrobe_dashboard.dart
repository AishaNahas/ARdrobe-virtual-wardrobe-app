import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/gradient_text.dart';
import '../services/wardrobe_service.dart';
import '../models/wardrobe_item.dart';
import 'add_item_screen.dart';
import 'type_items_screen.dart';
import 'favorites_screen.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'try_on_screen.dart';
import '../services/calendar_service.dart';
import 'calendar_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobeDashboard extends StatefulWidget {
  final String email;

  const WardrobeDashboard({
    super.key,
    required this.email,
  });

  @override
  State<WardrobeDashboard> createState() => _WardrobeDashboardState();
}

class _WardrobeDashboardState extends State<WardrobeDashboard>
    with WidgetsBindingObserver {
  final WardrobeService _wardrobeService = WardrobeService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final CalendarService _calendarService = CalendarService();
  List<WardrobeItem> _items = [];
  bool _isLoading = true;
  int _uploadedItems = 0;
  static const String _suggestionShownKey = 'suggestion_shown';
  List<Map<String, dynamic>> _notifications = [];
  bool _showEventNotification = false;
  Map<String, dynamic>? _todayEventNotification;
  int _selectedIndex = 0; // Define the _selectedIndex variable
  bool _showSearchFilters = false; // Add a boolean to control the expanded search/filter UI
  bool _showSearchBox = false; // Add a boolean to control the search box visibility

  // Search/filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedColor = '';
  String _selectedSeason = '';
  String _selectedCategory = '';
  String _selectedType = '';

  List<WardrobeItem> get _filteredItems {
    return _items.where((item) {
      final matchesColor = _selectedColor.isEmpty || item.color.toLowerCase().contains(_selectedColor.toLowerCase());
      final matchesSeason = _selectedSeason.isEmpty || item.season.toLowerCase() == _selectedSeason.toLowerCase();
      final matchesCategory = _selectedCategory.isEmpty || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesType = _selectedType.isEmpty || item.type.toLowerCase() == _selectedType.toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
        item.category.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        item.type.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        item.color.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesColor && matchesSeason && matchesCategory && matchesType && matchesSearch;
    }).toList();
  }

  // Helper to get unique types
  List<String> get _types => _items.map((item) => item.type).toSet().toList();

  // Helper to get filtered items for a type
  List<WardrobeItem> _filteredItemsForType(String type) {
    final filtered = _items.where((item) => item.type == type).where((item) {
      final matchesColor = _selectedColor.isEmpty || item.color.toLowerCase().contains(_selectedColor.toLowerCase());
      final matchesSeason = _selectedSeason.isEmpty || item.season.toLowerCase() == _selectedSeason.toLowerCase();
      final matchesCategory = _selectedCategory.isEmpty || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesType = _selectedType.isEmpty || item.type.toLowerCase() == _selectedType.toLowerCase();
      final matchesSearch = _searchController.text.isEmpty ||
        item.category.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        item.type.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        item.color.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesColor && matchesSeason && matchesCategory && matchesType && matchesSearch;
    }).toList();
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // For app lifecycle
    _resetSuggestionFlag(); // Reset when dashboard loads
    _loadWardrobeItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOutfitSuggestion();
      _checkTodayEvents();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Reset the flag when the dashboard loads
  Future<void> _resetSuggestionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_suggestionShownKey, false);
    print("Suggestion flag reset for new session");
  }

  Future<void> _checkAndShowOutfitSuggestion() async {
    try {
      print('Checking outfit suggestion...');
      final prefs = await SharedPreferences.getInstance();
      final hasShownSuggestion = prefs.getBool(_suggestionShownKey) ?? false;

      if (!hasShownSuggestion) {
        print('Showing outfit suggestion...');
        await _showOutfitSuggestion();
        await prefs.setBool(_suggestionShownKey, true);
        print('Outfit suggestion shown and saved to preferences');
      } else {
        print('Outfit suggestion already shown in this session');
      }
    } catch (e) {
      print('Error checking outfit suggestion: $e');
    }
  }

  Future<void> _showOutfitSuggestion() async {
    try {
      print('Getting user details...');
      // Get user's location
      final userDetails = await _authService.getUserDetails(widget.email);
      if (userDetails == null || userDetails['location'] == null) {
        print('No location found for user');
        return;
      }

      print('Getting wardrobe items...');
      // Get wardrobe items
      final items = await _wardrobeService.getWardrobeItems(widget.email);
      if (items.isEmpty) {
        print('No wardrobe items found');
        return;
      }

      print('Getting outfit suggestion...');
      // Get outfit suggestion
      final suggestion = await _notificationService.getOutfitSuggestion(
        items,
        userDetails['location'],
      );

      if (suggestion != null && mounted) {
        print('Showing outfit suggestion dialog...');
        _notificationService.showOutfitSuggestionDialog(
          context,
          suggestion,
          () {
            // Handle "Try On" action: open TryOnScreen with suggested outfit
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TryOnScreen(selectedItems: List<WardrobeItem>.from(suggestion['outfit'])),
              ),
            );
          },
        );
      } else {
        print('No outfit suggestion available');
      }
    } catch (e) {
      print('Error showing outfit suggestion: $e');
    }
  }

  Future<void> _loadWardrobeItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _wardrobeService.getWardrobeItems(widget.email);
      setState(() {
        _items = items;
        _uploadedItems = items.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(email: widget.email),
      ),
    );

    if (result == true) {
      _loadWardrobeItems();
    }
  }

  void _onTryOnPressed() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outfits available to try on.')),
      );
      return;
    }
    final selected = await showDialog<List<WardrobeItem>>(
      context: context,
      builder: (context) => _OutfitSelectionDialog(items: _items),
    );
    if (selected != null && selected.isNotEmpty) {
      // Navigate to TryOnScreen for AR overlay
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TryOnScreen(selectedItems: selected),
        ),
      );
    }
  }

  Future<void> _checkTodayEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();
    int notifCount = prefs.getInt('event_notif_count_${today.year}_${today.month}_${today.day}') ?? 0;
    if (notifCount >= 5) return; // Show up to 5 times per day

    final events = await _calendarService.getEvents(widget.email).first;
    final todayEvents = events.where((event) {
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate == today;
    }).toList();
    if (todayEvents.isNotEmpty) {
      for (final event in todayEvents) {
        final notifMsg = "Your '${event.title}' is today, view the outfit you saved";
        final notif = {
          'message': notifMsg,
          'date': today,
          'eventId': event.id,
          'outfit': event.items,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CalendarScreen(
                  email: widget.email,
                  highlightEventId: event.id,
                  outfitItems: event.items,
                ),
              ),
            );
          },
        };
        setState(() {
          _todayEventNotification = notif;
          _showEventNotification = true;
          _notifications.insert(0, notif);
        });
        // Save notification in Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
        final userId = userDoc.docs.isNotEmpty ? userDoc.docs.first.id : null;
        if (userId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId,
            'notification_msg': notifMsg,
            'timestamp': DateTime.now().toIso8601String(),
            'date': today.toIso8601String(),
          });
        }
        notifCount++;
        await prefs.setInt('event_notif_count_${today.year}_${today.month}_${today.day}', notifCount);
        await Future.delayed(const Duration(milliseconds: 3500));
        if (mounted && _showEventNotification) {
          setState(() => _showEventNotification = false);
        }
        if (notifCount >= 2) break;
      }
    }
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Getting Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4B4B),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _uploadedItems / 5,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFFA4D3A0),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload $_uploadedItems/5 items to start',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String type, List<WardrobeItem> items) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TypeItemsScreen(
              type: type,
              items: items,
              email: widget.email,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              Text(
                '${items.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first $type',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Display image if URL exists
                          if (item.imageUrl.isNotEmpty)
                            Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item.color} • ${item.season}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Favorites tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavoritesScreen(email: widget.email),
        ),
      );
    }
    // Add other navigation cases as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Header with App Name and Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const GradientText('ARdrobe'),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _onTryOnPressed,
                                  icon: const Icon(Icons.camera_alt, color: Colors.black),
                                  label: const Text(
                                    'Try On',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA4D3A0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4D3A0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _addNewItem,
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Show search box as overlay, not pushing categories down
                        Stack(
                          children: [
                            if (_showSearchBox)
                              Positioned(
                                right: 0,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 320,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _searchController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            hintText: 'Search by color, type, category...',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.search, color: Color(0xFFA4D3A0)),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedColor.isEmpty ? null : _selectedColor,
                                                hint: const Text('Color'),
                                                items: _items.map((e) => e.color).toSet().map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                                                onChanged: (val) => setState(() => _selectedColor = val ?? ''),
                                                decoration: const InputDecoration(border: InputBorder.none),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedSeason.isEmpty ? null : _selectedSeason,
                                                hint: const Text('Season'),
                                                items: _items.map((e) => e.season).toSet().map((season) => DropdownMenuItem(value: season, child: Text(season))).toList(),
                                                onChanged: (val) => setState(() => _selectedSeason = val ?? ''),
                                                decoration: const InputDecoration(border: InputBorder.none),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                                                hint: const Text('Category'),
                                                items: _items.map((e) => e.category).toSet().map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                                onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
                                                decoration: const InputDecoration(border: InputBorder.none),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                value: _selectedType.isEmpty ? null : _selectedType,
                                                hint: const Text('Type'),
                                                items: _items.map((e) => e.type).toSet().map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                                onChanged: (val) => setState(() => _selectedType = val ?? ''),
                                                decoration: const InputDecoration(border: InputBorder.none),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _selectedColor = '';
                                                  _selectedSeason = '';
                                                  _selectedCategory = '';
                                                  _selectedType = '';
                                                  _searchController.clear();
                                                });
                                              },
                                              child: const Text('Clear', style: TextStyle(color: Color(0xFFA4D3A0))),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _showSearchBox = false;
                                                });
                                              },
                                              child: const Text('Close', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_uploadedItems < 5) ...[
                          _buildProgressSection(),
                          const SizedBox(height: 24),
                        ],
                        // Search icon above categories (standalone, not in header)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFFA4D3A0)),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: _searchController,
                                            decoration: const InputDecoration(
                                              hintText: 'Search by color, type, category...',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.search, color: Color(0xFFA4D3A0)),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: _selectedColor.isEmpty ? null : _selectedColor,
                                                  hint: const Text('Color'),
                                                  items: _items.map((e) => e.color).toSet().map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                                                  onChanged: (val) => setState(() => _selectedColor = val ?? ''),
                                                  decoration: const InputDecoration(border: InputBorder.none),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: _selectedSeason.isEmpty ? null : _selectedSeason,
                                                  hint: const Text('Season'),
                                                  items: _items.map((e) => e.season).toSet().map((season) => DropdownMenuItem(value: season, child: Text(season))).toList(),
                                                  onChanged: (val) => setState(() => _selectedSeason = val ?? ''),
                                                  decoration: const InputDecoration(border: InputBorder.none),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                                                  hint: const Text('Category'),
                                                  items: _items.map((e) => e.category).toSet().map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                                  onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
                                                  decoration: const InputDecoration(border: InputBorder.none),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: _selectedType.isEmpty ? null : _selectedType,
                                                  hint: const Text('Type'),
                                                  items: _items.map((e) => e.type).toSet().map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                                  onChanged: (val) => setState(() => _selectedType = val ?? ''),
                                                  decoration: const InputDecoration(border: InputBorder.none),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedColor = '';
                                                    _selectedSeason = '';
                                                    _selectedCategory = '';
                                                    _selectedType = '';
                                                    _searchController.clear();
                                                  });
                                                },
                                                child: const Text('Clear', style: TextStyle(color: Color(0xFFA4D3A0))),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              setState(() {}); // Refresh after dialog closes
                            },
                          ),
                        ),
                        // Categories (classic dashboard view, filtered items per category)
                        Expanded(
                          child: _items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.checkroom_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Your wardrobe is empty!\nStart by adding your favorite outfits.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  children: _types.map((type) {
                                    final filtered = _filteredItemsForType(type);
                                    if (filtered.isEmpty) return null; // Hide category if no items
                                    return _buildCategorySection(type, filtered);
                                  }).whereType<Widget>().toList(), // Only show non-empty categories
                                ),
                        ),
                      ],
                    ),
                  ),
            if (_showEventNotification && _todayEventNotification != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _todayEventNotification!['message'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showEventNotification = false);
                          },
                          child: const Text('Dismiss'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showEventNotification = false);
                            _todayEventNotification!['onTap']();
                          },
                          child: const Text('See Outfit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        email: widget.email,
        // Pass notifications to NotificationScreen
        // (You may need to update BottomNavBar to accept this prop)
      ),
    );
  }
}

class _OutfitSelectionDialog extends StatefulWidget {
  final List<WardrobeItem> items;
  const _OutfitSelectionDialog({required this.items});
  @override
  State<_OutfitSelectionDialog> createState() => _OutfitSelectionDialogState();
}

class _OutfitSelectionDialogState extends State<_OutfitSelectionDialog> {
  final Set<String> _selectedIds = {};
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFAF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Select Outfits', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF4B4B4B))),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: ListView(
          children: widget.items.map((item) {
            final selected = _selectedIds.contains(item.id);
            return ListTile(
              leading: CircleAvatar(backgroundImage: item.imageUrl.isNotEmpty ? NetworkImage(item.imageUrl) : null, backgroundColor: const Color(0xFFA4D3A0)),
              title: Text(item.type, style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF4B4B4B))),
              subtitle: Text(item.category, style: const TextStyle(fontFamily: 'Poppins')),
              trailing: Checkbox(
                value: selected,
                activeColor: const Color(0xFFA4D3A0),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(item.id);
                    } else {
                      _selectedIds.remove(item.id);
                    }
                  });
                },
              ),
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedIds.remove(item.id);
                  } else {
                    _selectedIds.add(item.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty ? null : () {
            final selected = widget.items.where((item) => _selectedIds.contains(item.id)).toList();
            Navigator.pop(context, selected);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA4D3A0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Continue', style: TextStyle(fontFamily: 'Poppins', color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
