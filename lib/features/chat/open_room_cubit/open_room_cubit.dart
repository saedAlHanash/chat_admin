import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_cubit/m_cubit.dart';

import '../../../services/chat_service/chat_service_core.dart';

part 'open_room_state.dart';

class OpenRoomCubit extends Cubit<OpenRoomInitial> {
  OpenRoomCubit() : super(OpenRoomInitial.initial());

  Future<void> openRoom(types.User chatUser) async {
    emit(state.copyWith(statuses: CubitStatuses.loading, request: chatUser));

    final room = await FirebaseChatCore.instance.createRoom(chatUser.id);
    emit(state.copyWith(statuses: CubitStatuses.done, result: room));
  }

  Future<void> openRoomByRoom(types.Room room) async {
    emit(state.copyWith(statuses: CubitStatuses.init));
    Future(() => emit(state.copyWith(statuses: CubitStatuses.done, result: room)));
  }

  Future<void> openRoomByUserId(String userId) async {
    emit(state.copyWith(statuses: CubitStatuses.loading));
    final chatUser = await ChatServiceCore.getUser(userId);

    if (chatUser == null) {
      emit(state.copyWith(statuses: CubitStatuses.error));
      return;
    }

    final room = await FirebaseChatCore.instance.createRoom(chatUser.id);
    emit(state.copyWith(statuses: CubitStatuses.done, result: room));
  }

  Future<void> openGroupRoom(String roomId) async {
    emit(state.copyWith(statuses: CubitStatuses.loading));

    final room = await FirebaseChatCore.instance.getRoomByRoomId(roomId);
    if (room != null) {
      emit(state.copyWith(statuses: CubitStatuses.done, result: room));
    } else {
      emit(state.copyWith(statuses: CubitStatuses.error, error: 'Group room not found'));
    }
  }
}
