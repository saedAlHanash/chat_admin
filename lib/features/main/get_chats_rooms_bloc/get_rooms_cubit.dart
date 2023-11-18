import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import '../../../core/strings/enum_manager.dart';
import '../../../main.dart';
import '../../chat/util.dart';

part 'get_rooms_state.dart';

class GetRoomsCubit extends Cubit<GetRoomsInitial> {
  GetRoomsCubit() : super(GetRoomsInitial.initial());

  Future<void> getChatRooms() async {
    if (firebaseUser == null) return;

    rooms();
  }

  /// Returns a stream of messages from Firebase for a given room.
  void rooms() {
    var query = FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('updatedAt', descending: true)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            getLatestUpdatedFromHive,
          ),
        );

    final stream = query.snapshots().listen((snapshot) async {
      final listRooms = await processRoomsQuery(
        firebaseUser!,
        FirebaseFirestore.instance,
        snapshot,
        'users',
      );

      storeRoomsInHive(listRooms);

      if (!isClosed) {
        _setData();
      }
    });

    emit(state.copyWith(stream: stream));
  }

  Future<int> get getLatestUpdatedRoom async {
    final latestUpdateItem = await FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    final item = latestUpdateItem.docs.firstOrNull?.data();

    item?['updatedAt'] = item['updatedAt']?.millisecondsSinceEpoch;

    return item?['updatedAt'] ?? 1;
  }

  int get getLatestUpdatedFromHive {
    return state.allRooms.firstOrNull?.updatedAt ?? 0;
  }

  void _setData() {
    final rooms = getRoomsFromHive;
    final myRoom = rooms.where((e) => isMe(e)).toList();
    final otherRoom = rooms.where((e) => !isMe(e)).toList();

    final allRooms = rooms
      // ..addAll(rooms)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    final myRooms = myRoom
      // ..addAll(myRoom)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    final otherRooms = otherRoom
      // ..addAll(otherRoom)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    emit(
      state.copyWith(
        allRooms: allRooms,
        myRooms: myRooms,
        otherRooms: otherRooms,
        statuses: CubitStatuses.done,
      ),
    );
  }

  Future<types.Room?> getRoomByUser(String? id) async {
    if (id == null) return null;

    for (var e in state.myRooms) {
      for (var e1 in e.users) {
        if (e1.id == id) {
          return e;
        }
      }
    }

    for (var e in await getChatUsers()) {
      if (e.id == id) {
        var newRoom = await FirebaseChatCore.instance.createRoom(e);
        // localListRooms.add(newRoom);
        return newRoom;
      }
    }
    return null;
  }

  List<types.Room> get getRoomsFromHive {
    return roomsBox.values.map((e) {
      return types.Room.fromJson(jsonDecode(e));
    }).toList();
  }

  Future<void> storeRoomsInHive(List<types.Room> rooms) async {
    for (var i = 0; i < rooms.length; i++) {
      final e = rooms[i];
      await roomsBox.put(e.id, jsonEncode(e));
    }
  }

  void updateRooms() {
    _setData();
  }

  void search(String s) {
    final filtered = state.allRooms.where(
      (e) {
        for (var e1 in e.users) {
          if ((e1.lastName)?.toLowerCase().contains(s.toLowerCase()) ?? false) {
            return true;
          }
        }
        return false;
      },
    ).toList();

    emit(
      state.copyWith(filterRooms: filtered),
    );
  }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
