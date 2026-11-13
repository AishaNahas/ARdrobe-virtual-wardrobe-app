import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class CloudinaryService {
  final cloudinary = CloudinaryPublic(
    'dgqp2bcty', // Your cloud name
    'ardrobe_upload', // Make sure this matches exactly with your preset name (lowercase)
    cache: false,
  );

  Future<String> uploadImage(File image) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: 'ardrobe', // Optional: creates a folder in Cloudinary
        ),
      );
      print('Upload successful: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> urls = [];
    try {
      for (var image in images) {
        final url = await uploadImage(image);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      print('Error uploading multiple images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }
}
