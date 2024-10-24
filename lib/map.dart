import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Posting/view_posts.dart';
import 'consts.dart';
import 'Posting/login.dart';
import 'page_two.dart';
import 'chat_page.dart';
import 'main.dart';
import 'package:flutter/services.dart';
import 'ai.dart';
// To load JSON file for custom map style

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};  // Set to hold markers
  bool _loading = true;  // State to indicate whether the map is ready
  Position? _currentPosition;  // User's current location

  // Fetch services from Firestore in real-time
  Future<void> _fetchRealTimePosts() async {
    FirebaseFirestore.instance.collection('posts').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Safely cast latitude and longitude to double
        double lat = (data['latitude'] is int)
            ? (data['latitude'] as int).toDouble()
            : data['latitude'] as double;
        double lng = (data['longitude'] is int)
            ? (data['longitude'] as int).toDouble()
            : data['longitude'] as double;

        String description = data['description'] ?? 'No description available';

        // Add markers for the posts
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),  // Correctly using LatLng type
            infoWindow: InfoWindow(
              title: data['city'] ?? 'Unknown City',
              snippet: '${data['state'] ?? 'Unknown State'}\n$description',
              onTap: () {
                _launchRouteInGoogleMaps(lat, lng);
              },
            ),
          ),
        );
      }

      // Once data is fetched, update the loading state
      setState(() {
        _loading = false;  // Set loading to false once the data is fetched
      });
    });
  }

  // Fetch user's current location
  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _currentPosition = position;

    // Center the map on the user's current location
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14.0,  // Set appropriate zoom level
          ),
        ),
      );
    }
  }

  // Load custom map style from JSON file
  Future<void> _setMapStyle(GoogleMapController controller) async {
    String style = await rootBundle.loadString('assets/map_style.json');
    controller.setMapStyle(style);
  }

  // Function to launch Google Maps in pedestrian mode with directions to a given location
  void _launchRouteInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRealTimePosts();  // Fetch posts in real-time from Firestore
    _getUserLocation();  // Fetch and center the map on the user's location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services on Map'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())  // Show loading spinner while fetching data
          : Column(
        children: [
          // Container to hold the Google Map with rounded corners
          Container(
            margin: const EdgeInsets.all(16.0),  // Add margin around the map
            height: 400,  // Set the height of the map
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),  // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),  // Clip the map to rounded corners
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(37.7749, -122.4194),  // Default position (can be adjusted)
                  zoom: 12.0,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;

                  // Apply custom map style from JSON
                  _setMapStyle(controller);

                  if (_currentPosition != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 14.0,  // Zoom level for user location
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Description below the map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              'Find the nearest services to you. This map shows real-time updates as people post services.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),

          // Button for "Find Shelters and Homes"
          ElevatedButton(
            onPressed: () {
              // Navigate to a page that helps find shelters or homes
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewPostsPage(),  // Replace with appropriate page
                ),
              );
            },
            child: const Text('Go Find Shelters and Homes'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: darkBrown,  // Background color for footer
        child: Padding(
          padding: const EdgeInsets.all(10.0),  // Padding inside the footer
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,  // Evenly space items
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.post_add),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.list),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PageTwo()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.medical_information),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DrugRecommendationApp()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
