import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../../core/strings/enum_manager.dart';
import 'package:m_cubit/m_cubit.dart';

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

    if (state.result.isEmpty) await Future.delayed(Duration(seconds: 4));

    await users();
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> users() async {
    late final Query<Map<String, dynamic>> query;

    var x  = state.result.lastOrNull?.updatedAt;
    query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('updatedAt', descending: true)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            state.result.firstOrNull?.updatedAt ?? 0,
          ),
        );

    final stream = query.snapshots().listen((snapshot) async {
      final users = snapshot.docs.map((doc) => doc.user);

      if(users.isEmpty)return;
      await saveData(users);

      if (state.statuses.loading) {
        emit(state.copyWith(statuses: CubitStatuses.done));
      }

      if (isClosed) return;

      await setData();
    });

    emit(state.copyWith(stream: stream));
  }

  types.User? findUser(String id) {
    final user = state.result.firstWhereOrNull((e) => e.id == id);
    return user;
  }

  Future<void> setData() async {
    final data = await getListCached(fromJson: types.User.fromJson);

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
