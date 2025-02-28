import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/error/error_manager.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:m_cubit/m_cubit.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/chat_service/core/util.dart';

part 'rooms_state.dart';

class RoomsCubit extends MCubit<RoomsInitial> {
  RoomsCubit() : super(RoomsInitial.initial());

  @override
  String get nameCache => 'rooms1';

  @override
  String get filter => '0';

  Future<void> saveJsonToFile(
      List<Map<String, dynamic>> jsonData, String fileName) async {
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

  Future<void> getChatRooms() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));

    await setData();

    try {
      await rooms();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      showErrorFromApi(state);
    }
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> rooms() async {
    // جلب المحادثات من firestore على الشكل التالي
    // آخر 100 رسالة
    // بحيث تكون جميع الرسائل أكبر من تاريخ آخر رسالة مخزنة
    final query = FirebaseFirestore.instance
        .collection('rooms')
        .orderBy('updatedAt', descending: true)
        // .limit(100)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
            state.result.firstOrNull?.updatedAt ?? 0,
          ),
        );

    // توقيت آخر محادثة موجودة ضمن الرسائل
    var latestUpdate = state.result.firstOrNull?.updatedAt ?? 0;
    // إيقاف آخر stream موجود مسبقا
    await state.stream?.cancel();

    final stream = query.snapshots().listen((snapshot) async {
      //تجميع جميع المحادثات القادمة من ال stream
      final listRooms = await processRoomsQuery(snapshot, 'users');
      //في حال فارغة لا تكمل
      if (listRooms.isEmpty) return;

      // // جلب آخر وقت تحديث لآخر رسالة
      // final latestUpdateMessageFromSnap = listRooms
      //     .reduce((c, n) => (c.updatedAt ?? 0) > (n.updatedAt ?? 0) ? c : n)
      //     .updatedAt;
      //
      // // حذف الرسائل المكررة والمعالجة مسبقا
      // listRooms.removeWhere((e) => ((e.updatedAt ?? 0) <= latestUpdate));
      //
      // //تحديث توقيت آخر معالجة للرسائل
      // latestUpdate = latestUpdateMessageFromSnap ?? 0;
      // //في حال فارغة لا تكمل
      // if (listRooms.isEmpty) return;
      //حفظ الرسائل الجديدة في طبقة التخزين

      await saveData(listRooms, clearId: false);

      if (state.statuses.loading) {
        emit(state.copyWith(statuses: CubitStatuses.done));
      }

      //اذا توقف ال bloc لا تكمل
      if (isClosed) return;
      // إرسال المعلومات للوجهة
      await setData();
    });

    emit(state.copyWith(
      stream: stream,
      statuses: state.result.isNotEmpty ? CubitStatuses.done : null,
    ));
  }

  Future<void> setData() async {
    final roomsCached = await getListCached(
      fromJson: types.Room.fromJson,
    );

    roomsCached
        .removeWhere((e) => e.users.firstWhereOrNull((ee) => ee.id == '-1') != null);

    if (state.search.isNotEmpty) {
      roomsCached.removeWhere(
        (room) => !(room.usersName.toLowerCase().contains(state.search.toLowerCase())),
      );
    }

    roomsCached.sort((a, b) {
      if (a.isRead != b.isRead) return (b.isNotRead) ? 1 : -1;

      return (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0);
    });

    final myRooms = roomsCached
        .where((e) => e.users.firstWhereOrNull((e) => e.id == '0') != null)
        .toList();

    final othersRooms = roomsCached
        .where((e) => e.users.firstWhereOrNull((e) => e.id == '0') == null)
        .toList();

    emit(
      state.copyWith(
        result: roomsCached,
        myRooms: myRooms,
        othersRooms: othersRooms,
      ),
    );
  }

  void search({required String q}) {
    emit(state.copyWith(search: q));
    setData();
  }

  Future<void> deleteRoom(String id) async {
    await FirebaseFirestore.instance.collection('rooms').doc(id).delete();
    loggerObject.e(id);
  }

  // void checkRoomsAndDelete() async {
  //   var c = [];
  //   for (var e in state.result) {
  //     if (e.users.firstWhereOrNull((e) => e.id == '-1') != null) {
  //       c.add(e.id);
  //     }
  //   }
  //   loggerObject.w(c.length);
  //   // for (var e in c) {
  //   //   await deleteRoom(e);
  //   // }
  // }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
