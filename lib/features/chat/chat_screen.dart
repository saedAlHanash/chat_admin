import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

import 'chat.dart';
import 'chat_card_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('chat'),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StatefulBuilder(
        builder: (context, state) {
          return FutureBuilder(
            future: getChatRooms(),
            builder: (context, AsyncSnapshot<List<Room>?> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              return RefreshIndicator(
                color: Colors.white,
                onRefresh: () async {
                  state(() {});
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final openRoom = snapshot.data![index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return ChatPage(
                              room: openRoom,
                              name: getChatMember(openRoom.users).lastName ?? '',
                            );
                          },
                        ));
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
          );
        },
      ),
    );
  }
}
