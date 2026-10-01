import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../features/chat/chat.dart';
import '../features/main_screen.dart';
import '../features/splash/ui/pages/splash_screen.dart';
import '../features/sync/ui/pages/sync_screen.dart';

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

      case RouteName.sync:
        return MaterialPageRoute(builder: (_) => const SyncScreenPage());

      case RouteName.chat:
        //region
        {
          return MaterialPageRoute(
            builder: (context) {
              final room = settings.arguments as Room;
              return ChatPage(room: room);
            },
          );
        }

    }

    return MaterialPageRoute(
        builder: (_) => const Scaffold(backgroundColor: Colors.red));
  }
}

class RouteName {
  static const splash = '/';
  static const chat = '/1';
  static const home = '/2';
  static const sync = '/sync';
}
