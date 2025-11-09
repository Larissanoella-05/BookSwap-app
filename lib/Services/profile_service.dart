import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service for managing user profile pictures
class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'bookswap-fec4c.firebasestorage.app',
  );

  /// Upload profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to upload a profile picture';
    }

    try {
      debugPrint('Starting profile picture upload...');
      
      // Create a unique filename
      final String fileName = 'profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('📁 File path: $fileName');
      
      final Reference storageRef = _storage.ref().child(fileName);
      
      // Upload metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('Uploading profile picture...');
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      
      final TaskSnapshot snapshot = await uploadTask;
      debugPrint('Profile picture uploaded successfully');
      
      // Get download URL
      final String downloadUrl = await storageRef.getDownloadURL();
      debugPrint('Profile picture URL: $downloadUrl');
      
      // Update user's photoURL in Firebase Auth
      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      throw 'Failed to upload profile picture: $e';
    }
  }

  /// Delete profile picture
  Future<void> deleteProfilePicture() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw 'You must be logged in to delete a profile picture';
    }

    try {
      // Remove photoURL from user
      await user.updatePhotoURL(null);
      await user.reload();
      
      // Note: We don't delete from Storage automatically to avoid breaking references
      // You can add cleanup logic if needed
    } catch (e) {
      throw 'Failed to delete profile picture: $e';
    }
  }
}

