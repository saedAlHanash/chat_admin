import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitness_admin_chat/core/strings/enum_manager.dart';


import '../core/injection/injection_container.dart' as di;
import '../features/chat/chat_screen.dart';
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

      case RouteName.chatScreen:
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
  static const chatScreen = '/1';
  static const home = '/2';
  static const forgetPassword = '/3';
  static const resetPasswordPage = '/4';
  static const login = '/5';
  static const signup = '/6';
  static const confirmCode = '/7';

  static const product = '/9';
  static const profile = '/10';
  static const searchResult = '/11';
  static const update = '/12';
  static const updateChoice = '/13';
  static const notifications = '/14';
  static const offers = '/15';
  static const bestSeller = '/16';
  static const myOrders = '/17';
  static const about = '/18';
  static const privacy = '/19';
  static const category = '/20';
}
