import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../core/strings/enum_manager.dart';
import '../../../core/util/abstraction.dart';

part 'users_state.dart';

class UsersCubit extends MCubit<UsersInitial> {
  UsersCubit() : super(UsersInitial.initial());

  @override
  String get nameCache => 'users';

  @override
  String get filter => '0';

  Future<void> getChatUsers() async {
    emit(state.copyWith(statuses: CubitStatuses.done));

    await setData();

    users();
  }

  /// Returns a stream of messages from Firebase for a given room.
  void users() {
    late final Query<Map<String, dynamic>> query;

    query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('updatedAt', descending: true)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            state.result.lastOrNull?.updatedAt ?? 0,
          ),
        );

    final stream = query.snapshots().listen((snapshot) async {
      final users = snapshot.docs.map(
        (doc) {
          final data = doc.data();

          data['id'] = doc.id;
          data['createdAt'] = data['createdAt']?.millisecondsSinceEpoch;
          data['lastSeen'] = data['lastSeen']?.millisecondsSinceEpoch;
          data['updatedAt'] = data['updatedAt']?.millisecondsSinceEpoch;

          return types.User.fromJson(data);
        },
      );

      await sortDataChat(users);

      if (state.statuses.loading) {
        emit(state.copyWith(statuses: CubitStatuses.done));
      }
      if (isClosed) return;

      await setData();
    });

    emit(state.copyWith(stream: stream));
  }

  Future<void> setData() async {
    final data = (await getListCached()).map((e) => types.User.fromJson(e)).toList();
    final dataList = data..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    var usersCached = <types.User>[];
    if (state.search.isEmpty) {
      usersCached = dataList;
    } else {
      usersCached = dataList
          .where((room) =>
              (room.firstName ?? '').toLowerCase().contains(state.search.toLowerCase()))
          .toList();
    }

    emit(state.copyWith(result: usersCached));
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
