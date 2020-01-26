import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              myLocationEnabled: true,
              circles: circles,
        ),
        Positioned(
          left : 0.0, 
          right : 0.0, 
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
          )
        ),
        ],
        )

      ),
    );
  }
}
