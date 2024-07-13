import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/services/chat_service/core/firebase_chat_core.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../../../core/api_manager/api_service.dart';
import '../../../core/strings/enum_manager.dart';
import '../../../core/util/abstraction.dart';
import '../../../services/chat_service/core/util.dart';

part 'rooms_state.dart';

class RoomsCubit extends MCubit<RoomsInitial> {
  RoomsCubit() : super(RoomsInitial.initial());

  @override
  String get nameCache => 'rooms1';

  @override
  String get filter => '0';

  Future<void> getChatRooms() async {
    await setData();

    rooms();
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> rooms() async {
    await state.stream?.cancel();

    emit(state.copyWith(statuses: CubitStatuses.loading));
    loggerObject.f('start');
    late final Query<Map<String, dynamic>> query;

    query = FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('updatedAt', descending: true)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            state.result.lastOrNull?.updatedAt ?? 0,
          ),
        );

    final stream = query.snapshots().listen((snapshot) async {
      final listRooms = await processRoomsQuery(
        FirebaseFirestore.instance,
        snapshot,
        'users',
      );

      await sortDataWithIds(listRooms);

      loggerObject.f('message');
      if (state.statuses.loading) {
        emit(state.copyWith(statuses: CubitStatuses.done));
      }
      if (isClosed) return;
      await setData();
    });

    emit(state.copyWith(stream: stream));
  }

  Future<void> setData() async {
    final data =
        (await getListCached()).map((e) => types.Room.fromJson(e)).toList();

    final dataList = data
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    var roomsCached = <Room>[];
    if (state.search.isEmpty) {
      roomsCached = dataList;
    } else {
      roomsCached = dataList
          .where((room) =>
              room.usersName.toLowerCase().contains(state.search.toLowerCase()))
          .toList();
    }

    final myRooms = roomsCached
        .where((e) => e.users.firstWhereOrNull((e) => e.id == '0') != null)
        .toList();

    final othersRooms = roomsCached
        .where((e) => e.users.firstWhereOrNull((e) => e.id == '0') == null)
        .toList();

    emit(state.copyWith(
      result: roomsCached,
      myRooms: myRooms,
      othersRooms: othersRooms,
    ));
  }

  void search({required String q}) {
    emit(state.copyWith(search: q));
    setData();
  }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
