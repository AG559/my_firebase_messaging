import 'package:flutter/material.dart';
import 'package:my_flutter_messaging/About.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Home.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final BehaviorSubject<String> selectNotificationSubject =
BehaviorSubject<String>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationAppLaunchDetails notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectNotificationSubject.add(payload);
      });
  runApp(MaterialApp(
    routes: {
      '/': (context) => LoginScreen(),
      '/home': (context) => HomeScreen(),
      '/about': (context) => AboutScreen(),
    },
  ));
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _configureSelectNotificationSubject();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        final SharedPreferences prefs = await _prefs;
        var loginStatus = prefs.getBool("login_status");
        if(loginStatus!= null && loginStatus){
          _showNotification();
        }else{
          print("_onMessage  status $loginStatus");
        }
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // _navigateToItemDetail(message);
      },
    );
    _firebaseMessaging.getToken().then((value) => print(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [Text("Login Screen"),
          RaisedButton(onPressed:()async{
            final SharedPreferences prefs = await _prefs;
            prefs.setBool("login_status", true);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (BuildContext context) => HomeScreen()),
            );
          },
            child: Text("Login"),)],
        ),
      ),
    );
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    super.dispose();
  }

  void _configureSelectNotificationSubject() async{
    selectNotificationSubject.stream.listen((String payload) async {
      final SharedPreferences prefs = await _prefs;
      var loginStatus = prefs.getBool("login_status");
      if(loginStatus!= null && loginStatus){
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (BuildContext context) => AboutScreen()),
        );
      }else{
        print("_config Select Noti Subject status $loginStatus");
      }
    });
  }
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
  // Or do other work.
}
