import 'dart:async';

import 'package:chat_lib/chat_lib.dart';
import 'package:collection/collection.dart';
import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/my_text_form_widget.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_multi_type/image_multi_type.dart';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_manager/api_url.dart';
import '../core/util/my_style.dart';
import '../generated/assets.dart';
import 'chat/group_session_bloc/group_session_rooms_cubit.dart';
import 'chat/messages_bloc/messages_cubit.dart';
import 'chat/open_room_cubit/open_room_cubit.dart';
import 'chat/rooms_bloc/rooms_cubit.dart';
import 'chat/ui/widgets/chat_timestamp_widget.dart';
import 'chat/userss_bloc/users_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  ///Timer to delay request search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersCubit>().getChatUsers();
      context.read<RoomsCubit>().getChatRooms();
      context.read<GroupSessionRoomsCubit>().getGroupRooms();
    });
  }

  ///search in DB and render list widget
  void searchFun(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      context.read<UsersCubit>().search(q: val);
      context.read<RoomsCubit>().search(q: val);
      context.read<GroupSessionRoomsCubit>().search(q: val);
    });
  }

  Future<void> _exportCache() async {
    try {
      final mode = isTestMode ? 'test' : 'live';
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = '${dir.path}/$mode';
      final exportedFiles = await FirebaseChatCore.instance.exportAllSeedFiles(targetDir, pretty: true);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تم تصدير الكاش بنجاح ($mode)'),
          content: SelectableText(
            'تم حفظ 3 ملفات في المجلد:\n$targetDir\n\n'
            '1. direct_rooms_seed.json\n'
            '2. group_rooms_seed.json\n'
            '3. users_seed.json',
          ),
          actions: [
            TextButton(
              onPressed: () {
                OpenFilex.open(exportedFiles['directRooms'] ?? dir.path);
              },
              child: const Text('فتح الملف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OpenRoomCubit, OpenRoomInitial>(
      listenWhen: (p, c) => c.done,
      listener: (context, state) async {
        await context.read<MessagesCubit>().state.stream?.cancel();
        if (!context.mounted) return;
        Navigator.pushNamed(context, RouteName.chat, arguments: state.result).then((value) async {
          if (state.result != null) {
            final updatedRoom = await FirebaseChatCore.instance.latestSeenRoom(state.result!);
            if (context.mounted) {
              if (updatedRoom.isGroup) {
                context.read<GroupSessionRoomsCubit>().updateRoom(updatedRoom);
              } else {
                context.read<RoomsCubit>().updateRoom(updatedRoom);
              }
            }
          }
        });
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            //     tooltip: 'تصدير الكاش (Seed Data)',
            //     onPressed: _exportCache,
            //   ),
            // ],
            title: Container(
              margin: const EdgeInsets.only(top: 7.0),
              child: MyEditTextWidget(
                onChanged: searchFun,
                hint: 'Search',
                backgroundColor: AppColorManager.mainColor,
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
              isScrollable: true,
              tabAlignment: TabAlignment.center,
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
                    text: 'المجموعات',
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
              // 1. Others' Direct Conversations (Monitored)
              BlocBuilder<RoomsCubit, RoomsInitial>(
                builder: (context, state) {
                  loggerObject.w(state.result.length);
                  if (state.loading) {
                    return MyStyle.loadingWidget();
                  }
                  if (state.othersRooms.isEmpty) {
                    return Center(
                      child: DrawableText(
                        text: 'لا توجد محادثات',
                        color: Colors.grey,
                        size: 16.0.sp,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(20.0).r,
                    shrinkWrap: true,
                    separatorBuilder: (context, i) {
                      return Divider(color: Colors.grey[100]);
                    },
                    itemCount: state.othersRooms.length,
                    itemBuilder: (context, index) {
                      final room = state.othersRooms[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
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
                                  url: (room.users.firstOrNull?.imageUrl.isBlank ?? true)
                                      ? Assets.images.avatar.path
                                      : room.users.firstOrNull?.imageUrl,
                                  size: 35.0.r,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: CircleImageWidget(
                                  url: (room.users.lastOrNull?.imageUrl.isBlank ?? true)
                                      ? Assets.images.avatar.path
                                      : room.users.lastOrNull?.imageUrl,
                                  size: 35.0.r,
                                ),
                              ),
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
                        subtitle: room.lastMessages?.firstOrNull?.latestMessage(room),
                        trailing: room.updatedAt == null
                            ? null
                            : ChatTimestampWidget(timestamp: room.updatedAt),
                      );
                    },
                  );
                },
              ),

              // 2. Support Chats (With Admin '0')
              BlocBuilder<RoomsCubit, RoomsInitial>(
                builder: (context, state) {
                  if (state.loading) {
                    return MyStyle.loadingWidget();
                  }
                  if (state.myRooms.isEmpty) {
                    return Center(
                      child: DrawableText(
                        text: 'لا توجد محادثات دعم',
                        color: Colors.grey,
                        size: 16.0.sp,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(20.0).r,
                    shrinkWrap: true,
                    itemCount: state.myRooms.length,
                    separatorBuilder: (context, i) {
                      return 10.0.verticalSpace;
                    },
                    itemBuilder: (_, i) {
                      final room = state.myRooms[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                        tileColor: room.isRead
                            ? AppColorManager.lightGray
                            : AppColorManager.threadColor.withValues(alpha: 0.1),
                        onTap: () async {
                          context.read<OpenRoomCubit>().openRoomByRoom(room);
                        },
                        leading: CircleImageWidget(
                          url: (room.otherUser.imageUrl.isBlank) ? Assets.images.avatar.path : room.otherUser.imageUrl,
                          size: 40.0.r,
                        ),
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DrawableText(
                              text: room.otherUser.name,
                              maxLines: 1,
                              matchParent: true,
                            ),
                            3.0.verticalSpace,
                            DrawableText(
                              text: room.otherUser.email,
                              size: 10.0,
                              matchParent: true,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        subtitle: room.lastMessages?.firstOrNull?.latestMessage(room),
                        trailing: ChatTimestampWidget(timestamp: room.updatedAt),
                      );
                    },
                  );
                },
              ),

              // 3. Group Session Chats
              BlocBuilder<GroupSessionRoomsCubit, GroupSessionRoomsInitial>(
                builder: (context, state) {
                  if (state.loading) {
                    return MyStyle.loadingWidget();
                  }
                  if (state.result.isEmpty) {
                    return Center(
                      child: DrawableText(
                        text: 'لا توجد مجموعات جماعية',
                        color: Colors.grey,
                        size: 16.0.sp,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(20.0).r,
                    shrinkWrap: true,
                    separatorBuilder: (context, i) => Divider(color: Colors.grey[100]),
                    itemCount: state.result.length,
                    itemBuilder: (context, index) {
                      final room = state.result[index];
                      final trainerName = room.name?.isNotEmpty == true ? room.name! : 'مجموعة المدرب #${room.id}';
                      final imageUrl = room.imageUrl;
                      final memberCount = room.users.length;

                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                        onTap: () async {
                          context.read<OpenRoomCubit>().openRoomByRoom(room);
                        },
                        leading: CircleImageWidget(
                          url: (imageUrl.isBlank) ? Assets.images.avatar.path : imageUrl,
                          size: 40.0.r,
                        ),
                        title: DrawableText(
                          text: trainerName,
                          maxLines: 1,
                          fontWeight: FontWeight.bold,
                          size: 14.0.sp,
                        ),
                        subtitle: room.lastMessages?.firstOrNull?.latestMessage(room),
                        trailing: room.updatedAt == null
                            ? null
                            : Column(
                                spacing: 7.0,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 2.0.h),
                                    decoration: BoxDecoration(
                                      color: AppColorManager.mainColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.0.r),
                                    ),
                                    child: DrawableText(
                                      text: '$memberCount عضو',
                                      size: 11.0.sp,
                                      color: AppColorManager.mainColor,
                                      drawableStart: ImageMultiType(
                                        url: Icons.group,
                                        height: 14.0.r,
                                        width: 14.0.r,
                                        color: AppColorManager.mainColor,
                                      ),
                                      drawablePadding: 4.0.w,
                                    ),
                                  ),
                                  ChatTimestampWidget(timestamp: room.updatedAt),
                                ],
                              ),
                      );
                    },
                  );
                },
              ),

              // 4. Users List
              BlocBuilder<UsersCubit, UsersInitial>(
                builder: (context, state) {
                  if (state.loading) {
                    return MyStyle.loadingWidget();
                  }
                  if (state.result.isEmpty) {
                    return Center(
                      child: DrawableText(
                        text: 'لا يوجد مستخدمين',
                        color: Colors.grey,
                        size: 16.0.sp,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(20.0).r,
                    shrinkWrap: true,
                    itemCount: state.result.length,
                    separatorBuilder: (context, i) {
                      return Divider(
                        color: Colors.grey[100],
                      );
                    },
                    itemBuilder: (_, i) {
                      final user = state.result[i];
                      if (user.id == '0') return 0.0.verticalSpace;
                      return ListTile(
                        onTap: () async {
                          context.read<OpenRoomCubit>().openRoomByUserId(user.id);
                        },
                        leading: CircleImageWidget(
                          url: (user.imageUrl.isBlank) ? Assets.images.avatar.path : user.imageUrl,
                          size: 40.0.r,
                        ),
                        title: DrawableText(
                          text: user.name,
                          maxLines: 1,
                          matchParent: true,
                          drawablePadding: 5.0.w,
                        ),
                        subtitle: DrawableText(
                          text: user.email,
                          matchParent: true,
                          drawablePadding: 5.0.w,
                        ),
                        trailing: DrawableText(
                          text: DateTime.fromMillisecondsSinceEpoch(user.createdAt ?? 0).formatDate,
                          color: Colors.grey[400]!,
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
