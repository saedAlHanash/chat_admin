import 'package:chat_lib/chat_lib.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../router/app_router.dart';

bool canRecording = false;

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final isEmpty = await FirebaseChatCore.instance.isCacheEmpty();
    if (!mounted) return;

    if (isEmpty) {
      Navigator.pushReplacementNamed(context, RouteName.sync);
    } else {
      Navigator.pushReplacementNamed(context, RouteName.home);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              AppColorManager.secondColor,
            ],
          ),
        ),
        child: GestureDetector(
          onDoubleTap: () {
            canRecording = true;
          },
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(1.0.sw / 7),
              child: Image.asset(
                Assets.images.whiteLogo.path,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
