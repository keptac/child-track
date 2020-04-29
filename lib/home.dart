import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:track/coordinates.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:track/radiusStorage.dart';

class FlutterDemo extends StatefulWidget {
  final CounterStorage storage;

  FlutterDemo({Key key, @required this.storage}) : super(key: key);

  @override
  _FlutterDemoState createState() => _FlutterDemoState();
}

class _FlutterDemoState extends State<FlutterDemo> {  



  double distance = 0;
  double radius; // In meters
  GoogleMapController mapController;
  Location location = new Location();
  Firestore firestore = Firestore.instance;
  LatLng _lastMapPosition = LatLng(-17.823, 30.955);
  Stream<dynamic> query;

  Future<CoordinatesValue> futureCoordinatesValue;
  List<CoordinatesValue> myModels;

  Future<CoordinatesValue> fetchCoordinatesValue() async {
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

  @override
  void initState() {
    super.initState();
    widget.storage.readCounter().then((int value) {
      setState(() {
        radius = value.toDouble();
      });
    });
    futureCoordinatesValue = fetchCoordinatesValue();
    myDistance();
  }

  myDistance() async {
    var pos = await location.getLocation();
    double lat = pos.latitude;
    double lng = pos.longitude;
    _lastMapPosition = LatLng(lat, lng);
    print(_lastMapPosition);
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

  Future<File> _changeDistance(int value) {
    return widget.storage.writeCounter(value);
  }

   popup() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text('Change your geofence radius',style: TextStyle(fontSize: 18),),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Slider(
                      min: 0.0,
                      max: 300.0,
                      divisions: 5,
                      value: radius,
                      label: 'Radius $radius m',
                      activeColor: Colors.green,
                      inactiveColor: Colors.green.withOpacity(0.2),
                      onChanged: (double newValue) {
                        setState(() {
                          radius = newValue;
                          _changeDistance(radius.toInt());
                        });
                        
                      },
                    ),
                    Center(
                      child: FlatButton(
                        color: Colors.green[900],
                        child: Text(
                          "Done",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        InkWell(
                          child: Container(
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
                          onTap: () => popup(),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Monitoring distance\n\n $radius metres",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.blue[100]),
                        ),
                      ],
                    ),
                  ),
                ),
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
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
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
                          "Locations",
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

                      FutureBuilder<dynamic>(
                        future: futureCoordinatesValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ListView.builder(
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(
                                      left: 32, right: 32, bottom: 20),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
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
                                              myModels[index]
                                                  .vehicleId
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey[900]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            calculateDistance(
                                                        myModels[index]
                                                            .currentLocationLatitude,
                                                        myModels[index]
                                                            .currentLocationLongitude)
                                                    .toStringAsFixed(2) +
                                                " M",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: distance > radius
                                                    ? Colors.red
                                                    : Colors.lightGreen),
                                          ),
                                          Text(
                                            myModels[index].time,
                                            style: TextStyle(
                                                fontSize: 14,
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
                              itemCount: myModels.length,
                              padding: EdgeInsets.only(bottom: 30.0),
                              controller:
                                  ScrollController(keepScrollOffset: false),
                            );
                          } else if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          }
                          return CircularProgressIndicator();
                        },
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
