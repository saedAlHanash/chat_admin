import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:m_cubit/m_cubit.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/chat_service/core/firebase_chat_core_config.dart';
import '../../../services/chat_service/core/util.dart';

part 'users_state.dart';

class UsersCubit extends MCubit<UsersInitial> {
  UsersCubit() : super(UsersInitial.initial());

  @override
  String get nameCache => 'users';

  @override
  String get filter => '0';

  Future<void> getChatUsers() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));
    await setData();

    if (state.result.isEmpty) await Future.delayed(Duration(seconds: 4));

    await users();
  }

  Future<void> saveJsonToFile(List<Map<String, dynamic>> jsonData, String fileName) async {
    // تحويل القائمة إلى JSON String
    String jsonString = jsonEncode(jsonData);

    // الحصول على المسار المؤقت لحفظ الملف
    final directory = await getTemporaryDirectory();
    final file = await File('${directory.path}/$fileName.json').writeAsString(jsonString);

    // تحديد مرجع التخزين في Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('json_files/$fileName.json');

    // رفع الملف
    await storageRef.putFile(file);
    // كتابة البيانات إلى الملف
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> users() async {
    late final Query<Map<String, dynamic>> query;

    query =
        FirebaseFirestore.instance.collection(FirebaseChatCoreConfig.instance.usersCollectionName).orderBy('updatedAt', descending: true).where(
              'updatedAt',
              isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
                state.result.firstOrNull?.updatedAt ?? 0,
              ),
            );

    final stream = query.snapshots().listen((snapshot) async {
      final users = snapshot.docs.map((doc) => doc.user);

      for (var e in users) {
        if (e.firstName?.toLowerCase() == 'guest') {
          await deleteUser(e.id);
        }
      }
      if (users.isEmpty) return;
      await saveData(users, clearId: false);

      if (state.statuses.loading) {
        emit(state.copyWith(statuses: CubitStatuses.done));
      }

      if (isClosed) return;

      await setData();
    });

    emit(
      state.copyWith(
        stream: stream,
        statuses: state.result.isNotEmpty ? CubitStatuses.done : null,
      ),
    );
  }

  types.User? findUser(String id) {
    final user = state.result.firstWhereOrNull((e) => e.id == id);
    return user;
  }

  Future<types.User> fetchUser(String id) async {
    final user = await fetchUserModel(FirebaseFirestore.instance, id);
    return user;
  }

  Future<void> setData() async {
    final data = await getListCached(
      fromJson: types.User.fromJson,
      deleteFunction: (json) {
        return json['firstName']?.toString().toLowerCase() == 'guest';
      },
    );

    final dataList = data..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

    var usersCached = <types.User>[];

    if (state.search.isEmpty) {
      usersCached = dataList;
    } else {
      usersCached = dataList
          .where(
              (room) => (room.firstName ?? '').toLowerCase().contains(state.search.toLowerCase()))
          .toList();
    }

    emit(state.copyWith(result: usersCached));
  }

  Future<void> addUser(types.User e) async {
    await saveData([e], clearId: false);
  }

  void search({required String q}) {
    emit(state.copyWith(search: q));
    setData();
  }

  Future<void> deleteUser(String id) async {
    await FirebaseFirestore.instance.collection(FirebaseChatCoreConfig.instance.usersCollectionName).doc(id).delete();
  }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
