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

class ChatServiceCore {
  static Future<void> initFirebaseChat() async {
    loginChatUser();
    return;
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
          metadata: {'fcm': await getFireToken()},
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
    if (user.id == '-1') return null;
    return user;
  }

  static Future<bool> latestSeenRoom(String? roomId) async {
    if (roomId == null) return false;
    try {
      await FirebaseChatCore.instance.latestSeenRoom(roomId);
      return true;
    } catch (e) {
      loggerObject.e('latestSeenRoom $e');
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
}
