import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _userCollection = 'users';

  // Save user data with local persistence
  Future<void> saveUserData(String uid, String username, String email) async {
    try {
      print("📝 Saving user data to Firestore...");

      await _db.collection(_userCollection).doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save locally
      //final prefs = await SharedPreferences.getInstance();
      //await prefs.setString('username', username);
      //await prefs.setString('email', email);

      print("✅ User data saved successfully!");
    } catch (e) {
      print("❌ Error saving user data: $e");
      rethrow;
    }
  }

  // Save user location
  Future<void> saveUserLocation(String location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      print("📍 Updating user location...");

      await _db.collection(_userCollection).doc(user.uid).update({
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location', location);

      print("✅ User location saved successfully!");
    } catch (e) {
      print("❌ Error saving location: $e");
      rethrow;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      print("🔍 Fetching user data...");

      final prefs = await SharedPreferences.getInstance();
      final localUsername = prefs.getString('username');
      final localEmail = prefs.getString('email');
      final localLocation = prefs.getString('user_location');

      // If local data exists, return it
      if (localUsername != null && localEmail != null) {
        print("✅ Returning local user data.");
        return {
          'username': localUsername,
          'email': localEmail,
          'location': localLocation,
        };
      }

      // Fetch from Firestore if not found locally
      final doc = await _db.collection(_userCollection).doc(userId).get();
      if (!doc.exists) throw Exception('User data not found in Firestore');

      final data = doc.data();
      if (data == null) throw Exception('Firestore returned null data');

      // Save to local storage
      await prefs.setString('username', data['username'] ?? '');
      await prefs.setString('email', data['email'] ?? '');
      if (data.containsKey('location')) {
        await prefs.setString('user_location', data['location']);
      }

      print("✅ User data fetched from Firestore.");
      return data;
    } catch (e) {
      print("❌ Error getting user data: $e");
      rethrow;
    }
  }

  // Clear user data on logout
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("🗑️ Local user data cleared successfully!");
    } catch (e) {
      print("❌ Error clearing user data: $e");
    }
  }

  // Save wardrobe item
  Future<void> saveWardrobeItem(
      String itemName, List<String> imageUrls, String category) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("⚠️ No user logged in, cannot save wardrobe item.");
      return;
    }

    try {
      print("👗 Saving wardrobe item...");

      await _db
          .collection(_userCollection)
          .doc(userId)
          .collection('wardrobe')
          .add({
        'name': itemName,
        'images': imageUrls,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Wardrobe item saved successfully!");
    } catch (e) {
      print("❌ Error saving wardrobe item: $e");
      rethrow;
    }
  }
}
