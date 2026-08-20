import 'dart:async';

import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/error/error_manager.dart';
import 'package:m_cubit/m_cubit.dart';

part 'group_session_rooms_state.dart';

class GroupSessionRoomsCubit extends MCubit<GroupSessionRoomsInitial> {
  GroupSessionRoomsCubit() : super(GroupSessionRoomsInitial.initial());

  @override
  String get nameCache => 'all_group_rooms_admin';

  List<types.Room> _rawRooms = [];

  Future<void> getGroupRooms() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));

    try {
      await listenGroupRooms();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), statuses: CubitStatuses.error));
      showErrorFromApi(state);
    }
  }

  Future<void> listenGroupRooms() async {
    await state.stream?.cancel();

    final groupStream = await FirebaseChatCore.instance.getAllGroupSessionRoomsStream();

    final stream = groupStream.listen(
      (rooms) async {
        _rawRooms = List<types.Room>.from(rooms);
        await processAndEmitRooms();
      },
      onError: (err) {
        emit(state.copyWith(statuses: CubitStatuses.done, error: err.toString()));
      },
    );

    emit(state.copyWith(stream: stream, statuses: state.result.isNotEmpty ? CubitStatuses.done : null));
  }

  Future<void> processAndEmitRooms() async {
    var filtered = List<types.Room>.from(_rawRooms);

    if (state.search.isNotEmpty) {
      filtered.removeWhere(
        (room) => !(room.name?.toLowerCase().contains(state.search.toLowerCase()) ?? false) &&
            !(room.usersName.toLowerCase().contains(state.search.toLowerCase())),
      );
    }

    filtered.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    emit(state.copyWith(result: filtered, statuses: CubitStatuses.done));
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

  /// Admin Action: Mute or Unmute a member in group session
  Future<void> muteMember(String roomId, String userId, bool isMuted) async {
    try {
      await FirebaseChatCore.instance.muteMemberInGroupSession(roomId, userId, isMuted);
    } catch (e) {
      loggerObject.e('muteMember error: $roomId, $userId - $e');
    }
  }

  /// Admin Action: Kick / Remove a member from group session
  Future<void> removeMember(String roomId, String userId) async {
    try {
      await FirebaseChatCore.instance.removeMemberFromGroupSession(roomId, userId);
    } catch (e) {
      loggerObject.e('removeMember error: $roomId, $userId - $e');
    }
  }

  @override
  Future<void> close() async {
    await state.stream?.cancel();
    return super.close();
  }
}
