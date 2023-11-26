import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:image_multi_type/image_multi_type.dart';
import 'package:image_multi_type/round_image_widget.dart';

import '../../main.dart';
import '../../router/app_router.dart';
import '../main/get_chats_rooms_bloc/get_rooms_cubit.dart';

class ChatCardWidget extends StatefulWidget {
  final Room room;

  const ChatCardWidget({
    super.key,
    required this.room,
  });

  @override
  State<ChatCardWidget> createState() => _ChatCardWidgetState();
}

class _ChatCardWidgetState extends State<ChatCardWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openRoom(context);
        // Get.toNamed(AppRoutes.conversationScreen,
        //   arguments: [chatainer!.name!, chat.channelId]);
      },
      child: Container(
        height: 1.0.sh / 9,
        width: 1.0.sw,
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 1.0.sh / 162.4),
        child: Row(
          children: [
            Container(
              width: 1.0.sw / 6,
              height: 1.0.sw / 6,
              margin: EdgeInsets.only(left: 1.0.sw / 12.5, right: 1.0.sw / 18.75),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    width: 2,
                    color: isMe(widget.room)
                        ? AppColorManager.mainColorDark
                        : AppColorManager.ampere),
              ),
              alignment: Alignment.center,
              child: RoundImageWidget(
                url: isMe(widget.room) ? Icons.person : Icons.group,
                color: isMe(widget.room) ? Colors.blue : AppColorManager.mainColor,
                height: 50.0.r,
                width: 50.0.r,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMe(widget.room))
                  DrawableText(
                    size: 12.0.sp,
                    text: (widget.room.users.first.id == firebaseUser?.uid)
                        ? widget.room.users.last.lastName.toString()
                        : widget.room.users.first.lastName.toString(),
                    drawableStart: ImageMultiType(
                      url: Icons.person,
                      color: Colors.black,
                      height: 20.0.r,
                      width: 20.0.r,
                    ),
                  )
                else ...[
                  DrawableText(
                    size: 12.0.sp,
                    text: widget.room.users.first.lastName.toString(),
                    drawableStart: ImageMultiType(
                      url: Icons.person,
                      color: Colors.black,
                      height: 20.0.r,
                      width: 20.0.r,
                    ),
                  ),
                  DrawableText(
                    size: 12.0.sp,
                    text: widget.room.users.last.lastName.toString(),
                    drawableStart: ImageMultiType(
                      url: Icons.person,
                      color: AppColorManager.mainColor,
                      height: 20.0.r,
                      width: 20.0.r,
                    ),
                  ),
                ],
                const Divider(),
                DrawableText(
                  color: Colors.grey,
                  size: 10.0.sp,
                  text: DateTime.fromMillisecondsSinceEpoch(
                          widget.room.updatedAt ?? DateTime.now().millisecond)
                      .formatDuration(),
                )
              ],
            ),
            if (widget.room.isNotReed) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0).w,
                child: const Icon(
                  Icons.circle,
                  color: AppColorManager.mainColorDark,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> openRoom(BuildContext context) async {
    roomMessage = await Hive.openBox<String>(widget.room.id);
    if (context.mounted) {
      context.read<GetRoomsCubit>().state.stream?.pause();
      Navigator.pushNamed(context, RouteName.chat, arguments: widget.room).then((value) {
        roomMessage.close();
        context.read<GetRoomsCubit>().state.stream?.resume();

        setState(() {});
      });
    }
  }
}
