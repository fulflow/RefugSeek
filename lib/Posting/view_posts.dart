import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ViewPostsPage extends StatefulWidget {
  const ViewPostsPage({Key? key}) : super(key: key);

  @override
  State<ViewPostsPage> createState() => _ViewPostsPageState();
}

class _ViewPostsPageState extends State<ViewPostsPage> {
  // Distance filter (default is 5 miles)
  double selectedDistance = 5;

  // User's current location (for distance calculation)
  Position? _currentUserPosition;

  @override
  void initState() {
    super.initState();
    _determineUserPosition(); // Get user's location on initialization
  }

  // Function to determine user's current location
  Future<void> _determineUserPosition() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentUserPosition = position;
    });
  }

  // Calculate the distance between two points (haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1609.344; // convert meters to miles
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Posts'),
      ),
      body: Column(
        children: [
          // Top Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Filter by Distance (in miles):', style: TextStyle(fontSize: 16)),
                Slider(
                  value: selectedDistance,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  label: selectedDistance.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      selectedDistance = value;
                    });
                  },
                ),
                Text('${selectedDistance.round()} miles'),
              ],
            ),
          ),

          // Posts Section (Starts below the filter, and scrollable)
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                // Filter posts by distance from the user's location
                final filteredPosts = posts.where((post) {
                  if (_currentUserPosition != null) {
                    double postLat = post['latitude']; // assuming lat/lng are stored in Firestore
                    double postLng = post['longitude'];
                    double distance = _calculateDistance(
                        _currentUserPosition!.latitude,
                        _currentUserPosition!.longitude,
                        postLat,
                        postLng);
                    return distance <= selectedDistance;
                  }
                  return true;
                }).toList();

                // Sort posts by closest distance (if current location is available)
                filteredPosts.sort((a, b) {
                  if (_currentUserPosition == null) return 0;
                  double aDistance = _calculateDistance(
                    _currentUserPosition!.latitude,
                    _currentUserPosition!.longitude,
                    a['latitude'],
                    a['longitude'],
                  );
                  double bDistance = _calculateDistance(
                    _currentUserPosition!.latitude,
                    _currentUserPosition!.longitude,
                    b['latitude'],
                    b['longitude'],
                  );
                  return aDistance.compareTo(bDistance);
                });

                // Check if there are no posts to show
                if (filteredPosts.isEmpty) {
                  return const Center(child: Text('No posts available within the selected distance'));
                }

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    var post = filteredPosts[index];

                    String city = post['city'] ?? 'Unknown city';
                    String state = post['state'] ?? 'Unknown state';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 250,
                            width: double.infinity,
                            child: Image.network(
                              post['postUrl'],  // Image URL from Firestore
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['description'],  // Description of the post
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Location: $city, $state',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
