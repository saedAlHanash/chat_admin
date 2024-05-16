import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/util/my_style.dart';
import 'package:fitness_admin_chat/features/main/get_chats_rooms_bloc/get_rooms_cubit.dart';
import 'package:fitness_admin_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:image_multi_type/circle_image_widget.dart';

import '../../generated/assets.dart';
import '../../router/app_router.dart';
import 'util.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  void _handlePressed(types.User otherUser, BuildContext context) async {
    final room =
        await context.read<GetRoomsCubit>().getRoomByUser(otherUser.id);
    if (context.mounted && room != null) {
      roomMessage = await Hive.openBox<String>(room.id);
      if (context.mounted) {
        context.read<GetRoomsCubit>().state.stream?.pause();
        Navigator.pushNamed(context, RouteName.chat, arguments: room)
            .then((value) {
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
            loggerObject.w(user.imageUrl);
            return ListTile(
              onTap: () {
                _handlePressed(user, context);
              },
              leading: CircleImageWidget(
                url: Assets.imagesAvatar,
                size: 50.0.r,
              ),
              title: DrawableText(
                text: getUserName(user),
                fontFamily: FontManager.cairoBold.name,
                fontWeight: FontWeight.bold,
              ),
              subtitle: DrawableText(
                text: DateTime.fromMillisecondsSinceEpoch(user.updatedAt ?? 0)
                    .formatDate,
                color: Colors.grey,
                size: 14.0.sp,
              ),
            );
          },
        );
      },
    );
  }
}
