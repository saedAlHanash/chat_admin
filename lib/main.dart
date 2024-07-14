import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/services/caching_service/caching_service.dart';
import 'package:fitness_admin_chat/services/chat_service/chat_service_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app/app_widget.dart';
import 'core/injection/injection_container.dart' as di;
import 'core/injection/injection_container.dart';
import 'core/util/shared_preferences.dart';
import 'features/chat/messages_bloc/messages_cubit.dart';
import 'features/chat/open_room_cubit/open_room_cubit.dart';
import 'features/chat/rooms_bloc/rooms_cubit.dart';
import 'features/chat/userss_bloc/users_bloc.dart';
import 'firebase_options.dart';

//adb shell setprop debug.firebase.analytics.app com.slf.sadaf
FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CachingService.initial();


  await Note.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SharedPreferences.getInstance().then((value) {
    AppSharedPreference.init(value);
  });

  await di.init();

  await ChatServiceCore.initFirebaseChat();
  loggerObject.w(await getFireToken());
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<OpenRoomCubit>()),
        BlocProvider(create: (_) => sl<RoomsCubit>()..getChatRooms()),
        BlocProvider(create: (_) => sl<UsersCubit>()..getChatUsers()),
        BlocProvider(create: (_) => sl<MessagesCubit>()),

      ],
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

  if (flutterLocalNotificationsPlugin == null) {
    Note.initialize();
  }
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
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var androidInitialize = const AndroidInitializationSettings('mipmap/ic_launcher');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    await flutterLocalNotificationsPlugin!.initialize(initializationsSettings);
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

    await flutterLocalNotificationsPlugin?.show(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000), title, body, not);
  }
}
