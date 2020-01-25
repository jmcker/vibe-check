import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoogleMapController mapController;

  final LatLng _center = const LatLng(40.4285364,-86.9240971);
  LocationData currentLocation;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getLocation();
  }

  _getLocation() async {
    // var currentLocation = LocationData;

    var location = new Location();
    try {
      currentLocation = await location.getLocation();

      print("locationLatitude: ${currentLocation.latitude.toString()}");
      print("locationLongitude: ${currentLocation.longitude.toString()}");
      setState(
          () {}); //rebuild the widget after getting the current location of the user
    } on Exception {
      currentLocation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Vibe Check'),
          backgroundColor: Colors.purple[900],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
        ),
      ),
    );
  }
}
