import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:track/coordinates.dart';

import 'package:flutter/foundation.dart';
import 'package:track/radiusStorage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SetRadius extends StatefulWidget {
  final CounterStorage storage;

  SetRadius({Key key, @required this.storage}) : super(key: key);

  @override
  _SetRadiusState createState() => _SetRadiusState();
}

class _SetRadiusState extends State<SetRadius> {
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

  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(243, 245, 248, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 24,
                  ),
                  Center(
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            "Child Locations",
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32),
                    ),
                  ),
                  SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 16,
                  ),
                  //Container Listview for expenses and incomes
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
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
                                          myModels[index].vehicleId.toString(),
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
                          controller: ScrollController(keepScrollOffset: false),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text("Failed contact child device"));
                      }
                      return Center(child:CircularProgressIndicator());
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
