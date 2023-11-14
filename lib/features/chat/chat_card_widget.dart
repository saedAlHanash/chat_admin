import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_multi_type/image_multi_type.dart';
import 'package:image_multi_type/round_image_widget.dart';

class ChatCardWidget extends StatelessWidget {
  final Room room;

  const ChatCardWidget({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: isMe(room) ? AppColorManager.mainColorDark : AppColorManager.ampere),
            ),
            alignment: Alignment.center,
            child: RoundImageWidget(
              url: isMe(room) ? Icons.person : Icons.group,
              color: isMe(room) ? Colors.blue : AppColorManager.mainColor,
              height: 50.0.r,
              width: 50.0.r,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawableText(
                size: 12.0.sp,
                text: room.users.first.lastName.toString(),
                drawableStart: ImageMultiType(
                  url: Icons.person,
                  color: Colors.black,
                  height: 20.0.r,
                  width: 20.0.r,
                ),
              ),
              if (!isMe(room))
                DrawableText(
                  size: 12.0.sp,
                  text: room.users.last.lastName.toString(),
                  drawableStart: ImageMultiType(
                    url: Icons.person,
                    color: AppColorManager.mainColor,
                    height: 20.0.r,
                    width: 20.0.r,
                  ),
                ),
              const Divider(),
              DrawableText(
                  color: Colors.grey,
                  size: 10.0.sp,
                  text: DateTime.fromMillisecondsSinceEpoch(
                          room.updatedAt ?? DateTime.now().millisecond)
                      .formatDuration())
            ],
          ),
        ],
      ),
    );
  }
}
