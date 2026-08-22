import 'package:chat_lib/chat_lib.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/generated/assets.dart';
import 'package:fitness_admin_chat/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SyncScreenPage extends StatefulWidget {
  const SyncScreenPage({super.key});

  @override
  State<SyncScreenPage> createState() => _SyncScreenPageState();
}

class _SyncScreenPageState extends State<SyncScreenPage> {
  String _status = 'جاري تحضير البيانات...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      await FirebaseChatCore.instance.syncSeedData(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _status = step;
              _progress = progress;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteName.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'حدث خطأ في المزامنة: $e';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, RouteName.home);
          }
        });
      }
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
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Assets.images.whiteLogo.path,
                  width: 140.w,
                  height: 140.w,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8.h,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
