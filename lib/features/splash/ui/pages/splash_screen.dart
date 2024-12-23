import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../router/app_router.dart';
import '../../../chat/userss_bloc/users_bloc.dart';

bool canRecording = false;

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersCubit, UsersInitial>(
      listenWhen: (p, c) => c.statuses.done,
      listener: (context, state) {
        Navigator.pushReplacementNamed(context, RouteName.home);
      },
      child: Scaffold(
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
      ),
    );
  }
}
