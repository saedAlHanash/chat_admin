import 'dart:io';

import 'package:chat_lib/chat_lib.dart';
import 'package:collection/collection.dart';
import 'package:drawable_text/drawable_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/features/chat/sound_record.dart';
import 'package:fitness_admin_chat/features/chat/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_multi_type/image_multi_type.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/helper/launcher_helper.dart';
import '../../core/strings/app_color_manager.dart';
import '../../core/util/my_style.dart';
import '../../core/util/snack_bar_message.dart';
import '../../core/widgets/app_bar/app_bar_widget.dart';
import '../../generated/assets.dart';
import 'messages_bloc/messages_cubit.dart';
import 'my_room_object.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.room});

  final types.Room room;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final MyRoomObject myRoomObject;

  bool get isGroup => widget.room.isGroup;

  @override
  void initState() {
    final otherFcm = isGroup ? '' : ((widget.room.otherUser.metadata ?? {})['fcm']?.toString() ?? '');

    myRoomObject = MyRoomObject(
      roomId: widget.room.id,
      fcmToken: otherFcm,
    );

    context.read<MessagesCubit>().getChatRoomMessage(widget.room);
    super.initState();
  }

  bool _isAttachmentUploading = false;

  void _handleFileSelection() async {
    final result = await FilePicker.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;

      try {
        final mimeType = lookupMimeType(filePath);
        final uri = await FirebaseChatCore.instance.uploadFile(
          filePath,
          mimeType: mimeType,
          customArgs: {'compress': false},
        );

        final message = types.PartialFile(
          mimeType: mimeType,
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
        final uri = await FirebaseChatCore.instance.uploadFile(
          result.path,
          mimeType: 'image/jpeg',
          customArgs: {'compress': true, 'compressionQuality': 70},
        );

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.TextMessage) {
      final url = message.text;
      if (url.startsWith('http')) {
        LauncherHelper.openPage(url);
      }
    }

    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } catch (_) {}
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handleSendPressed(types.PartialText message) {
    if (myRoomObject.needToSendNotification && myRoomObject.fcmToken.isNotEmpty) {
      sendNotificationMessage(
        myRoomObject,
        ChatNotification(body: message.text, title: 'رسالة جديدة'),
      ).then((value) {
        if (value) {
          myRoomObject.needToSendNotification = false;
        }
      });
    }

    FirebaseChatCore.instance.sendMessage(message, widget.room.id);
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawableText(
                text: 'Chose attachment type to send',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              20.0.verticalSpace,
              ListTile(
                selectedTileColor: AppColorManager.mainColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                selected: true,
                leading: ImageMultiType(url: Icons.image, color: AppColorManager.mainColor),
                title: DrawableText(
                  text: 'Select image',
                  color: AppColorManager.mainColor,
                  size: 18.0.sp,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
              ),
              10.0.verticalSpace,
              ListTile(
                selectedTileColor: AppColorManager.mainColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                selected: true,
                leading: ImageMultiType(
                  url: Icons.file_present_sharp,
                  color: AppColorManager.mainColor,
                ),
                title: DrawableText(
                  text: 'Select file',
                  color: AppColorManager.mainColor,
                  size: 18.0.sp,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
              ),
              10.0.verticalSpace,
              ListTile(
                selectedTileColor: AppColorManager.mainColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                selected: true,
                leading: ImageMultiType(url: Icons.mic, color: AppColorManager.mainColor),
                title: DrawableText(
                  text: 'Voice Message',
                  color: AppColorManager.mainColor,
                  size: 18.0.sp,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () {
                  Navigator.pop(context);
                  NoteMessage.showMyDialog(
                    context,
                    child: Container(
                      padding: EdgeInsets.all(20.0).r,
                      child: AudioRecorderWidget(
                        onSendAudio: (p0) {
                          if (p0 == null) return;
                          _handleSendAudioMessage(p0);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendAudioMessage(File audio) async {
    _setAttachmentUploading(true);
    try {
      final name = '${DateTime.now().millisecondsSinceEpoch}.aac';
      final uri = await FirebaseChatCore.instance.uploadFile(
        audio.path,
        mimeType: 'audio/aac',
      );

      final message = types.PartialAudio(
        size: audio.lengthSync(),
        uri: uri,
        duration: const Duration(seconds: 0),
        name: name,
      );

      await FirebaseChatCore.instance.sendMessage(message, widget.room.id);
      try {
        audio.delete();
      } catch (e) {
        loggerObject.e('delete audio file $e');
      }
      _setAttachmentUploading(false);
    } finally {
      _setAttachmentUploading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isGroup
        ? (widget.room.name?.isNotEmpty == true ? widget.room.name! : 'مجموعة المدرب #${widget.room.id}')
        : widget.room.otherUser.name;

    final imageUrl = isGroup ? widget.room.imageUrl : widget.room.otherUser.imageUrl;

    final isSpectator = !isGroup && !widget.room.isSupport;

    return Scaffold(
      appBar: AppBarWidget(
        actions: [
          SizedBox(
            width: .9.sw,
            child: ListTile(
              leading: CircleImageWidget(
                url: (imageUrl.isBlank) ? Assets.images.avatar.path : imageUrl,
                size: 40.0.r,
              ),
              title: DrawableText(
                text: titleText,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              subtitle: isGroup
                  ? DrawableText(
                      text: '${widget.room.users.length} أعضاء',
                      color: Colors.white70,
                      size: 11.0.sp,
                    )
                  : null,
            ),
          ),
        ],
      ),
      body: BlocBuilder<MessagesCubit, MessagesInitial>(
        builder: (context, state) {
          if (state.loading) {
            return MyStyle.loadingWidget();
          }
          return Chat(
            isAttachmentUploading: _isAttachmentUploading,
            messages: state.result,
            bubbleBuilder: (child, {required message, required nextMessageInGroup}) {
              final me = isSpectator
                  ? message.author.id == widget.room.users.firstOrNull?.id
                  : message.author.id == '0';

              final authorName = message.author.firstName ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGroup && !me && authorName.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 8.0.w, bottom: 2.0.h),
                      child: DrawableText(
                        text: authorName,
                        size: 11.0.sp,
                        color: AppColorManager.mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: me ? AppColorManager.mainColor : AppColorManager.secondColor,
                      borderRadius: BorderRadiusDirectional.only(
                        bottomStart: Radius.circular(me ? 16.0.r : 0.0.r),
                        bottomEnd: Radius.circular(!me ? 16.0.r : 0.0.r),
                        topEnd: Radius.circular(16.0.r),
                        topStart: Radius.circular(16.0.r),
                      ),
                    ),
                    child: child,
                  ),
                  3.0.verticalSpace,
                  DrawableText(
                    size: 10.0.sp,
                    text: DateTime.fromMillisecondsSinceEpoch(message.createdAt ?? 0).fixTimeZone.formatTime,
                    color: AppColorManager.grey,
                  ),
                ],
              );
            },
            customDateHeaderText: (p0) {
              return p0.year == DateTime.now().year
                  ? p0.fixTimeZone.formatDateMonthName
                  : '(${p0.year}) ${p0.fixTimeZone.formatDateMonthName}';
            },
            onAttachmentPressed: _handleAtachmentPressed,
            onMessageTap: _handleMessageTap,
            onMessageLongPress: (context, p0) {
              showShortListMenu(ctx: context, id: p0.id);
            },
            customMessageBuilder: (p0, {required messageWidth}) {
              final text = p0.metadata?['text']?.toString() ?? '';
              final start = DateTime.tryParse(p0.metadata?['start']?.toString() ?? '');
              final end = DateTime.tryParse(p0.metadata?['end']?.toString() ?? '');

              return ListTile(
                horizontalTitleGap: 10.0.w,
                title: DrawableText(
                  matchParent: true,
                  text: text,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.0).r,
                  fontWeight: FontWeight.bold,
                ),
                leading: ImageMultiType(
                  url: Icons.notifications,
                  width: 25.0.r,
                  color: AppColorManager.whit,
                ),
                subtitle: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColorManager.whit.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.0.r),
                      ),
                      padding: const EdgeInsets.all(7.0).r,
                      child: DrawableText(
                        text: 'From: ${start?.fixTimeZone.formatDateTime}',
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        size: 14.0.sp,
                        color: AppColorManager.whit,
                      ),
                    ),
                    10.0.verticalSpace,
                    Container(
                      decoration: BoxDecoration(
                        color: AppColorManager.whit.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.0.r),
                      ),
                      padding: const EdgeInsets.all(7.0).r,
                      child: DrawableText(
                        text: 'To: ${end?.fixTimeZone.formatDateTime}',
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        size: 14.0.sp,
                        color: AppColorManager.whit,
                      ),
                    ),
                  ],
                ),
              );
            },
            onSendPressed: _handleSendPressed,
            theme: DarkChatTheme(
              backgroundColor: Colors.white,
              primaryColor: AppColorManager.mainColor,
              dateDividerTextStyle: TextStyle(color: Colors.black54),
              secondaryColor: AppColorManager.secondColor,
              inputBackgroundColor: AppColorManager.mainColor,
              sentMessageBodyTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w800,
              ),
              receivedMessageBodyTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            audioMessageBuilder: (p0, {required messageWidth}) {
              return AudioMessageBuilder(audioUrl: p0.uri);
            },
            emptyState: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64.0.r,
                    color: Colors.grey[350],
                  ),
                  16.0.verticalSpace,
                  DrawableText(
                    text: 'لا توجد رسائل في هذه الغرفة حالياً',
                    color: Colors.grey,
                    size: 15.0.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            customBottomWidget: isSpectator ? const SizedBox() : null,
            user: isSpectator
                ? (widget.room.users.firstOrNull ?? const types.User(id: '0'))
                : const types.User(id: '0'),
          );
        },
      ),
    );
  }
}

void showShortListMenu({required String id, required BuildContext ctx}) {
  final RenderBox box = ctx.findRenderObject() as RenderBox;
  final localPosition = box.localToGlobal(Offset.zero);

  showMenu(
    context: ctx,
    position: RelativeRect.fromLTRB(
      localPosition.dx,
      (localPosition.dy + 50.0.h),
      localPosition.dx,
      localPosition.dy,
    ),
    items: [
      PopupMenuItem(
        value: 1,
        onTap: () {
          ctx.read<MessagesCubit>().deleteMessage(id);
        },
        child: ListTile(
          leading: const ImageMultiType(url: Icons.delete, color: AppColorManager.red),
          trailing: DrawableText(text: 'Delete', color: Colors.red),
        ),
      ),
    ],
  );
}
