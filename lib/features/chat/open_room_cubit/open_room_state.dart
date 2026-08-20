part of 'open_room_cubit.dart';

class OpenRoomInitial extends AbstractState<types.Room?> {
  const OpenRoomInitial({
    required super.result,
    super.error,
    super.request,
    super.statuses,
  });

  factory OpenRoomInitial.initial() {
    return const OpenRoomInitial(
      result: null,
      error: '',
      statuses: CubitStatuses.init,
    );
  }

  @override
  List<Object?> get props => [
        statuses,
        error,
        if (result != null) result!,
        if (request != null) request,
      ];

  OpenRoomInitial copyWith({
    CubitStatuses? statuses,
    types.Room? result,
    String? error,
    dynamic request,
  }) {
    return OpenRoomInitial(
      statuses: statuses ?? this.statuses,
      result: result ?? this.result,
      error: error ?? this.error,
      request: request ?? this.request,
    );
  }
}
