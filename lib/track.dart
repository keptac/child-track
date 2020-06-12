import 'dart:async';
import 'dart:convert';


import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'package:track/coordinates.dart';
import 'package:flutter/foundation.dart';
import 'package:track/radiusStorage.dart';

class FireMap extends StatefulWidget {
  final CounterStorage storage;

  FireMap({Key key, @required this.storage}) : super(key: key);
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  Location location = new Location();

  Stream<dynamic> query;
  StreamSubscription subscription;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  double distance = 0;
  static double _radi = 0;

  LatLng _lastMapPosition = LatLng(-20.1612,28.6355);
  static LatLng _radiusLocation = LatLng(-20.1612,28.6355);

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
      strokeColor: Colors.red,
      fillColor: Color.fromRGBO(0, 120, 0, 0.1),
      circleId: CircleId("Parent location"),
      center: LatLng(_radiusLocation.latitude, _radiusLocation.longitude),
      radius: _radi,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    myLocationFinder();
    widget.storage.readCounter().then((int value) {
      setState(() {
        _radi = value.toDouble();
      });
    });
    futureCoordinatesValue = fetchCoordinates();
  }

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }


  myLocationFinder() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    await location.getLocation().then((onValue) {
      double lat = onValue.latitude;
      double lng = onValue.longitude;
      setState(() {
         _lastMapPosition = LatLng(lat, lng);
         _radiusLocation = _lastMapPosition;
      });
    });
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
            myLocationFinder();
            Timer(Duration(seconds: 10), () {
              myLocationFinder();
            });

            return Stack(
              children: [
                GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition:
                        CameraPosition(target: _lastMapPosition, zoom: 25),
                    myLocationEnabled: true,
                    mapType: MapType.normal,
                    markers: Set<Marker>.of(markers.values),
                    trafficEnabled: true,
                    circles: circles,
                    myLocationButtonEnabled: true),
              ],
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return Center(child: CircularProgressIndicator());
        });
  }

  void _updateMarkers() {
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
        center:
            LatLng(item.currentLocationLatitude, item.currentLocationLongitude),
        radius: _radi,
      ));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }
}
