import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:fitness_admin_chat/core/api_manager/api_url.dart';
import 'package:fitness_admin_chat/features/chat/userss_bloc/users_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_manager/api_service.dart';
import '../../core/error/error_manager.dart';
import '../../main.dart';

import '../files_service/file_upload_service.dart';

class ChatServiceCore {
  static Future<void> initFirebaseChat() async {
    final mode = isTestMode ? 'test' : 'live';
    FirebaseChatCore.instance.initialize(
      ChatConfig(
        firestore: FirebaseFirestore.instance,
        currentUserId: () => '0',
        isTestMode: isTestMode,
        directRoomsSeedAssetPath: 'assets/seed/$mode/direct_rooms_seed.json',
        groupRoomsSeedAssetPath: 'assets/seed/$mode/group_rooms_seed.json',
        usersSeedAssetPath: 'assets/seed/$mode/users_seed.json',
        uploadDelegate: (filePath, {mimeType, customArgs}) async {
          return await FileUploadService.upload(filePath, mimeType: mimeType, customArgs: customArgs);
        },
      ),
    );

    await loginChatUser();
  }

  static Future<bool> loginChatUser() async {
    try {
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          id: '0',
          firstName: 'Fitness Support',
          imageUrl:
              'https://firebasestorage.googleapis.com/v0/b/fitness-strom-1.appspot.com/o/fitness_files%2Fic_launcher-playstore.png?alt=media&token=424968a5-35fb-4060-a39d-5fbd1cb41d99',
          lastName: '',
          role: types.Role.admin,
          metadata: kIsWeb ? null : {'fcm': await getFireToken()},
        ),
      );
      return true;
    } catch (e) {
      loggerObject.e('loginChatUser $e');
      return false;
    }
  }

  static Future<types.User?> getUser(String userId) async {
    final user = await (ctx!.read<UsersCubit>()).fetchUser(userId);
    if (user == null || user.id == '-1') return null;
    return user;
  }

  static Future<bool> latestSeenRoom(types.Room? room) async {
    if (room == null) return false;
    try {
      await FirebaseChatCore.instance.latestSeenRoom(room);
      return true;
    } catch (e) {
      loggerObject.e('latestSeenRoom $e');
      return false;
    }
  }
}
