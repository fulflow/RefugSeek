
import 'package:cloud_firestore/cloud_firestore.dart';  // Firestore import

class Post {
  final String description;
  final String postId;
  final DateTime datePublished;
  final String postUrl;
  final double latitude;
  final double longitude;
  final String city;     // Add city
  final String state;    // Add state

  const Post({
    required this.description,
    required this.postId,
    required this.datePublished,
    required this.postUrl,
    required this.latitude,
    required this.longitude,
    required this.city,  // Add city
    required this.state,  // Add state
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'postId': postId,
    'datePublished': datePublished,
    'postUrl': postUrl,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,  // Add city to JSON
    'state': state,  // Add state to JSON
  };

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      description: snapshot['description'],
      postId: snapshot['postId'],
      datePublished: (snapshot['datePublished'] as Timestamp).toDate(),
      postUrl: snapshot['postUrl'],
      latitude: snapshot['latitude'],
      longitude: snapshot['longitude'],
      city: snapshot['city'],
      state: snapshot['state'],
    );
  }
}
