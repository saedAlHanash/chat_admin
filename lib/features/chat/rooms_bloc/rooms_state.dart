part of 'rooms_cubit.dart';

enum RoomFilterType {
  all,
  unread,
}

class RoomsInitial extends AbstractState<List<types.Room>> {
  final StreamSubscription? stream;
  final String search;
  final RoomFilterType filterType;
  final List<types.Room> myRooms;
  final List<types.Room> othersRooms;

  const RoomsInitial({
    required super.result,
    super.statuses,
    super.request,
    super.error,
    this.stream,
    required this.myRooms,
    required this.othersRooms,
    this.search = '',
    this.filterType = RoomFilterType.all,
  });

  bool? get mRequest => request as bool?;

  @override
  List<Object?> get props => [
        statuses,
        error,
        result,
        search,
        filterType,
        myRooms,
        othersRooms,
        if (request != null) request,
        if (stream != null) stream,
      ];

  factory RoomsInitial.initial() {
    return const RoomsInitial(
      result: [],
      myRooms: [],
      othersRooms: [],
      filterType: RoomFilterType.all,
      statuses: CubitStatuses.init,
    );
  }

  bool get notRead {
    final room = myRooms.firstWhereOrNull((e) => e.isNotRead);
    return room != null;
  }

  int get unreadCount {
    return myRooms.where((e) => e.isNotRead).length;
  }

  RoomsInitial copyWith({
    CubitStatuses? statuses,
    List<types.Room>? result,
    List<types.Room>? myRooms,
    List<types.Room>? othersRooms,
    String? error,
    String? search,
    RoomFilterType? filterType,
    bool? request,
    StreamSubscription? stream,
  }) {
    return RoomsInitial(
      statuses: statuses ?? this.statuses,
      result: result ?? this.result,
      error: error ?? this.error,
      search: search ?? this.search,
      filterType: filterType ?? this.filterType,
      request: request ?? this.request,
      myRooms: myRooms ?? this.myRooms,
      othersRooms: othersRooms ?? this.othersRooms,
      stream: stream ?? this.stream,
    );
  }
}

