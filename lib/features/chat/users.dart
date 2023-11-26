import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_admin_chat/core/util/my_style.dart';
import 'package:fitness_admin_chat/features/main/get_chats_rooms_bloc/get_rooms_cubit.dart';
import 'package:fitness_admin_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:image_multi_type/round_image_widget.dart';

import '../../core/strings/app_color_manager.dart';
import '../../router/app_router.dart';
import 'chat.dart';
import 'util.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  void _handlePressed(types.User otherUser, BuildContext context) async {
    final room = await context.read<GetRoomsCubit>().getRoomByUser(otherUser.id);
    if (context.mounted && room != null) {
      roomMessage = await Hive.openBox<String>(room.id);
      if (context.mounted) {
        context.read<GetRoomsCubit>().state.stream?.pause();
        Navigator.pushNamed(context, RouteName.chat, arguments: room).then((value) {
          roomMessage.close();
          context.read<GetRoomsCubit>().state.stream?.resume();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getChatUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MyStyle.loadingWidget();
        }
        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, i) {
            return Divider(
              color: Colors.grey[100],
            );
          },
          itemBuilder: (context, index) {
            final user = snapshot.data![index];

            return InkWell(
              onTap: () {
                _handlePressed(user, context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 1.0.sw / 6,
                      height: 1.0.sw / 6,
                      margin: const EdgeInsets.only(left: 10.0, right: 20.0).w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(width: 2, color: AppColorManager.ampere),
                      ),
                      alignment: Alignment.center,
                      child: RoundImageWidget(
                        url: Icons.person,
                        color: AppColorManager.mainColor,
                        height: 50.0.r,
                        width: 50.0.r,
                      ),
                    ),
                    Text(getUserName(user)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
