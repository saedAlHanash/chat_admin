import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/my_text_form_widget.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_multi_type/circle_image_widget.dart';
import 'package:image_multi_type/image_multi_type.dart';

import '../services/chat_service/chat_service_core.dart';
import 'chat/messages_bloc/messages_cubit.dart';
import 'chat/open_room_cubit/open_room_cubit.dart';
import 'chat/rooms_bloc/rooms_cubit.dart';
import 'chat/userss_bloc/users_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ///Timer to delay request search
  Timer? _debounce;

  ///search in DB and render list widget
  void searchFun(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      context.read<UsersCubit>().search(q: val);
      context.read<RoomsCubit>().search(q: val);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OpenRoomCubit, OpenRoomInitial>(
      listenWhen: (p, c) => c.statuses.done,
      listener: (context, state) async {
        await context.read<MessagesCubit>().state.stream?.cancel();
        if (!context.mounted) return;
        Navigator.pushNamed(context, RouteName.chat, arguments: state.result)
            .then((value) => ChatServiceCore.latestSeenRoom(state.result?.id));
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Container(
              margin: const EdgeInsets.only(top: 7.0),
              child: MyEditTextWidget(
                onChanged: searchFun,
                hint: 'Search',
                backgroundColor: AppColorManager.mainColorDark,
                icon: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: ImageMultiType(
                    url: Icons.search,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
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
                  child: BlocBuilder<RoomsCubit, RoomsInitial>(
                    builder: (context, state) {
                      return DrawableText(
                        text: 'الدعم',
                        color: Colors.white,
                        size: 16.0.sp,
                        drawablePadding: 5.0.w,
                        drawableStart: state.notRead
                            ? ImageMultiType(
                                url: Icons.circle,
                                height: 10.0.r,
                                width: 10.0.r,
                                color: Colors.red,
                              )
                            : null,
                      );
                    },
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
              BlocBuilder<RoomsCubit, RoomsInitial>(
                builder: (context, state) {
                  return ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, i) {
                      return Divider(color: Colors.grey[100]);
                    },
                    itemCount: state.othersRooms.length,
                    itemBuilder: (context, index) {
                      final room = state.othersRooms[index];
                      return ListTile(
                        onTap: () async {
                          context.read<OpenRoomCubit>().openRoomByRoom(room);
                        },
                        leading: SizedBox(
                          width: 40.0.w,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                child: CircleImageWidget(
                                  url: room.users.firstOrNull?.imageUrl,
                                  size: 35.0.r,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: CircleImageWidget(
                                  url: room.users.lastOrNull?.imageUrl,
                                  size: 35.0.r,
                                ),
                              )
                            ],
                          ),
                        ),
                        title: Column(
                          children: [
                            DrawableText(
                              text: room.users.firstOrNull?.name ?? '',
                              maxLines: 1,
                              matchParent: true,
                              drawablePadding: 5.0.w,
                              drawableStart: ImageMultiType(
                                url: Icons.person,
                                height: 17.0.r,
                                width: 17.0.r,
                                color: AppColorManager.mainColor,
                              ),
                            ),
                            DrawableText(
                              text: room.users.lastOrNull?.name ?? '',
                              maxLines: 1,
                              matchParent: true,
                              drawablePadding: 5.0.w,
                              drawableStart: ImageMultiType(
                                url: Icons.person,
                                color: AppColorManager.mainColor,
                                height: 17.0.r,
                                width: 17.0.r,
                              ),
                            ),
                          ],
                        ),
                        subtitle:
                            room.lastMessages?.firstOrNull?.latestMessage(room),
                        trailing: room.updatedAt == null
                            ? null
                            : DrawableText(
                                textAlign: TextAlign.center,
                                size: 12.0.sp,
                                color: Colors.grey,
                                text: DateTime.fromMillisecondsSinceEpoch(
                                        room.updatedAt!)
                                    .formatDateTimeVertical,
                              ),
                      );
                    },
                  );
                },
              ),
              BlocBuilder<RoomsCubit, RoomsInitial>(
                builder: (context, state) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.myRooms.length,
                    separatorBuilder: (context, i) {
                      return Divider(
                        color: Colors.grey[100],
                      );
                    },
                    itemBuilder: (_, i) {
                      final room = state.myRooms[i];

                      return ListTile(
                        onTap: () async {
                          context.read<OpenRoomCubit>().openRoomByRoom(room);
                        },
                        leading: CircleImageWidget(
                          url: room.otherUser.imageUrl,
                          size: 40.0.r,
                        ),
                        title: DrawableText(
                          text: room.otherUser.name,
                          maxLines: 1,
                          matchParent: true,
                          drawablePadding: 5.0.w,
                          drawableStart: ImageMultiType(
                            url: Icons.person,
                            height: 17.0.r,
                            width: 17.0.r,
                            color: AppColorManager.mainColor,
                          ),
                        ),
                        subtitle:
                            room.lastMessages?.firstOrNull?.latestMessage(room),
                        trailing: room.updatedAt == null
                            ? null
                            : DrawableText(
                                textAlign: TextAlign.center,
                                size: 12.0.sp,
                                color: Colors.grey,
                                text: DateTime.fromMillisecondsSinceEpoch(
                                        room.updatedAt!)
                                    .formatDateTimeVertical,
                              ),
                      );
                    },
                  );
                },
              ),
              BlocBuilder<UsersCubit, UsersInitial>(
                builder: (context, state) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.result.length,
                    separatorBuilder: (context, i) {
                      return Divider(
                        color: Colors.grey[100],
                      );
                    },
                    itemBuilder: (_, i) {
                      final user = state.result[i];

                      return ListTile(
                        onTap: () async {
                          context
                              .read<OpenRoomCubit>()
                              .openRoomByUserId(user.id);
                        },
                        leading: CircleImageWidget(
                          url: user.imageUrl,
                          size: 40.0.r,
                        ),
                        title: DrawableText(
                          text: user.firstName ?? '',
                          maxLines: 1,
                          matchParent: true,
                          drawablePadding: 5.0.w,
                          drawableStart: ImageMultiType(
                            url: Icons.person,
                            height: 17.0.r,
                            width: 17.0.r,
                            color: AppColorManager.mainColor,
                          ),
                        ),
                        trailing: const ImageMultiType(
                          url: Icons.arrow_forward_ios,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
