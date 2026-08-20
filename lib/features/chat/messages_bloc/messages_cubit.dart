import 'dart:async';

import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:m_cubit/m_cubit.dart';

part 'messages_state.dart';

class MessagesCubit extends MCubit<MessagesInitial> {
  MessagesCubit() : super(MessagesInitial.initial());

  @override
  String get nameCache => state.mRequest.id.toString();

  @override
  String get filter => state.mRequest.id;

  @override
  bool get withSupperFilet => false;

  Future<void> getChatRoomMessage(types.Room room) async {
    emit(state.copyWith(request: room, statuses: CubitStatuses.loading));
    await messages(room);
  }

  /// Returns a stream of messages from Firebase for a given room.
  Future<void> messages(types.Room room) async {
    await state.stream?.cancel();

    final stream = FirebaseChatCore.instance.getMessagesStream(roomId: room.id).listen((messages) async {
      emit(state.copyWith(result: messages, statuses: CubitStatuses.done));
    });

    emit(state.copyWith(stream: stream));
  }

  Future<void> deleteMessage(String messageId) async {
    await FirebaseChatCore.instance.deleteMessage(messageId, state.mRequest.id);
  }

  @override
  Future<void> close() async {
    await state.stream?.cancel();
    return super.close();
  }
}
