import 'package:drawable_text/drawable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(
                child: DrawableText(
                  text: 'المحادثات',
                  color: Colors.white,
                  size: 16.0.sp,
                ),
              ),
              Tab(
                child: DrawableText(
                  text: 'الدعم',
                  color: Colors.white,
                  size: 16.0.sp,
                ),
              ),
              Tab(
                child: DrawableText(
                  text: 'المستخدمين',
                  color: Colors.white,
                  size: 16.0.sp,
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Icon(Icons.directions_car),
            Icon(Icons.directions_transit),
            Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }
}
