import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;

import 'package:rxdart/rxdart.dart';

class Home extends StatefulWidget {
  @override
  State createState() => HomeScreen();
}

class HomeScreen extends State<Home> {
  double distance = 0.0;
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  BehaviorSubject<double> radius = BehaviorSubject.seeded(5.0);
  StreamSubscription subscription;
  Stream<dynamic> query;

  LatLng _lastMapPosition = LatLng(-17.823, 30.955);

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) async {
    print(documentList);
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['position']['geopoint'];
      double calDist = calculateDistance(pos.latitude, pos.longitude,
          _lastMapPosition.latitude, _lastMapPosition.longitude);

      if (distance > 2000) {
        print(distance);
      }

      setState(() {
        distance = double.parse(calDist.toStringAsFixed(2)) * 1000;
      });
    });
  }

  _startQuery() async {
    // Get users location
    var pos = await location.getLocation();
    print(pos);
    double lat = pos.latitude;
    double lng = pos.longitude;
    _lastMapPosition = LatLng(lat, lng);
    // Make a referece to firestore
    var ref = firestore.collection('locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    // Subscribe to query
    subscription = radius.switchMap((rad) {
      return geo
          .collection(collectionRef: ref)
          .within(center: center, radius: rad, field: 'position');
    }).listen(_updateMarkers);
  }

  @override
  Widget build(BuildContext context) {
    _startQuery();
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          //Container for top data
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            height: 30,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(243, 245, 248, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(18))),
                            child: Icon(
                              Icons.notification_important,
                              color: Colors.blue[900],
                              size: 30,
                            ),
                            padding: EdgeInsets.all(12),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "Alerts",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.blue[100]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(243, 245, 248, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(18))),
                            child: Icon(
                              Icons.public,
                              color: Colors.blue[900],
                              size: 30,
                            ),
                            padding: EdgeInsets.all(12),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "Beep",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.blue[100]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(243, 245, 248, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(18))),
                            child: Icon(
                              Icons.settings,
                              color: Colors.blue[900],
                              size: 30,
                            ),
                            padding: EdgeInsets.all(12),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            "Settings",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.blue[100]),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          //draggable sheet
          DraggableScrollableSheet(
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                    color: Color.fromRGBO(243, 245, 248, 1),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40))),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 24,
                      ),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Your Children",
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32),
                      ),
                      SizedBox(
                        height: 24,
                      ),

                      SizedBox(
                        height: 16,
                      ),
                      //Container Listview for expenses and incomes
                      Container(
                        child: Text(
                          "TODAY",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[500]),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32),
                      ),

                      SizedBox(
                        height: 16,
                      ),

                      ListView.builder(
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(
                                left: 32, right: 32, bottom: 20),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(13))),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.lightBlue[900],
                                  ),
                                  padding: EdgeInsets.all(12),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "Shepherd",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[900]),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      "$distance Metres Away",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: distance > 300
                                              ? Colors.red
                                              : Colors.lightGreen),
                                    ),
                                    Text(
                                      DateTime.now().toString(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        shrinkWrap: true,
                        itemCount: 1,
                        padding: EdgeInsets.only(bottom: 30.0),
                        controller: ScrollController(keepScrollOffset: false),
                      ),
                    ],
                  ),
                  controller: scrollController,
                ),
              );
            },
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 1,
          )
        ],
      ),
    );
  }
}
