import 'package:drawable_text/drawable_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_multi_type/image_multi_type.dart';

import '../../generated/assets.dart';
import '../../main.dart';
import '../../router/app_router.dart';
import '../app_theme.dart';
import '../injection/injection_container.dart';
import '../util/shared_preferences.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static Future<void> setLocale(BuildContext context, Locale newLocale) async {
    final state = context.findAncestorStateOfType<_MyAppState>();
    await state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    setImageMultiTypeErrorImage(
      const Opacity(
        opacity: 0.3,
        child: ImageMultiType(
          url: Assets.imagesLogo,
          height: 30.0,
          width: 30.0,
        ),
      ),
    );
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      String title = '';
      String body = '';

      if (notification != null) {
        title = notification.title ?? '';
        body = notification.body ?? '';
      } else {
        title = message.data['title'] ?? '';
        body = message.data['body'] ?? '';
      }

      Note.showBigTextNotification(title: title, body: body);
    });
    super.initState();
  }

  Future<void> setLocale(Locale locale) async {
    AppSharedPreference.cashLocal(locale.languageCode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: MediaQuery.of(context).size,
      // designSize: const Size(14440, 972),
      minTextAdapt: true,
      // splitScreenMode: true,
      builder: (context, child) {
        DrawableText.initial(
          initialHeightText: 1.5.sp,
          initialSize: 16.0.sp,
          selectable: false,
          initialColor: AppColorManager.black,
        );

        return MaterialApp(
          navigatorKey: sl<GlobalKey<NavigatorState>>(),
          locale: Locale(AppSharedPreference.getLocal),
          scrollBehavior: MyCustomScrollBehavior(),
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          onGenerateRoute: AppRoutes.routes,
        );
      },
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
