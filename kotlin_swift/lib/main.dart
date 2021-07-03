import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String backgroundMessageIdKey = 'backgroundMessageId';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
RemoteMessage initialRemoteMessage;
NotificationAppLaunchDetails launchNotificationDetails;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  sharedPreferences.setString(backgroundMessageIdKey, message.messageId);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initialRemoteMessage = await _firebaseMessaging.getInitialMessage();

  launchNotificationDetails =
      await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  runApp(MyApp());
}

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
  String selectedLocalNotification = '';
  String selectedRemoteNotification = '';
  String backgroundMessageId = '';

  @override
  void initState() {
    super.initState();
    initializePlugins();
  }

  Future<void> initializePlugins() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _firebaseMessaging.requestPermission(
        sound: true, badge: true, alert: true);
    await initializeFlutterLocalNotificationsPlugin();
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) async {
      print('onMessage: $message');
      setState(() {
        selectedRemoteNotification = message.notification.body;
      });
      if (Platform.isIOS) {
        return;
      }
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your channel description',
        importance: Importance.max,
        priority: Priority.high,
      );
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await _flutterLocalNotificationsPlugin.show(
        0,
        message.notification.title,
        message.notification.body,
        platformChannelSpecifics,
      );
    });

    _firebaseMessaging.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    final token = await _firebaseMessaging.getToken();
    _saveToken(token);

    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey(backgroundMessageIdKey)) {
      backgroundMessageId = sharedPreferences.getString(backgroundMessageIdKey);
      if (mounted) {
        setState(() {});
      }
      // clear for next test
      sharedPreferences.clear();
    }
  }

  void _saveToken(String token) {
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
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<void> onSelectNotification(String payload) async {
    setState(() {
      selectedLocalNotification = payload;
    });
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
          SelectableText('FCM token: ${_token ?? ''}'),
          Text(
              'Initial remote message: ${(initialRemoteMessage?.notification?.body ?? '')}'),
          Text(
              'Launch notification payload: ${(launchNotificationDetails?.payload ?? '')}'),
          Text('Background message id: $backgroundMessageId'),
          Text('Selected remote message: $selectedRemoteNotification'),
          Text('Selected local message: $selectedLocalNotification'),
          ElevatedButton(
            child: Text('show local notification'),
            onPressed: () async {
              var androidPlatformChannelSpecifics = AndroidNotificationDetails(
                'your channel id',
                'your channel name',
                'your channel description',
                importance: Importance.max,
                priority: Priority.high,
              );
              var iOSPlatformChannelSpecifics = IOSNotificationDetails();
              var platformChannelSpecifics = NotificationDetails(
                  android: androidPlatformChannelSpecifics,
                  iOS: iOSPlatformChannelSpecifics);
              await _flutterLocalNotificationsPlugin.show(
                  1, 'plain title', 'plain body', platformChannelSpecifics,
                  payload: 'item x');
            },
          )
        ],
      ),
    );
  }
}
