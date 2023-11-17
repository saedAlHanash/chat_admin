import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import '../../../core/strings/enum_manager.dart';
import '../../../main.dart';
import '../../chat/util.dart';

part 'room_messages_state.dart';

class RoomMessagesCubit extends Cubit<RoomMessagesInitial> {
  RoomMessagesCubit() : super(RoomMessagesInitial.initial());

  Future<void> getChatRoomMessage(types.Room room) async {
    if (firebaseUser == null) return;
    messages(room);
  }

  /// Returns a stream of messages from Firebase for a given room.
  void messages(types.Room room) {
    var query = FirebaseFirestore.instance
        .collection('rooms/${room.id}/messages')
        .orderBy('createdAt', descending: true)
        .where(
          'createdAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            getLatestUpdatedFromHive,
          ),
        );

    final stream = query.snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final author = room.users.firstWhere(
          (u) => u.id == data['authorId'],
          orElse: () => types.User(id: data['authorId'] as String),
        );

        data['author'] = author.toJson();
        data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
        data['id'] = doc.id;
        data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

        roomMessage.put(doc.id, jsonEncode(data));
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            allMessages: roomMessage.values
                .map((e) => types.Message.fromJson(jsonDecode(e)))
                .toList()
              ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0)),
          ),
        );
      }
      loggerObject.w('saed');
    });

    emit(state.copyWith(stream: stream));
  }

  int get getLatestUpdatedFromHive {
    return state.allMessages.firstOrNull?.updatedAt ?? 0;
  }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
