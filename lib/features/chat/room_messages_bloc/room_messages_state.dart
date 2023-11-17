part of 'room_messages_cubit.dart';

class RoomMessagesInitial extends Equatable {
  final CubitStatuses statuses;
  final List<types.Message> allMessages;
  final String error;
  final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? stream;

  const RoomMessagesInitial({
    required this.statuses,
    required this.allMessages,
    required this.error,
    this.stream,
  });

  factory RoomMessagesInitial.initial() {
    return RoomMessagesInitial(
      allMessages:
          roomMessage.values.map((e) => types.Message.fromJson(jsonDecode(e))).toList()
            ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0)),
      error: '',
      statuses: CubitStatuses.init,
    );
  }

  @override
  List<Object> get props => [statuses, allMessages, error];

  RoomMessagesInitial copyWith({
    CubitStatuses? statuses,
    List<types.Message>? allMessages,
    String? error,
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? stream,
  }) {
    return RoomMessagesInitial(
        statuses: statuses ?? this.statuses,
        allMessages: allMessages ?? this.allMessages,
        error: error ?? this.error,
        stream: stream ?? this.stream);
  }
}
