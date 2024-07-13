import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

import '../../../../core/strings/enum_manager.dart';
import '../../../../core/util/abstraction.dart';
import '../../../services/chat_service/chat_service_core.dart';
import '../../../services/chat_service/core/firebase_chat_core.dart';

part 'open_room_state.dart';

class OpenRoomCubit extends Cubit<OpenRoomInitial> {
  OpenRoomCubit() : super(OpenRoomInitial.initial());

  Future<void> openRoom(User chatUser) async {
    emit(state.copyWith(statuses: CubitStatuses.loading, request: chatUser));

    final room = await FirebaseChatCore.instance.createRoom(chatUser);
    emit(state.copyWith(statuses: CubitStatuses.done, result: room));

  }

  Future<void> openRoomByRoom(Room room) async {
    emit(state.copyWith(statuses: CubitStatuses.init));
    Future(() =>
        emit(state.copyWith(statuses: CubitStatuses.done, result: room)));

  }

  Future<void> openRoomByUserId(String userId) async {
    emit(state.copyWith(statuses: CubitStatuses.loading));
    final chatUser = await ChatServiceCore.getUser(userId);

    if (chatUser == null) {
      emit(state.copyWith(statuses: CubitStatuses.error));
      return;
    }

    final room = await FirebaseChatCore.instance.createRoom(chatUser);
    emit(state.copyWith(statuses: CubitStatuses.done, result: room));
  }

  Future<void> openRoomCustomerService() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));

  }
}
