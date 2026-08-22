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
import 'package:flutter/services.dart';
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

  void _handleMessageLongPress(BuildContext context, types.Message message) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                if (message is types.TextMessage) ...[
                  ListTile(
                    leading: const Icon(Icons.copy_rounded, color: AppColorManager.mainColor),
                    title: DrawableText(
                      text: 'نسخ النص',
                      fontWeight: FontWeight.w600,
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      Clipboard.setData(ClipboardData(text: message.text));
                      NoteMessage.showSuccessSnackBar(
                        context: context,
                        message: 'تم نسخ النص',
                      );
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppColorManager.red),
                  title: DrawableText(
                    text: 'حذف الرسالة',
                    color: AppColorManager.red,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.read<MessagesCubit>().deleteMessage(message.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
            showUserAvatars: true,
            showUserNames: true,
            avatarBuilder: (user) {
              final avatarUrl = user.imageUrl ?? '';
              return Padding(
                padding: EdgeInsetsDirectional.only(end: 8.w),
                child: CircleImageWidget(
                  url: avatarUrl.isBlank ? Assets.images.avatar.path : avatarUrl,
                  size: 24.0.r,
                ),
              );
            },
            imageMessageBuilder: (imageMessage, {required messageWidth}) {
              final me = isSpectator
                  ? imageMessage.author.id == widget.room.users.firstOrNull?.id
                  : imageMessage.author.id == '0';
              final timeText = DateTime.fromMillisecondsSinceEpoch(imageMessage.createdAt ?? 0).fixTimeZone.formatTime;
              final radius = BorderRadius.only(
                topLeft: Radius.circular(16.0.r),
                topRight: Radius.circular(16.0.r),
                bottomLeft: Radius.circular(me ? 16.0.r : 4.0.r),
                bottomRight: Radius.circular(me ? 4.0.r : 16.0.r),
              );

              return Container(
                constraints: BoxConstraints(
                  maxWidth: 260.w,
                  maxHeight: 320.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ImageMultiType(
                        url: imageMessage.uri,
                        fit: BoxFit.cover,
                        width: 260.w,
                        height: 280.h,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: DrawableText(
                                  size: 9.5.sp,
                                  text: timeText,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            bubbleBuilder: (child, {required message, required nextMessageInGroup}) {
              final isImage = message.type == types.MessageType.image;
              if (isImage) {
                return child;
              }

              final me = isSpectator
                  ? message.author.id == widget.room.users.firstOrNull?.id
                  : message.author.id == '0';

              final radius = BorderRadius.only(
                topLeft: Radius.circular(16.0.r),
                topRight: Radius.circular(16.0.r),
                bottomLeft: Radius.circular(me ? 16.0.r : 4.0.r),
                bottomRight: Radius.circular(me ? 4.0.r : 16.0.r),
              );
              final timeText = DateTime.fromMillisecondsSinceEpoch(message.createdAt ?? 0).fixTimeZone.formatTime;

              return Container(
                decoration: BoxDecoration(
                  color: me ? AppColorManager.mainColor : Colors.white,
                  borderRadius: radius,
                  border: me
                      ? null
                      : Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: me
                          ? AppColorManager.mainColor.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: 14.h,
                        start: me ? 2.w : 5.w,
                        end: me ? 5.w : 2.w,
                      ),
                      child: child,
                    ),
                    Positioned(
                      bottom: 5.h,
                      right: me ? 10.w : null,
                      left: me ? null : 10.w,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.metadata?['isEdited'] == true) ...[
                            DrawableText(
                              size: 8.5.sp,
                              text: '(معدلة) ',
                              color: me
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                          DrawableText(
                            size: 9.5.sp,
                            text: timeText,
                            color: me
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            customDateHeaderText: (p0) {
              return p0.year == DateTime.now().year
                  ? p0.fixTimeZone.formatDateMonthName
                  : '(${p0.year}) ${p0.fixTimeZone.formatDateMonthName}';
            },
            onAttachmentPressed: _handleAtachmentPressed,
            onMessageTap: _handleMessageTap,
            onMessageLongPress: _handleMessageLongPress,
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
            theme: DefaultChatTheme(
              backgroundColor: const Color(0xFFF4F6F8),
              primaryColor: AppColorManager.mainColor,
              secondaryColor: Colors.white,
              messageBorderRadius: 18,
              messageInsetsHorizontal: 14,
              messageInsetsVertical: 9,
              messageMaxWidth: 300,
              userAvatarImageBackgroundColor: const Color(0xFFECEFF1),
              userNameTextStyle: TextStyle(
                fontSize: 12.0.sp,
                fontWeight: FontWeight.w700,
                color: AppColorManager.mainColor,
                height: 1.3,
              ),
              dateDividerMargin: const EdgeInsets.symmetric(vertical: 14),
              dateDividerTextStyle: TextStyle(
                color: const Color(0xFF8A94A6),
                fontSize: 11.0.sp,
                fontWeight: FontWeight.w600,
              ),
              sentMessageBodyTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 14.0.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
              receivedMessageBodyTextStyle: TextStyle(
                color: const Color(0xFF1E293B),
                fontSize: 14.0.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
              inputBackgroundColor: Colors.white,
              inputMargin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              inputPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              inputTextCursorColor: AppColorManager.mainColor,
              inputTextColor: const Color(0xFF1E293B),
              inputTextStyle: TextStyle(
                color: const Color(0xFF1E293B),
                fontSize: 14.0.sp,
                height: 1.4,
              ),
              inputTextDecoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13.5.sp,
                ),
                fillColor: const Color(0xFFF1F5F9),
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0.r),
                  borderSide: BorderSide.none,
                ),
              ),
              sendButtonIcon: Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20.r,
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
