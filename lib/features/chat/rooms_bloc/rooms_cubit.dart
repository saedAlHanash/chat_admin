import 'dart:async';

import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:collection/collection.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/error/error_manager.dart';
import 'package:m_cubit/m_cubit.dart';

part 'rooms_state.dart';

class RoomsCubit extends MCubit<RoomsInitial> {
  RoomsCubit() : super(RoomsInitial.initial());

  @override
  String get nameCache => 'all_rooms_admin';

  List<types.Room> _rawRooms = [];

  Future<void> getChatRooms() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));

    try {
      await rooms();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), statuses: CubitStatuses.error));
      showErrorFromApi(state);
    }
  }

  /// Streams all direct and support rooms for admin observation.
  Future<void> rooms() async {
    await state.stream?.cancel();

    final roomsStream =  FirebaseChatCore.instance.getAllRoomsStream();

    final stream = roomsStream.listen(
      (listRooms) async {
        _rawRooms = List<types.Room>.from(listRooms);
        await processAndEmitRooms();
      },
      onError: (e) {
        emit(state.copyWith(error: e.toString(), statuses: CubitStatuses.done));
      },
    );

    emit(state.copyWith(stream: stream, statuses: .done));
  }

  Future<void> processAndEmitRooms() async {
    var filtered = List<types.Room>.from(_rawRooms);

    // Remove invalid rooms
    filtered.removeWhere((e) => e.users.any((ee) => ee.id == '-1'));

    if (state.search.isNotEmpty) {
      filtered.removeWhere(
        (room) => !(room.usersName.toLowerCase().contains(state.search.toLowerCase())),
      );
    }

    // Sort by updatedAt descending
    filtered.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    // Support rooms (myRooms): rooms containing support user '0'
    final myRooms = filtered.where((e) => e.users.any((u) => u.id == '0')).toList();

    // Others' rooms (othersRooms): conversations between trainers & users
    final othersRooms = filtered.where((e) => !e.users.any((u) => u.id == '0')).toList();

    emit(
      state.copyWith(
        result: filtered,
        myRooms: myRooms,
        othersRooms: othersRooms,
        statuses: CubitStatuses.done,
      ),
    );
  }

  void updateRoom(types.Room room) {
    final index = _rawRooms.indexWhere((e) => e.id == room.id);
    if (index == -1) return;
    _rawRooms[index] = room;
    processAndEmitRooms();
  }

  void search({required String q}) {
    emit(state.copyWith(search: q));
    processAndEmitRooms();
  }

  Future<void> deleteRoom(String id) async {
    try {
      await FirebaseChatCore.instance.deleteRoom(id);
    } catch (e) {
      loggerObject.e('deleteRoom error: $id - $e');
    }
  }

  @override
  Future<void> close() async {
    await state.stream?.cancel();
    return super.close();
  }
}
