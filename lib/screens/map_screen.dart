import 'dart:async';
import 'dart:convert';

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
  BitmapDescriptor myIcon;
  Set<Circle> circles = {}; // CLASS MEMBER, MAP OF Circle
  Set<Marker> markers = {};
  // Set<Circle> circles = Set.from([
  //   Circle(
  //     circleId: CircleId("current_location"),
  //     center: LatLng(40.4285364, -86.9240971),
  //     fillColor: Color.fromARGB(128, 51, 153, 153),
  //     strokeColor: Color.fromARGB(160, 51, 153, 153),
  //     radius: 4000,
  //   )
  // ]);

  final LatLng _center = const LatLng(40.4285364, -86.9240971);
  LocationData currentLocation;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(64, 64)), 'Assets/music.png')
        .then((onValue) {
      myIcon = onValue;
    });

    Timer(Duration(milliseconds: 200), _getBounds);
  }

  void _onCameraMoveStarted() {
    print('_onCameraMoveStarted');
  }

  void _onCamerMoveIdle() {
    print('_onCamerMoveIdle');
  }

  void drawCircles(List<dynamic> vibes){
      circles.clear();
      markers.clear();
      Circle vibeCircle;
      for(dynamic vibe in vibes){
        // print(vibe['location_id'].toString());
        // print(LatLng(vibe['latitude'], vibe['longitude']).toString());
        print(vibe['genre'].toString());
        double rad = (vibe['genre_total_count']* 15).toDouble();
        vibeCircle = new Circle(
          circleId: CircleId(vibe['location_id'].toString()),
          center:LatLng(vibe['latitude'], vibe['longitude']),
          fillColor: genreColorMap[vibe['genre'].toString()],
          radius: rad,
          consumeTapEvents : true,
          // onTap: () {
            );


            Marker marker = new Marker (
              anchor: Offset(0.5, 0.5),
                markerId: MarkerId((vibe['location_id'].toString())),
                position: LatLng(vibe['latitude'], vibe['longitude']),
                visible: true,
                alpha: 0.0,
                //icon: myIcon,
                infoWindow: new InfoWindow(
                  title: "Song: " + vibe["title"],
                  snippet: "Album: " + vibe["album"],
                )
              );
            
          // },
        markers.add(marker);
        circles.add(vibeCircle);
      }
      // Circle c = new Circle(
      // circleId: CircleId("current_location"),
      // center: LatLng(40.4285364, -86.9240971),
      // fillColor: Color.fromARGB(128, 51, 153, 153),
      // strokeColor: Color.fromARGB(160, 51, 153, 153),
      // radius: 4000);
      setState(() {
      });
  }

  void drawMarkers(List<dynamic> vibes){

      setState(() {



      });
  }

  _getBounds() async {
    print(this.mapController.toString());
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
        'https://vibecheck.tk/api/vibe?lat_min=${lat_min}&lat_max=${lat_max}&lon_min=${lon_min}&lon_max=${lon_max}&divisions=16');

    if (resp.statusCode == 200) {
      Map<String, dynamic> map = jsonDecode(resp.body);

      List<dynamic> vibes = map['vibes'];

      drawCircles(vibes);

      print("We got the vibes");
      print(map);
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
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraIdle: _onCamerMoveIdle,
              initialCameraPosition: CameraPosition(
                target: _center,
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
                      onPressed: _getBounds,
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
