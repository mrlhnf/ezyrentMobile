import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final searchController = TextEditingController();
  Set<Marker> markers = {};

  final LatLng initialLocation = const LatLng(2.1896, 102.2501);
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _searchPlaces(String query) async {
    //final apiKey = ''; // Replace with your Google Maps API Key
    const apiKey = ''; // Replace with your Google Maps API Key
    final headers = await const GoogleApiHeaders().getHeaders();
    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$encodedQuery&key=$apiKey');

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        final place = results[0];
        final lat = place['geometry']['location']['lat'];
        final lng = place['geometry']['location']['lng'];

        if (lat != null && lng != null) {
          final newLocation = LatLng(lat, lng);
          mapController.animateCamera(CameraUpdate.newLatLng(newLocation));

          setState(() {
            markers.clear();
            markers.add(Marker(
              markerId: const MarkerId('selectedLocation'),
              position: newLocation,
            ));
          });

          print('Place Data: $place');
        }
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search for a place',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            _searchPlaces(value);
          },
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: initialLocation,
          zoom: 12.0,
        ),
        markers: markers,
        onTap: (LatLng location) {
          setState(() {
            markers.clear();
            markers.add(Marker(
              markerId: const MarkerId('selectedLocation'),
              position: location,
            ));
          });

          print('Selected Location: $location');
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () {
            if (markers.isNotEmpty) {
              final selectedMarker = markers.first;
              final selectedLocation = selectedMarker.position;

              final locationData = {
                'lat': selectedLocation.latitude,
                'lng': selectedLocation.longitude,
              };

              Navigator.pop(context, locationData);

              print('Location data saved: $locationData');
            }
          },
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
}
