import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/features/chat/room_messages_bloc/room_messages_cubit.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:image_multi_type/image_multi_type.dart';

import '../../core/injection/injection_container.dart';
import '../../core/my_text_form_widget.dart';
import '../../main.dart';
import '../../router/app_router.dart';
import '../main/get_chats_rooms_bloc/get_rooms_cubit.dart';
import 'chat.dart';
import 'chat_card_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Rooms'),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StatefulBuilder(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20).r,
                child: MyEditTextWidget(
                  onChanged: (p0) {
                    context.read<GetRoomsCubit>().search(p0);
                  },
                  icon: const ImageMultiType(url: Icons.search),
                ),
              ),
              Expanded(
                child: BlocBuilder<GetRoomsCubit, GetRoomsInitial>(
                  builder: (context, state) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.filterRooms.length,
                      itemBuilder: (context, index) {
                        final openRoom = state.filterRooms[index];

                        return GestureDetector(
                          onTap: () async {
                            roomMessage = await Hive.openBox<String>(openRoom.id);
                            if (context.mounted) {
                              context.read<GetRoomsCubit>().state.stream?.pause();
                              Navigator.pushNamed(context, RouteName.chat,
                                      arguments: openRoom)
                                  .then((value) {
                                roomMessage.close();
                                context.read<GetRoomsCubit>().state.stream?.resume();
                              });
                            }
                          },
                          child: ChatCardWidget(
                            room: openRoom,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
