import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drawable_text/drawable_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/util/shared_preferences.dart';
import 'package:fitness_admin_chat/core/util/shared_preferences.dart';
import 'package:fitness_admin_chat/features/chat/room_messages_bloc/room_messages_cubit.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/injection/injection_container.dart';
import '../../core/util/my_style.dart';
import '../../main.dart';
import 'my_room_object.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.room,
    required this.name,
  });

  final types.Room room;
  final String name;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // late final
  List<types.Message>? initialMessage;

  @override
  void initState() {
    myRoomObject = MyRoomObject(
      roomId: widget.room.id,
      fcmToken: (getChatMember(widget.room.users).metadata ?? {})['fcm'] ?? '',
    );

    super.initState();
  }

  bool _isAttachmentUploading = false;

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      _setAttachmentUploading(true);
      final file = File(result.path);
      final size = file.lengthSync();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final name = result.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(
          message,
          widget.room.id,
        );
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final updatedMessage = message.copyWith(isLoading: true);
          FirebaseChatCore.instance.updateMessage(
            updatedMessage,
            widget.room.id,
          );

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final updatedMessage = message.copyWith(isLoading: false);
          FirebaseChatCore.instance.updateMessage(
            updatedMessage,
            widget.room.id,
          );
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  void _handleSendPressed(types.PartialText message) {
    sendNotificationMessage(
        myRoomObject,
        ChatNotification(
          title: getChatMember(widget.room.users, me: true).lastName ?? '',
          body: message.text,
        ));

    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
    );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RoomMessagesCubit>()..getChatRoomMessage(widget.room),
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: isMe(widget.room)
              ? Text(widget.name)
              : Row(
                  children: [
                    DrawableText(
                      size: 14.0.sp,
                      text: widget.room.users.first.lastName.toString(),
                      color: Colors.white,
                    ),
                    const Text(' | '),
                    DrawableText(
                      size: 14.0.sp,
                      text: widget.room.users.last.lastName.toString(),
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
        body: BlocBuilder<RoomMessagesCubit, RoomMessagesInitial>(
          builder: (context, state) {
            return Chat(
              isAttachmentUploading: _isAttachmentUploading,
              messages: state.allMessages,
              onAttachmentPressed: _handleAtachmentPressed,
              onMessageTap: _handleMessageTap,
              onPreviewDataFetched: _handlePreviewDataFetched,
              onSendPressed: _handleSendPressed,
              theme: const DarkChatTheme(),
              customBottomWidget: isMe(widget.room) ? null : const SizedBox(),
              user: types.User(
                id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
              ),
            );
          },
        ),
      ),
    );
  }
}

// /// Returns a stream of messages from Firebase for a given room.
// Stream<List<types.Message>> messages(
//   types.Room room, {
//   List<Object?>? endAt,
//   List<Object?>? endBefore,
//   int? limit,
//   List<Object?>? startAfter,
//   List<Object?>? startAt,
// }) {
//   final initialMessage = roomMessage.values
//       .map((e) => types.Message.fromJson(jsonDecode(e)))
//       .toList()
//     ..sort((a, b) => (a.updatedAt ?? 0).compareTo(b.updatedAt ?? 0));
//
//   var query = FirebaseFirestore.instance
//       .collection('rooms/${room.id}/messages')
//       .orderBy('createdAt', descending: true)
//       .where(
//         'createdAt',
//         isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
//           initialMessage.firstOrNull?.createdAt ?? 0,
//         ),
//       );
//
//   if (endAt != null) {
//     query = query.endAt(endAt);
//   }
//
//   if (endBefore != null) {
//     query = query.endBefore(endBefore);
//   }
//
//   if (limit != null) {
//     query = query.limit(limit);
//   }
//
//   if (startAfter != null) {
//     query = query.startAfter(startAfter);
//   }
//
//   if (startAt != null) {
//     query = query.startAt(startAt);
//   }
//
//   // final result1 = query.snapshots().listen((event) {
//   //   loggerObject.w(event);
//   // });
//   //
//   query.get().then((event) {
//     loggerObject.w(event);
//   });
//
//   final result = query.snapshots().map(
//     (snapshot) {
//       return snapshot.docs.fold<List<types.Message>>(
//         initialMessage,
//         (previousValue, doc) {
//           final data = doc.data();
//           final author = room.users.firstWhere(
//             (u) => u.id == data['authorId'],
//             orElse: () => types.User(id: data['authorId'] as String),
//           );
//
//           data['author'] = author.toJson();
//           data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
//           data['id'] = doc.id;
//           data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;
//
//           roomMessage.put(doc.id, jsonEncode(data));
//
//           return [...previousValue, types.Message.fromJson(data)];
//         },
//       );
//     },
//   );
//   return result;
// }
