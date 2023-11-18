import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/features/chat/users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';

import '../../core/api_manager/api_service.dart';
import '../../core/util/my_style.dart';
import '../../main.dart';
import '../../router/app_router.dart';
import '../chat/chat.dart';
import '../chat/chat_card_widget.dart';
import '../chat/util.dart';
import 'get_chats_rooms_bloc/get_rooms_cubit.dart';

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
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteName.search);
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            BlocBuilder<GetRoomsCubit, GetRoomsInitial>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: Colors.white,
                  onRefresh: () async {
                    // context.read<GetRoomsCubit>().getChatRooms();
                  },
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, i) {
                      return Divider(
                        color: Colors.grey[100],
                      );
                    },
                    itemCount: state.otherRooms.length,
                    itemBuilder: (context, index) {
                      final openRoom = state.otherRooms[index];

                      return ChatCardWidget(
                        room: openRoom,
                      );
                    },
                  ),
                );
              },
            ),
            BlocBuilder<GetRoomsCubit, GetRoomsInitial>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: Colors.white,
                  onRefresh: () async {
                    // context.read<GetRoomsCubit>().getChatRooms();
                  },
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.myRooms.length,
                    separatorBuilder: (context, i) {
                      return Divider(
                        color: Colors.grey[100],
                      );
                    },
                    itemBuilder: (_, i) {
                      final openRoom = state.myRooms[i];

                      return ChatCardWidget(
                        room: openRoom,
                      );
                    },
                  ),
                );
              },
            ),
            const UsersPage(),
          ],
        ),
      ),
    );
  }
}
