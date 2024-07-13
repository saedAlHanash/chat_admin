import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/features/chat/userss_bloc/users_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../core/api_manager/api_service.dart';

import '../../core/error/error_manager.dart';
import '../../core/util/shared_preferences.dart';
import '../../main.dart';
import 'core/firebase_chat_core.dart';
import 'core/util.dart';

class ChatServiceCore {
  static Future<void> initFirebaseChat() async {
    loginChatUser();
    return;
  }

  static Future<bool> loginChatUser() async {
    if (AppSharedPreference.getIsLoginToChatApp) return true;

    try {
      await FirebaseChatCore.instance.createUserInFirestore(
        types.User(
          id: '0',
          firstName: 'Fitness Support',
          imageUrl: 'https://www.seqrite.com/skin/frontend/default/seqrite_v1/images/support-img.png',
          lastName: '',
          role: types.Role.admin,
          metadata: {'fcm': await getFireToken()},
        ),
      );
      await AppSharedPreference.cashLoginToChatApp(true);
      return true;
    } catch (e) {
      loggerObject.e(e);
      return false;
    }
  }

  static Future<bool> logoutChatUser() async {
    if (!AppSharedPreference.getIsLoginToChatApp) return true;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('0')
          .update({'metadata': {}});
      await AppSharedPreference.cashLoginToChatApp(false);
      return true;
    } catch (e) {
      loggerObject.e(e);
      return false;
    }
  }

  static Future<types.User?> getUser(String userId) async {
    final user =
    (ctx!.read<UsersCubit>().state.result).firstWhereOrNull((e) => e.id == userId);
    return user;
  }

  static Future<bool> latestSeenRoom(String? roomId) async {
    if(roomId==null)return false;
    try {
      await FirebaseChatCore.instance.latestSeenRoom(roomId);
      return true;
    } catch (e) {
      loggerObject.e(e);
      return false;
    }
  }

  static Future<List<types.User>> getChatUsers() async {
      final users = await FirebaseFirestore.instance.collection('users').get();

    final listUsers = users.docs.map((doc) {
      final data = doc.data();

      data['id'] = doc.id;
      data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
      data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
      data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

      return types.User.fromJson(data);
    }).toList();

    return listUsers;
  }

  static Future<List<types.Room>> getChatRooms() async {
    final roomQuery = await FirebaseChatCore.instance.getFirebaseFirestore()
        .collection('rooms')
        .get();

    final rooms = (await processRoomsQuery(
      FirebaseChatCore.instance.getFirebaseFirestore(),
      roomQuery,
      'users',
    ));
    return rooms;
  }

}
