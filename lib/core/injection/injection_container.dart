import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/chat/group_session_bloc/group_session_rooms_cubit.dart';
import '../../features/chat/messages_bloc/messages_cubit.dart';
import '../../features/chat/open_room_cubit/open_room_cubit.dart';
import '../../features/chat/rooms_bloc/rooms_cubit.dart';
import '../../features/chat/userss_bloc/users_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //region Core
  sl.registerLazySingleton(() => MessagesCubit());
  sl.registerLazySingleton(() => RoomsCubit());
  sl.registerLazySingleton(() => GroupSessionRoomsCubit());
  sl.registerLazySingleton(() => UsersCubit());
  sl.registerLazySingleton(() => OpenRoomCubit());

  sl.registerLazySingleton(() => GlobalKey<NavigatorState>());
  //endregion
}
