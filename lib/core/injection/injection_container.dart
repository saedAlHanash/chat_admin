import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/chat/util.dart';
import '../network/network_info.dart';
import '../util/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //region Core

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectionChecker: sl()));
  sl.registerLazySingleton(() => InternetConnectionChecker());

  sl.registerLazySingleton(() => GlobalKey<NavigatorState>());
  initFirebaseChat();
  //endregion
}

Future<void> initFirebaseChat() async {

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    firebaseUser = user;
    if (user == null) {
      loginChatUser();
      return;
    }
  });
}
