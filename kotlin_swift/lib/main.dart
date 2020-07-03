import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
  String _launchMessage;
  @override
  void initState() {
    super.initState();
    initializePlugins();
  }

  Future<void> initializePlugins() async {
    _firebaseMessaging.configure(onMessage: (message) async {
      print('onMessage: $message');
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your channel description',
        importance: Importance.Max,
        priority: Priority.High,
      );
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      var title = '';
      if (Platform.isIOS) {
        title = message['aps']['alert']['title'];
      } else if (Platform.isAndroid) {
        title = message['notification']['title'];
      }

      var body = '';
      if (Platform.isIOS) {
        body = message['aps']['alert']['body'];
      } else if (Platform.isAndroid) {
        body = message['notification']['body'];
      }
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
      );
    }, onLaunch: (message) async {
      setState(() {
        _launchMessage = message.toString();
      });
      print('onLaunch: $message');
    }, onResume: (message) async {
      print('onResume: $message');
    });
    final result = await _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    if (result != null) {
      print('permissioned requested $result');
      await initializeFlutterLocalNotificationsPlugin();
    } else if (Platform.isAndroid) {
      await initializeFlutterLocalNotificationsPlugin();
    }
    final token = await _firebaseMessaging.getToken();
    print('token: $token');
    if (mounted) {
      setState(() {
        _token = token;
      });
    } else {
      _token = token;
    }
  }

  Future<void> initializeFlutterLocalNotificationsPlugin() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<void> onSelectNotification(String payload) async {
    debugPrint('onSelectNotification');
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase sample'),
      ),
      body: Column(
        children: [
          Text('FCM token: ${_token ?? ''}'),
          Text('Launch message: ${_launchMessage ?? ''}'),
          RaisedButton(
            child: Text('show local notification'),
            onPressed: () async {
              var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                'your channel id',
                'your channel name',
                'your channel description',
                importance: Importance.Max,
                priority: Priority.High,
              );
              var iOSPlatformChannelSpecifics = IOSNotificationDetails();
              var platformChannelSpecifics = NotificationDetails(
                  androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
              await _flutterLocalNotificationsPlugin.show(
                  1, 'plain title', 'plain body', platformChannelSpecifics,
                  payload: 'item x');
            },
          )
        ],
      ),
    );
  }

  FutureOr onValue(bool value) {}
}
