import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';

import '../../core/api_manager/api_service.dart';
import '../../core/util/my_style.dart';
import '../../main.dart';
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
        ),
        body: TabBarView(
          children: [
            BlocBuilder<GetRoomsCubit, GetRoomsInitial>(
              builder: (context, state) {
                if (state.statuses.isLoading) {
                  return MyStyle.loadingWidget();
                }
                return RefreshIndicator(
                  color: Colors.white,
                  onRefresh: () async {},
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.otherRooms.length,
                    itemBuilder: (context, index) {
                      final openRoom = state.otherRooms[index];

                      return GestureDetector(
                        onTap: () async {
                          roomMessage = await Hive.openBox<String>(openRoom.id);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ChatPage(
                                  room: openRoom,
                                  name: getChatMember(openRoom.users).lastName ?? '',
                                );
                              },
                            )).then((value) {
                              roomMessage.close();
                            });
                          }
                          // Get.toNamed(AppRoutes.conversationScreen,
                          //   arguments: [chatainer!.name!, chat.channelId]);
                        },
                        child: ChatCardWidget(
                          room: openRoom,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            BlocBuilder<GetRoomsCubit, GetRoomsInitial>(
              builder: (context, state) {
                if (state.statuses.isLoading) {
                  return MyStyle.loadingWidget();
                }
                return RefreshIndicator(
                  color: Colors.white,
                  onRefresh: () async {},
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.myRooms.length,
                    itemBuilder: (_, i) {
                      final openRoom = state.myRooms[i];

                      return GestureDetector(
                        onTap: () async {
                          roomMessage = await Hive.openBox<String>(openRoom.id);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ChatPage(
                                  room: openRoom,
                                  name: getChatMember(openRoom.users).lastName ?? '',
                                );
                              },
                            )).then((value) {
                              roomMessage.close();
                            });
                          }
                        },
                        child: ChatCardWidget(
                          room: openRoom,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }
}
