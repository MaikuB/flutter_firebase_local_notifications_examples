import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _token;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(onMessage: (message) async {
      print('onMessage: $message');
    }, onLaunch: (message) async {
      print('onLaunch: $message');
    }, onResume: (message) async {
      print('onResume: $message');
    });
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.getToken().then((token) {
      print('token: $token');
      if (mounted) {
        setState(() {
          _token = token;
        });
      } else {
        _token = token;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase sample'),
      ),
      body: Center(
        child: Text(_token == null ? '' : _token),
      ),
    );
  }
}
