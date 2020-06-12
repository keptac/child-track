import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:track/coordinates.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:track/radiusStorage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FlutterDemo extends StatefulWidget {
  final CounterStorage storage;

  FlutterDemo({Key key, @required this.storage}) : super(key: key);

  @override
  _FlutterDemoState createState() => _FlutterDemoState();
}

class _FlutterDemoState extends State<FlutterDemo> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  var initializationSettingsAndroid;
  var initializationSettingsIOS;
  var initializationSettings;

  void _showNotification() async {
    await _childNotification();
  }

  Future<void> _childNotification() async {
    var androidPlatfromChannnelSpecifics = AndroidNotificationDetails(
        'channelId', 'channelName', 'channelDescription',
        importance: Importance.Max,
        priority: Priority.Max,
        ticker: 'Child Ticker');
    var iosChannelSpecs = IOSNotificationDetails();
    var platformChannelSpec =
        NotificationDetails(androidPlatfromChannnelSpecifics, iosChannelSpecs);

    await flutterLocalNotificationsPlugin.show(0, 'Child Location',
        'Your child has gone out of your reach', platformChannelSpec,
        payload: 'Text payload');
  }

  double distance = 0;
  double radius = 10;
  GoogleMapController mapController;
  Location location = Location();

  LatLng _lastMapPosition = LatLng(-20.1612, 28.6355);
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

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('Notification payload: $payload');
    }
    // await Navigator.push(context, MaterialPageRoute(builder: (context)=>SecondRoute()));
    new CircularProgressIndicator();
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String pa) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('OK'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                // await Navigator.push(context, MaterialPageRoute(builder: (context)=>SecondRoute()));
                CircularProgressIndicator();
              }),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');

    initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    widget.storage.readCounter().then((int value) {
      setState(() {
        radius = value.toDouble();
      });
    });
    futureCoordinatesValue = fetchCoordinatesValue();
    myLocation();
  }

  myLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    // LocationData _locationData ;

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

    await location.getLocation().then((onValue) {
      double lat = onValue.latitude;
      double lng = onValue.longitude;
      setState(() {
        _lastMapPosition = LatLng(lat, lng);
      });
    });
  }

  _getAddress(lat1, lon1) async {
    final coordinates = new Coordinates(lat1, lon1);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);

    var first = addresses.first;
    return first.addressLine.toString();
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

    if (distance > radius) {
      _showNotification();
    }

    print(_lastMapPosition.latitude);

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Container(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Change your geofence radius',
                      style: TextStyle(fontSize: 18),
                    ),
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
      },
    );
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
                              Icons.location_searching,
                              color: Colors.orange,
                              size: 40,
                            ),
                            padding: EdgeInsets.all(12),
                          ),
                          onTap: () => popup(),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Click to here change monitoring distance\n\n $radius metres",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
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
                    image: DecorationImage(
                        image: AssetImage('assets/images/loc.jpg'),
                        fit: BoxFit.cover),
                    color: Color.fromRGBO(243, 245, 248, 1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                  ),
                  child: Stack(children: <Widget>[
                    SingleChildScrollView(
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
                                  "CHILD LOCATION",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 32),
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          FutureBuilder<dynamic>(
                            future: futureCoordinatesValue,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ListView.builder(
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: EdgeInsets.only(
                                          left: 32, right: 32, bottom: 10),
                                      elevation: 5.0,
                                      child: Container(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.all(
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
                                                    'Device ' +
                                                        myModels[index]
                                                            .vehicleId
                                                            .toString(),
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Colors.grey[900]),
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: distance > radius
                                                          ? Colors.red
                                                          : Colors.lightGreen),
                                                ),

                                                // Text(_getAddress(
                                                //         myModels[index]
                                                //             .currentLocationLatitude,
                                                //         myModels[index]
                                                //             .currentLocationLongitude)
                                                //     .toString()),
                                              ],
                                            ),
                                          ],
                                        ),
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
                                return Center(
                                    child: Text("Failed contact child device"));
                              }
                              return Center(child: CircularProgressIndicator());
                            },
                          ),
                        ],
                      ),
                      controller: scrollController,
                    ),
                  ]));
            },
            initialChildSize: 0.60,
            minChildSize: 0.60,
            maxChildSize: 1,
          )
        ],
      ),
    );
  }
}
