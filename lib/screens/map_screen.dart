import 'dart:async';
import 'dart:convert';

import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart';
import 'package:vibe_check/screens/signin_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<MapScreen> {
  GoogleMapController mapController;
  Set<Circle> circles = {}; // CLASS MEMBER, MAP OF Circle
  LatLngBounds bounds = null;

  final LatLng _center = const LatLng(40.4285364, -86.9240971);
  LocationData currentLocation;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Timer(Duration(milliseconds: 200), _getBounds);
  }

  double calculateDistance() {
    double west = bounds.northeast.latitude;
    double east = bounds.southwest.latitude;
    double diff = (east - west);
    if (diff < 0) {
      diff = -1 * diff;
    }

    return diff;
  }

  void drawCircles(List<dynamic> vibes) {
    circles.clear();
    Circle vibeCircle;
    int min = vibes[0]['genre_total_count'];
    int max = vibes[0]['genre_total_count'];
    for (dynamic vibe in vibes) {
      if (vibe['genre_total_count'] > max) {
        max = vibe['genre_total_count'];
      } else if (vibe['genre_total_count'] < min) {
        min = vibe['genre_total_count'];
      }
    }
    for (dynamic vibe in vibes) {
      double diff = calculateDistance();
      double normalized;
      if (max == min) {
        normalized = 1 - 1 / vibe['genre_total_count'];
      } else {
        normalized = (vibe['genre_total_count'] - min) / (max - min);
      }
      double rad = ((10 + normalized * 15) * 650 * diff).toDouble();

      vibeCircle = new Circle(
          circleId: CircleId(vibe['location_id'].toString()),
          center: LatLng(vibe['latitude'], vibe['longitude']),
          fillColor: genreColorMap[vibe['genre'].toString()],
          radius: rad);
      circles.add(vibeCircle);
    }

    setState(() {});
  }

  _getBounds() async {
    bounds = await this.mapController.getVisibleRegion();

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

      List<dynamic> vibes = map['vibes'];

      drawCircles(vibes);

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
            backgroundColor: Colors.white,
            actions: <Widget>[
              RaisedButton(
                onPressed: _getBounds,
                color: Colors.white,
                child: Text(
                  'Show Vibes 🤙',
                ),
              ),
            ],
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
                circles: Set<Circle>.of(circles),
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
