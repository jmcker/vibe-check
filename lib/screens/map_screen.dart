import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<MapScreen> {
  GoogleMapController mapController;

  Set<Circle> circles = Set.from([
    Circle(
      circleId: CircleId("current_location"),
      center: LatLng(40.4285364, -86.9240971),
      fillColor: Color.fromARGB(128, 51, 153, 153),
      strokeColor: Color.fromARGB(160, 51, 153, 153),
      radius: 4000,
    )
  ]);

  final LatLng _center = const LatLng(40.4285364, -86.9240971);
  LocationData currentLocation;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getBounds();
  }

  _getBounds() async {
    LatLngBounds bounds = await this.mapController.getVisibleRegion();
    print(bounds.northeast.toString());
    print(bounds.southwest.toString());

    var lat_min, lon_min, lat_max, lon_max;

    // Find min latitude
    if (bounds.northeast.latitude < bounds.southwest.latitude) {
      lat_min = bounds.northeast.latitude.toString();
      lat_max = bounds.southwest.latitude.toString();
    } else {
      lat_min = bounds.southwest.latitude.toString();
      lat_max = bounds.northeast.latitude.toString();
    }

    // Find min longitude
    if (bounds.northeast.longitude < bounds.southwest.longitude) {
      lon_min = bounds.northeast.longitude.toString();
      lon_max = bounds.southwest.longitude.toString();
    } else {
      lon_min = bounds.southwest.longitude.toString();
      lon_max = bounds.northeast.longitude.toString();
    }

    Response resp = await get(
        'https://vibecheck.tk/api/vibe?lat_min=${lat_min}&lat_max=${lat_max}&lon_min=${lon_min}&lon_max=${lon_max}');

    if (resp.statusCode == 200) {
      Map<String, dynamic> map = jsonDecode(resp.body);

      print("We got the vibes");
      print(map);
    }
  }

  _getLocation() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('Vibe Check'),
            backgroundColor: Colors.purple[900],
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                myLocationEnabled: true,
                circles: circles,
              ),
              Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 40.0,
                        width: 400.0,
                        color: Colors.white,
                        child: Image.asset('Assets/legend.PNG'),
                        // Text("This is a sample txtd to understand FittedBox widget"),
                      )
                    ],
                  )),
            ],
          )),
    );
  }
}
