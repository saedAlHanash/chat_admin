import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import '../../../core/api_manager/api_service.dart';
import '../../../core/strings/enum_manager.dart';
import '../../../main.dart';
import '../../chat/util.dart';

part 'get_rooms_state.dart';

class GetRoomsCubit extends Cubit<GetRoomsInitial> {
  GetRoomsCubit() : super(GetRoomsInitial.initial());

  Future<void> getChatRooms() async {
    if (firebaseUser == null) return;

    setData(await _getChatRooms());
  }

  Future<List<types.Room>> _getChatRooms() async {
    if (firebaseUser == null) return [];

    final latestUpdate = await getLatestUpdatedRoom;
    final latestUpdateLocal = await getLatestUpdatedFromHive;

    if (latestUpdate <= latestUpdateLocal) return getRoomsFromHive();

    emit(state.copyWith(statuses: CubitStatuses.loading));

    final rooms = await FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('updatedAt', descending: true)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(latestUpdateLocal),
        )
        .get();

    final listRooms = await processRoomsQuery(
      firebaseUser!,
      FirebaseFirestore.instance,
      rooms,
      'users',
    );

    storeRoomsInHive(listRooms);

    return getRoomsFromHive();
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

  Future<int> get getLatestUpdatedFromHive async {
    final sortedRooms = getRoomsFromHive()
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    return sortedRooms.firstOrNull?.updatedAt ?? 0;
  }

  void setData(List<types.Room> rooms) {
    final myRoom = rooms.where((e) => isMe(e)).toList()
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    final otherRoom = rooms.where((e) => !isMe(e)).toList()
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    emit(
      state.copyWith(
        allRooms: rooms,
        myRooms: myRoom,
        otherRooms: otherRoom,
        statuses: CubitStatuses.done,
      ),
    );
  }

  void storeRoomsInHive(List<types.Room> rooms) {
    if (rooms.isEmpty) return;
    rooms.forEachIndexed((i, e) async => await roomsBox.put(e.id, jsonEncode(e)));
  }

  List<types.Room> getRoomsFromHive() {
    return roomsBox.values.map((e) {
      return types.Room.fromJson(jsonDecode(e));
    }).toList();
  }

  /// Returns a stream of messages from Firebase for a given room.
  Stream<List<types.Room>> _rooms() {
    var query = FirebaseFirestore.instance.collection('rooms');

    final result = query.snapshots().map(
      (snapshot) {
        return snapshot.docs.fold<List<types.Room>>(
          [],
          (previousValue, doc) {
            final data = doc.data();

            data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
            data['id'] = doc.id;
            data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

            roomMessage.put(doc.id, jsonEncode(data));

            return [...previousValue, types.Room.fromJson(data)];
          },
        );
      },
    );
    return result;
  }

  bool isMe(types.Room room) {
    for (var e in room.users) {
      if (e.id == firebaseUser?.uid) return true;
    }

    return false;
  }
}
