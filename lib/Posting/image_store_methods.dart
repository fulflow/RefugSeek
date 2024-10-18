import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'post.dart'; // Import your Post model

class ImageStoreMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Modify uploadPost to include city and state
  Future<String> uploadPost(String description, Uint8List file, double latitude, double longitude, String city, String state) async {
    try {
      // Generate a unique file path for the image
      String filePath = 'images/${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload the image to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref(filePath).putData(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create a Post object with location data
      Post post = Post(
        description: description,
        postId: DateTime.now().millisecondsSinceEpoch.toString(),
        datePublished: DateTime.now(),
        postUrl: downloadUrl,
        latitude: latitude,
        longitude: longitude,
        city: city,
        state: state,
      );

      // Store the image URL, description, city, state, and location in Firestore
      await _firestore.collection('posts').add(post.toJson());

      return 'success';
    } catch (e) {
      return e.toString();  // Return error message if something goes wrong
    }
  }
}
