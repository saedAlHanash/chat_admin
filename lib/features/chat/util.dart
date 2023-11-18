import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/main.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import 'my_room_object.dart';

List<types.User> localListUsers = [];

List<types.Room> localListRooms = [];

var myRoomObject = MyRoomObject();

firebase.User? firebaseUser = FirebaseChatCore.instance.firebaseUser;

Future<List<types.User>> getChatUsers() async {
  if (localListUsers.isNotEmpty) return localListUsers;

  final users = await FirebaseFirestore.instance.collection('users').get();

  final listUsers = users.docs.map((doc) {
    final data = doc.data();

    data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
    data['id'] = doc.id;
    data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
    data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

    return types.User.fromJson(data);
  }).toList();

  localListUsers = listUsers;

  return listUsers;
}

bool isMe(types.Room room) {
  for (var e in room.users) {
    if (e.id == firebaseUser?.uid) {
      return true;
    }
  }

  return false;
}

Future<List<types.Room>> getChatRooms() async {
  if (firebaseUser == null) return [];
  if (localListRooms.isNotEmpty) return localListRooms;

  final rooms = await FirebaseFirestore.instance
      .collection('rooms')
      // .where(
      //   'userIds',
      //   arrayContains: firebaseUser?.uid,
      // )
      .get();

  final listRooms = await processRoomsQuery(
    firebaseUser!,
    FirebaseFirestore.instance,
    rooms,
    'users',
  );

  localListRooms = listRooms;

  return listRooms;
}



types.User getChatMember(List<types.User> list, {bool? me}) {
  for (var e in list) {
    if (me ?? false) {
      if (e.id == firebaseUser?.uid) {
        return e;
      }
    } else if (e.id != firebaseUser?.uid) {
      return e;
    }
  }
  throw Exception('user not found');
}

Future<bool> isChatUserFound(String id) async {
  await getChatUsers();
  for (var e in localListUsers) {
    if (e.firstName == id) return true;
  }
  return false;
}

Future<void> createChatUser() async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'fitnes.0@fitnes.com',
      password: '988980!@qweDSAFCA',
    );

    await FirebaseChatCore.instance.createUserInFirestore(
      types.User(
        firstName: '0',
        id: credential.user!.uid,
        lastName: 'Customer Service',
        metadata: {'fcm': await getFireToken()},
      ),
    );
  } on Exception catch (e) {
    if (e.toString().contains('email address is already')) {
      loginChatUser();
    }
  }
}

Future<void> loginChatUser() async {
  var credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: 'fitnes.0@fitnes.com',
    password: '988980!@qweDSAFCA',
  );

  await FirebaseChatCore.instance.createUserInFirestore(
    types.User(
        firstName: '0',
        id: credential.user!.uid,
        lastName: 'Customer Service',
        metadata: {'fcm': await getFireToken()}),
  );
}

Future<void> logoutChatUser() async {
  if (firebaseUser != null) {
    await FirebaseFirestore.instance.collection('users').doc(firebaseUser?.uid).update(
      {
        'metadata': {'fcm': ''},
      },
    );
  }

  await FirebaseAuth.instance.signOut();
}

Future<void> sendNotificationMessage(
    MyRoomObject myRoomObject, ChatNotification message) async {
  if (!myRoomObject.needToSendNotification || myRoomObject.fcmToken.isEmpty) return;

  if (message.body.length > 100) {
    message.body = message.body.substring(0, 99);
  }

  var data = {
    'notification': {'title': message.title, 'body': message.body},
    'to': myRoomObject.fcmToken,
  };

  APIService().postApi(url: 'fcm/send', host: 'fcm.googleapis.com', body: data);

  myRoomObject.needToSendNotification = false;
}

const colors = [
  Color(0xffff6767),
  Color(0xff66e0da),
  Color(0xfff5a2d9),
  Color(0xfff0c722),
  Color(0xff6a85e5),
  Color(0xfffd9a6f),
  Color(0xff92db6e),
  Color(0xff73b8e5),
  Color(0xfffd7590),
  Color(0xffc78ae5),
];

Color getUserAvatarNameColor(types.User user) {
  final index = user.id.hashCode % colors.length;
  return colors[index];
}

String getUserName(types.User user) => (user.lastName ?? '').trim();
