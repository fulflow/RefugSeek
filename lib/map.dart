import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert'; // For json decoding
import 'package:http/http.dart' as http; // For making API requests
import 'consts.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};  // Store all the markers

  @override
  void initState() {
    super.initState();
    _fetchServiceLocations();  // Fetch locations from Firebase on init
  }

  // Fetch service locations from Firebase
  Future<void> _fetchServiceLocations() async {
    // Listen to Firestore for real-time updates to the 'services' collection
    FirebaseFirestore.instance.collection('services').snapshots().listen((snapshot) {
      // Clear existing markers
      _markers.clear();

      // Loop through each document in the collection
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Get latitude, longitude, and service name
        double lat = data['latitude'];
        double lng = data['longitude'];
        String name = data['name'] ?? 'Unknown Service';

        // Add a marker for each service location
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
          ),
        );
      }

      // Update the state to reflect the new markers on the map
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Locations'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194),  // Default location (e.g., San Francisco)
          zoom: 10.0,
        ),
        markers: _markers,  // Display markers from Firestore
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}