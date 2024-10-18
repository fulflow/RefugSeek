import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMapService extends StatefulWidget {
  @override
  _GoogleMapServiceState createState() => _GoogleMapServiceState();
}

class _GoogleMapServiceState extends State<GoogleMapService> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};  // Set to hold markers

  // Fetch services from Firestore
  Future<void> _fetchServices() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('services').get();

    // Loop through documents and create markers
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double lat = data['latitude'];
      double lng = data['longitude'];
      String name = data['name'] ?? 'Unknown Service';

      _markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: name),
        ),
      );
    }

    setState(() {});
  }

  // Fetch user's current location
  Future<void> _showUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Add a marker for the user's location
    _markers.add(
      Marker(
        markerId: MarkerId("user_location"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: "Your Location"),
      ),
    );

    // Move the camera to the user's location
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchServices(); // Fetch service locations from Firestore
    _showUserLocation(); // Fetch and display user location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services on Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Default position, can adjust
          zoom: 12.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
