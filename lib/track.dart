import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'package:track/coordinates.dart';

class FireMap extends StatefulWidget {
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  BehaviorSubject<double> radius = BehaviorSubject.seeded(5.0);
  Stream<dynamic> query;
  StreamSubscription subscription;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  double distance = 0;
  static double radi = 10.0;

  LatLng _lastMapPosition = LatLng(-17.823, 30.955);
  static LatLng _radiusLocation = LatLng(-17.823, 30.955);

  Future<CoordinatesValue> futureCoordinatesValue;
  List<CoordinatesValue> myModels;

  Future<CoordinatesValue> fetchCoordinates() async {
    final response =
        await http.get('http://nyasha-vehicle-2.herokuapp.com/vehicleTracker');

    if (response.statusCode == 200) {
      myModels = (json.decode(response.body) as List)
          .map((i) => CoordinatesValue.fromJson(i))
          .toList();
      return CoordinatesValue.fromJson(json.decode(response.body)[0]);
    } else {
      throw Exception('Failed to load coordinates');
    }
  }

  Set<Circle> circles = Set.from([
    Circle(
      strokeWidth: 1,
      strokeColor: Colors.blue,
      fillColor: Color.fromRGBO(0, 120, 0, 0.1),
      circleId: CircleId("Parent location"),
      center: LatLng(_radiusLocation.latitude, _radiusLocation.longitude),
      radius: radi,
    ),
  ]);

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }

  myDistance() async {
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;
    _lastMapPosition = LatLng(lat, lng);
    _radiusLocation = _lastMapPosition;
  }

  double calculateDistance(lat1, lon1) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((_lastMapPosition.latitude - lat1) * p) / 2 +
        c(lat1 * p) *
            c(_lastMapPosition.latitude * p) *
            (1 - c((_lastMapPosition.longitude - lon1) * p)) /
            2;
    distance = (12742 * asin(sqrt(a))) * 1000;
    return (12742 * asin(sqrt(a))) * 1000;
  }

  Widget build(BuildContext context) {
    futureCoordinatesValue = fetchCoordinates();
    return FutureBuilder<dynamic>(
        future: futureCoordinatesValue,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _updateMarkers();
            myDistance();
            Timer(Duration(seconds: 10), () {
              myDistance();
            }
            );
  
            return Stack(
              children: [
                GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition:
                        CameraPosition(target: _lastMapPosition, zoom: 100),
                    myLocationEnabled: true,
                    mapType: MapType.normal,
                    markers: Set<Marker>.of(markers.values),
                    trafficEnabled: true,
                    circles: circles,
                    myLocationButtonEnabled: true),
                Positioned(
                  bottom: 50,
                  left: 10,
                  child: Slider(
                    min: 1.0,
                    max: 50.0,
                    divisions: 5,
                    value: radius.value,
                    label: 'Radius ${radius.value} m',
                    activeColor: Colors.green,
                    inactiveColor: Colors.green.withOpacity(0.2),
                    onChanged: _updateQuery,
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text("HElllo   ${snapshot.error}");
          }
          return Center(child: CircularProgressIndicator());
        
        });
  }

  void _updateMarkers() {
    print('\n--------------------MARKERS----------------------------');
    print(markers);
    print(myModels);
    print('--------------------MArkerts end--------------------\n');

    for (CoordinatesValue item in myModels) {
      double distance = calculateDistance(
        item.currentLocationLatitude,
        item.currentLocationLongitude,
      );

      var markerIdVal = markers.length + 1;
      String mar = markerIdVal.toString();
      final MarkerId markerId = MarkerId(mar);
      final Marker marker = Marker(
        markerId: markerId,
        position:
            LatLng(item.currentLocationLatitude, item.currentLocationLongitude),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: '🍄 Child ${item.vehicleId} Location 🍄',
          snippet: distance.toStringAsFixed(2) + ' Meters from you',
        ),
      );

      markers[markerId] = marker;

      
     circles.add(Circle(
          strokeWidth: 1,
          strokeColor: Colors.yellow,
          fillColor: Color.fromRGBO(0, 120, 0, 0.1),
          circleId: CircleId("Child location"),
          center: LatLng(
              item.currentLocationLatitude, item.currentLocationLongitude),
          radius: radi,
        ));
    }
  }

  _updateQuery(value) {
    print(value);
    setState(() {
      radius.add(value);
      radi = value;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}
