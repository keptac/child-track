import 'package:flutter/material.dart';
import 'package:track/home.dart';
import 'package:track/pushNotification.dart';
import 'package:track/radiusStorage.dart';
import 'package:track/track.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Child Track',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChildTrack(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class ChildTrack extends StatefulWidget {
  @override
  _ChildTrackState createState() => _ChildTrackState();
}

class _ChildTrackState extends State<ChildTrack> {

  PushNotificationsManager notify = PushNotificationsManager();

  var screens = [
    FlutterDemo(storage: CounterStorage()),
    FireMap(storage: CounterStorage()),
  ];

  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    notify.init();

    return Scaffold(
      appBar: AppBar(
        title: Text('CHILD TRACK'),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(38, 81, 158, 1),
      ),
      backgroundColor: Color.fromRGBO(38, 81, 158, 1),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: Color.fromRGBO(38, 81, 158, 1),
              ),
              title: Text("Home")),
              
          BottomNavigationBarItem(
              icon: Icon(
                Icons.location_on,
                color: Color.fromRGBO(38, 81, 158, 1),
              ),
              title: Text("Child Location")),
        ],
        onTap: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        showUnselectedLabels: true,
        iconSize: 30,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: screens[selectedTab],
    );
  }
}
