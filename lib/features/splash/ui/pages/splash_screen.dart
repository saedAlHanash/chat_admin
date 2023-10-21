import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../router/app_router.dart';

bool canRecording = false;

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    Future.delayed(Duration(seconds: 2),() {
      Navigator.pushReplacementNamed(context, RouteName.chatScreen);
    },);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    ////log(controller.title);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColorManager.mainColor,
            AppColorManager.mainColorDark,
          ],
        )),
        child: GestureDetector(
          onDoubleTap: () {
            canRecording = true;
          },
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(1.0.sw / 7),
              child: Image.asset(
                Assets.imagesWhiteLogo,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
