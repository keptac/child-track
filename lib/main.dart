import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:math' show cos, sqrt, asin;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(appBar: AppBar(title: Text('Track')), body: FireMap()));
  }
}

class FireMap extends StatefulWidget {
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  BehaviorSubject<double> radius = BehaviorSubject.seeded(5.0);
  Stream<dynamic> query;
  StreamSubscription subscription;
  final Set<Marker> _markers = {};

  LatLng _lastMapPosition = LatLng(-17.823, 30.955);

  @override
  dispose() {
    subscription.cancel();
    super.dispose();
  }

  build(context) {
    _startQuery();
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition:
              CameraPosition(target: _lastMapPosition, zoom: 10),
          myLocationEnabled: true,
          mapType: MapType.normal,
          markers: _markers,
        ),
        Positioned(
          bottom: 50,
          right: 10,
          child: FlatButton(
            child: Icon(Icons.pin_drop),
            color: Colors.green,
            onPressed: () => _addGeoPoint(),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 10,
          child: Slider(
            min: 1.0,
            max: 20.0,
            divisions: 5,
            value: radius.value,
            label: 'Radius ${radius.value}km',
            activeColor: Colors.green,
            inactiveColor: Colors.green.withOpacity(0.2),
            onChanged: _updateQuery,
          ),
        ),
      ],
    );
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['position']['geopoint'];
      double distance = calculateDistance(pos.latitude, pos.longitude,
          _lastMapPosition.latitude, _lastMapPosition.longitude);
      print(distance);

      setState(() {
        _markers.add(Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          position: LatLng(pos.latitude, pos.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: 'Child Location 🍄🍄🍄',
            snippet: '$distance kilometers from you',
          ),
        ));
      });

      // mapController.addMarker(marker);
    });
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();

    double lat = pos.latitude;
    double lng = pos.longitude;

    _lastMapPosition = LatLng(lat, lng);

    // Make a referece to firestore
    var ref = firestore.collection('locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    // Subscribe to query
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: center, radius: rad, field: 'position');
    }).listen(_updateMarkers);
  }

  _updateQuery(value) {
    setState(() {
      radius.add(value);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

// Add locations to firestore
  Future<DocumentReference> _addGeoPoint() async {
    var pos = await location.getLocation();
    GeoFirePoint point =
        // geo.point(latitude: -17.8239996, longitude: 30.9559996);
    geo.point(latitude: pos.latitude, longitude: pos.longitude);
    return firestore.collection('locations').add({
      'position': point.data,
      'name': 'Momy, Dady Im here!',
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
