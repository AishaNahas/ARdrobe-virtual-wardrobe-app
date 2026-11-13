import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/location_screen.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Simple sign up - just save to Firestore
  Future<void> signUpUser(
      String email, String password, String username) async {
    try {
      print('📤 Saving user data...');

      // Save user data in Firestore
      await _db.collection('users').add({
        'email': email,
        'username': username,
        'location': '', // Initialize empty location
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ User data saved successfully!");
    } catch (e) {
      print("❌ Error: $e");
      throw e;
    }
  }

  // Update user location
  Future<void> updateUserLocation(String email, String location) async {
    try {
      print('📍 Updating user location...');

      // Find user by email
      QuerySnapshot querySnapshot =
          await _db.collection('users').where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update the location for the found user
        await querySnapshot.docs.first.reference.update({
          'location': location,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print("✅ Location updated successfully!");
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print("❌ Error updating location: $e");
      throw e;
    }
  }

  // Simple login - just check if user exists in Firestore
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // Query Firestore to find user
      QuerySnapshot querySnapshot =
          await _db.collection('users').where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        return {
          'success': true,
          'userData': querySnapshot.docs.first.data(),
          'error': null,
        };
      }

      return {
        'success': false,
        'userData': null,
        'error': 'User not found',
      };
    } catch (e) {
      print("❌ Login Error: $e");
      return {
        'success': false,
        'userData': null,
        'error': e.toString(),
      };
    }
  }

  // Get user details from Firestore
  Future<Map<String, dynamic>?> getUserDetails(String email) async {
    try {
      QuerySnapshot querySnapshot =
          await _db.collection('users').where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("❌ Error getting user details: $e");
      return null;
    }
  }
}
