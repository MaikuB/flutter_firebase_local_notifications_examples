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

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
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

  Future<void> onSelectNotification(String payload) async {
    debugPrint('onSelectNotification');
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    /*await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecondScreen(payload)),
    );*/
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
          Text('FCM token: ${_token == null ? '' : _token}'),
          RaisedButton(
            child: Text('show notification'),
            onPressed: () async {
              var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                  'your channel id',
                  'your channel name',
                  'your channel description',
                  importance: Importance.Max,
                  priority: Priority.High,
                  ticker: 'ticker');
              var iOSPlatformChannelSpecifics = IOSNotificationDetails();
              var platformChannelSpecifics = NotificationDetails(
                  androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
              await _flutterLocalNotificationsPlugin.show(
                  0, 'plain title', 'plain body', platformChannelSpecifics,
                  payload: 'item x');
            },
          )
        ],
      ),
    );
  }
}
