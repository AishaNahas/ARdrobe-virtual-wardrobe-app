import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/wardrobe_item.dart';
import '../services/cloudinary_service.dart';

class WardrobeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Cloudinary configuration
  static const String _cloudName = 'dgqp2bcty';
  static const String _uploadPreset = 'ardrobe_upload';
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Upload image to Cloudinary
  Future<String> uploadImageToCloudinary(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl));

      // Add the upload preset
      request.fields['upload_preset'] = _uploadPreset;

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading image to Cloudinary: $e');
      throw e;
    }
  }

  // Add item to clothing_items collection
  Future<void> addWardrobeItem(
      String email, WardrobeItem item, File? imageFile) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await uploadImageToCloudinary(imageFile);
      }

      // Add to Firestore with image URL
      await _db.collection('clothing_items').add({
        'email': email,
        'category': item.category,
        'type': item.type,
        'color': item.color,
        'season': item.season,
        'image': imageUrl, // Store the Cloudinary URL
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ Clothing item saved successfully!");
    } catch (e) {
      print('❌ Error adding clothing item: $e');
      throw e;
    }
  }

  // Get all wardrobe items for a user
  Future<List<WardrobeItem>> getWardrobeItems(String email) async {
    try {
      final snapshot = await _db
          .collection('clothing_items')
          .where('email', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WardrobeItem(
          id: doc.id,
          imageUrl: data['image'] ?? '',
          category: data['category'] ?? '',
          type: data['type'] ?? '',
          color: data['color'] ?? '',
          season: data['season'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting clothing items: $e');
      throw e;
    }
  }

  // Get wardrobe items by type
  Future<List<WardrobeItem>> getWardrobeItemsByType(
      String email, String type) async {
    try {
      final snapshot = await _db
          .collection('clothing_items')
          .where('email', isEqualTo: email)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WardrobeItem(
          id: doc.id,
          imageUrl: data['image'] ?? '', // Get the Cloudinary URL
          category: data['category'] ?? '',
          type: data['type'] ?? '',
          color: data['color'] ?? '',
          season: data['season'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting clothing items by type: $e');
      throw e;
    }
  }

  Future<void> toggleFavorite(String email, String itemId) async {
    try {
      final doc = await _db.collection('clothing_items').doc(itemId).get();

      if (doc.exists) {
        final currentFavorite = doc.data()?['isFavorite'] ?? false;
        await doc.reference.update({
          'isFavorite': !currentFavorite,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<void> deleteWardrobeItem(String email, String itemId) async {
    try {
      print('🗑️ Deleting wardrobe item: $itemId');
      await _db.collection('clothing_items').doc(itemId).delete();
      print('✅ Item deleted successfully');
    } catch (e) {
      print('❌ Error deleting item: $e');
      throw e;
    }
  }

  Future<void> updateWardrobeItem(
    String email,
    String itemId,
    String category,
    String type,
    String color,
    String season,
    File? newImage,
  ) async {
    try {
      final itemDoc = await _db.collection('clothing_items').doc(itemId).get();

      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }

      String imageUrl = itemDoc.data()?['image'] ?? '';

      // If a new image is provided, upload it to Cloudinary
      if (newImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(newImage);
      }

      await _db.collection('clothing_items').doc(itemId).update({
        'category': category,
        'type': type,
        'color': color,
        'season': season,
        'image': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully updated wardrobe item: $itemId');
    } catch (e) {
      print('Error updating wardrobe item: $e');
      rethrow;
    }
  }
}
