import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

import 'genres.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<MapScreen> {
  GoogleMapController mapController;
  BitmapDescriptor myIcon;
  Set<Circle> circles = {}; // CLASS MEMBER, MAP OF Circle
  Set<Marker> markers = {};

  final LatLng _mapDefault = const LatLng(40.4285364, -86.9240971);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(64, 64)), 'Assets/music.png')
        .then((onValue) {
      myIcon = onValue;
    });

    Timer(Duration(milliseconds: 200), _onRefreshButtonClicked);
  }

  void _onRefreshButtonClicked() async {
    LatLngBounds bounds = await this.mapController.getVisibleRegion();
    List<dynamic> vibes = await this.getVibes(bounds);

    this.drawVibes(bounds, vibes);
  }

  void _onCameraMoveStarted() {
    print('_onCameraMoveStarted');
  }

  void _onCamerMoveIdle() {
    print('_onCamerMoveIdle');
  }

  double calculateDistance(LatLngBounds bounds) {
    double west = bounds.northeast.latitude;
    double east = bounds.southwest.latitude;
    double diff = (east - west);
    if (diff < 0) {
      diff = -1 * diff;
    }

    return diff;
  }

  Future<List<dynamic>> getVibes(LatLngBounds bounds) async {

    var latMin, lonMin, latMax, lonMax;

    // Find min latitude
    if (bounds.northeast.latitude < bounds.southwest.latitude) {
      latMin = bounds.northeast.latitude.toString();
      latMax = bounds.southwest.latitude.toString();
    } else {
      latMin = bounds.southwest.latitude.toString();
      latMax = bounds.northeast.latitude.toString();
    }

    // Find min longitude
    if (bounds.northeast.longitude < bounds.southwest.longitude) {
      lonMin = bounds.northeast.longitude.toString();
      lonMax = bounds.southwest.longitude.toString();
    } else {
      lonMin = bounds.southwest.longitude.toString();
      lonMax = bounds.northeast.longitude.toString();
    }

    Response resp = await get(
        'https://vibecheck.tk/api/vibe?lat_min=${latMin}&lat_max=${latMax}&lon_min=${lonMin}&lon_max=${lonMax}&divisions=16');

    if (resp.statusCode == 200) {
      Map<String, dynamic> map = jsonDecode(resp.body);
      print(map);

      return map['vibes'];
    }

    return List<dynamic>();
  }

  void drawVibes(LatLngBounds bounds, List<dynamic> vibes) {
    circles.clear();
    markers.clear();

    Circle vibeCircle;
    Marker vibeMarker;
    int min = 0;
    int max = 0;

    // Calculate min and max
    for (dynamic vibe in vibes) {
      if (vibe['genre_total_count'] > max) {
        max = vibe['genre_total_count'];
      } else if (vibe['genre_total_count'] < min) {
        min = vibe['genre_total_count'];
      }
    }

    for (dynamic vibe in vibes) {
      double diff = calculateDistance(bounds);
      double normalized;
      if (max == min) {
        normalized = 1 - 1 / vibe['genre_total_count'];
      } else {
        normalized = (vibe['genre_total_count'] - min) / (max - min);
      }
      double radius = ((10 + normalized * 15) * 650 * diff).toDouble();

      vibeCircle = new Circle(
        circleId: CircleId(vibe['location_id'].toString()),
        center: LatLng(vibe['latitude'], vibe['longitude']),
        fillColor: genreColorMap[vibe['genre'].toString()],
        strokeColor: Color.fromARGB(150, 0, 0, 0),
        radius: radius,
      );

      circles.add(vibeCircle);

      vibeMarker = new Marker (
        anchor: Offset(0.5, 0.5),
        markerId: MarkerId((vibe['location_id'].toString())),
        position: LatLng(vibe['latitude'], vibe['longitude']),
        visible: true,
        alpha: 0.0,
        //icon: myIcon,
        infoWindow: new InfoWindow(
          title: 'Song: ' + vibe['title'],
          snippet: 'Artist: ' + vibe['artist'], // This gets cut off if added right now '\nAlbum: ' + vibe['album'] + '\nVibes: ' + vibe['top_track_vibe_count'].toString(),
        )
      );

      markers.add(vibeMarker);
    }

    setState(() {});
  }

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
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraIdle: _onCamerMoveIdle,
                initialCameraPosition: CameraPosition(
                  target: _mapDefault,
                  zoom: 11.0,
                ),
                rotateGesturesEnabled: false,
                compassEnabled: false,
                myLocationEnabled: true,
                circles: Set<Circle>.of(circles),
                markers: Set<Marker>.of(markers),
            ),
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: FloatingActionButton.extended(
                      backgroundColor: Colors.purple[900],
                      onPressed: _onRefreshButtonClicked,
                      label: Text('Show Vibes 🤙'),
                    ),
                  ),
                  Container(
                    height: 40.0,
                    width: 400.0,
                    color: Colors.white,
                    child: Image.asset('Assets/legend.PNG'),
                    // Text("This is a sample txtd to understand FittedBox widget"),
                  ),
                ],
              )
            ),
          ],
        )
      ),
    );
  }
}
