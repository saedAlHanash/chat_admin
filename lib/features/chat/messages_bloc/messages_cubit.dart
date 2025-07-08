import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:m_cubit/m_cubit.dart';

import '../../../core/util/cheker_helper.dart';
import '../../../services/chat_service/core/firebase_chat_core_config.dart';

part 'messages_state.dart';

class MessagesCubit extends MCubit<MessagesInitial> {
  MessagesCubit() : super(MessagesInitial.initial());

  @override
  String get nameCache => state.mRequest.id.toString();

  @override
  String get filter => state.mRequest.id;

  Future<void> getChatRoomMessage(types.Room room) async {
    emit(state.copyWith(request: room));

    await setData();

    await Future.delayed(const Duration(milliseconds: 600));

    await messages(room);
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> messages(types.Room room) async {
    // جلب الرسائل من firestore على الشكل التالي
    // آخر 100 رسالة
    // بحيث تكون جميع الرسائل أكبر من تاريخ آخر رسالة مخزنة
    var query = FirebaseFirestore.instance
        .collection('${FirebaseChatCoreConfig.instance.roomsCollectionName}/${room.id}/messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .where(
          'updatedAt',
          isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
              state.result.firstOrNull?.updatedAt ?? 0),
        );

    // توقيت آخر رسالة موجودة ضمن الرسائل
    var latestUpdate = state.result.firstOrNull?.updatedAt ?? 0;
    // إيقاف آخر stream موجود مسبقا
    await state.stream?.cancel();

    final stream = query.snapshots().listen((snapshot) async {
      //تجميع جميع الرسائل القادمة من ال stream
      final messages = snapshot.docs.map((doc) => doc.message(room)).toList();
      //في حال فارغة لا تكمل
      if (messages.isEmpty) return;
      // جلب آخر وقت تحديث لآخر رسالة
      final latestUpdateMessageFromSnap = messages.reduce(
        (current, next) =>
            current['updatedAt'] > next['updatedAt'] ? current : next,
      )['updatedAt'];
      // حذف الرسائل المكررة والمعالجة مسبقا
      messages.removeWhere((e) => (e['updatedAt'] <= latestUpdate));
      //تحديث توقيت آخر معالجة للرسائل
      latestUpdate = latestUpdateMessageFromSnap;
      //في حال فارغة لا تكمل
      if (messages.isEmpty) return;
      //حفظ الرسائل الجديدة في طبقة التخزين
      await saveData(messages, clearId: false);
      //اذا توقف ال bloc لا تكمل
      if (isClosed) return;
      // إرسال المعلومات للوجهة
      await setData();
    });

    emit(state.copyWith(stream: stream));
  }

  Future<void> setData() async {
    final nowTimeMillis = DateTime.now().millisecondsSinceEpoch;
    // جلب الرسائل من طبقة التخزين
    final allMessages = await getListCached(
      fromJson: types.Message.fromJson,
      // تابع الحذ لحذف الملفات التي هي أكبر من شهر
      deleteFunction: (json) {
        // نوع الرسالة
        final type = json['type'];
        // soft delete
        final isDeleted = json['metadata']?['isDeleted'] == true;
        final b1 =
            // ملف او فيديو
            (type == 'file' || type == 'video') &&
                // مضى أكثر من شهر
                isMoreThanOneMonth(json['createdAt'] ?? 0, nowTimeMillis);

        return b1 || isDeleted;
      },
    )
      // ترتيب بحسب تاريخ الإنشاء
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

    emit(state.copyWith(result: allMessages));
  }

  Future<void> deleteMessage(String id) async {
    await FirebaseFirestore.instance
        .collection('${FirebaseChatCoreConfig.instance.roomsCollectionName}/${state.mRequest.id}/messages')
        .doc(id)
        .update(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {'isDeleted': true},
      },
    );
  }

  @override
  Future<Function> close() async {
    super.close();
    state.stream?.cancel();
    return () {};
  }
}
