import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:logger/logger.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/app/app_widget.dart';
import 'core/injection/injection_container.dart';
import 'core/util/shared_preferences.dart';
import 'features/main/get_chats_rooms_bloc/get_rooms_cubit.dart';
import 'firebase_options.dart';
import 'core/injection/injection_container.dart' as di;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

//adb shell setprop debug.firebase.analytics.app com.slf.sadaf
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
late Box<String> roomsBox;
late Box usersBox;
late Box<String> roomMessage;
late Box<int> latestUpdateMessagesBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  roomsBox = await Hive.openBox('rooms');
  latestUpdateMessagesBox = await Hive.openBox('messages');
  usersBox = await Hive.openBox('users');
  await Note.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SharedPreferences.getInstance().then((value) {
    AppSharedPreference.init(value);
  });

  await di.init();

  HttpOverrides.global = MyHttpOverrides();
  runApp(
    BlocProvider(
      create: (context) => sl<GetRoomsCubit>()..getChatRooms(),
      child: const MyApp(),
    ),
  );
}

Future<String> getFireToken() async {
  var cashedToken = AppSharedPreference.getFireToken();

  if (cashedToken.isNotEmpty) {
    return cashedToken;
  }

  String? token = await FirebaseMessaging.instance.getToken();

  if (token != null) AppSharedPreference.cashFireToken(token);

  Logger().d(token);

  return token ?? '';
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notification = message.notification;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String title = '';
  String body = '';

  if (notification != null) {
    title = notification.title ?? '';
    body = notification.body ?? '';
  } else {
    title = message.data['title'] ?? '';
    body = message.data['body'] ?? '';
  }
  if (AppSharedPreference.getActiveNotification()) {
    Note.showBigTextNotification(title: title, body: body);
  }

  AppSharedPreference.addNotificationCount();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}

class Note {
  static Future initialize() async {
    var androidInitialize = const AndroidInitializationSettings('mipmap/ic_launcher');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }

  static Future showBigTextNotification({
    var id = 0,
    required String title,
    required String body,
    var payload,
  }) async {
    // var vibrationPattern = Int64List(2);
    // vibrationPattern[0] = 1000;
    // vibrationPattern[1] = 1000;

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Fitness',
      'Fitness Storm',
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
      importance: Importance.defaultImportance,
      priority: Priority.high,
    );

    var not = const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000), title, body, not);
  }
}
