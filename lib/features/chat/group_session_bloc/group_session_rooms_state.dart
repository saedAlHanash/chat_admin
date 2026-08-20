part of 'group_session_rooms_cubit.dart';

class GroupSessionRoomsInitial extends AbstractState<List<types.Room>> {
  final StreamSubscription? stream;
  final String search;

  const GroupSessionRoomsInitial({
    required super.result,
    super.statuses,
    super.request,
    super.error,
    this.stream,
    this.search = '',
  });

  @override
  List<Object?> get props => [
        statuses,
        error,
        result,
        search,
        if (request != null) request,
        if (stream != null) stream,
      ];

  factory GroupSessionRoomsInitial.initial() {
    return const GroupSessionRoomsInitial(
      result: [],
      statuses: CubitStatuses.init,
    );
  }

  GroupSessionRoomsInitial copyWith({
    CubitStatuses? statuses,
    List<types.Room>? result,
    String? error,
    String? search,
    StreamSubscription? stream,
  }) {
    return GroupSessionRoomsInitial(
      statuses: statuses ?? this.statuses,
      result: result ?? this.result,
      error: error ?? this.error,
      search: search ?? this.search,
      stream: stream ?? this.stream,
    );
  }
}
