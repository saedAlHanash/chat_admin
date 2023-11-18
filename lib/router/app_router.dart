import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitness_admin_chat/core/strings/enum_manager.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../core/injection/injection_container.dart' as di;
import '../core/injection/injection_container.dart';
import '../features/chat/chat.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/room_messages_bloc/room_messages_cubit.dart';
import '../features/chat/util.dart';
import '../features/main/main_screen.dart';
import '../features/splash/ui/pages/splash_screen.dart';

class AppRoutes {
  static Route<dynamic> routes(RouteSettings settings) {
    var screenName = settings.name;

    switch (screenName) {
      //region auth
      case RouteName.splash:
        //region
        return MaterialPageRoute(builder: (_) => const SplashScreenPage());
      //endregion

      //region auth
      case RouteName.home:
        //region
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      //endregion

      case RouteName.chat:
        //region
        {
          return MaterialPageRoute(
            builder: (context) {
              final room = settings.arguments as Room;
              return BlocProvider(
                create: (context) => sl<RoomMessagesCubit>()..getChatRoomMessage(room),
                child: ChatPage(
                  room: room,
                  name: getChatMember(room.users).lastName ?? '',
                ),
              );
            },
          );
        }
      case RouteName.search:
        //region
        {
          return MaterialPageRoute(
            builder: (context) {
              return const ChatScreen();
            },
          );
        }

      //endregion
    }

    return MaterialPageRoute(builder: (_) => const Scaffold(backgroundColor: Colors.red));
  }
}

class RouteName {
  static const splash = '/';
  static const chat = '/1';
  static const home = '/2';
  static const search = '/3';
}
