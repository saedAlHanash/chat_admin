import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/features/chat/userss_bloc/users_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../features/chat/messages_bloc/messages_cubit.dart';
import '../../features/chat/open_room_cubit/open_room_cubit.dart';
import '../../features/chat/rooms_bloc/rooms_cubit.dart';
import '../../features/chat/util.dart';

import '../network/network_info.dart';
import '../util/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //region Core
  sl.registerLazySingleton(() => MessagesCubit());
  sl.registerLazySingleton(() => RoomsCubit());
  sl.registerLazySingleton(() => UsersCubit());
  sl.registerLazySingleton(() => OpenRoomCubit());

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectionChecker: sl()));
  sl.registerLazySingleton(() => InternetConnectionChecker());

  sl.registerLazySingleton(() => GlobalKey<NavigatorState>());
  //endregion
}
