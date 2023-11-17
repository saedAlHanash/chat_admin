part of 'get_rooms_cubit.dart';

class GetRoomsInitial extends Equatable {
  final CubitStatuses statuses;
  final List<types.Room> allRooms;
  final List<types.Room> myRooms;
  final List<types.Room> otherRooms;
  final String error;

  const GetRoomsInitial({
    required this.statuses,
    required this.allRooms,
    required this.error,
    required this.myRooms,
    required this.otherRooms,
  });

  factory GetRoomsInitial.initial() {
    return const GetRoomsInitial(
      allRooms: [],
      myRooms: [],
      otherRooms: [],
      error: '',
      statuses: CubitStatuses.init,
    );
  }

  @override
  List<Object> get props => [statuses, allRooms, error];

  GetRoomsInitial copyWith({
    CubitStatuses? statuses,
    List<types.Room>? allRooms,
    List<types.Room>? myRooms,
    List<types.Room>? otherRooms,
    String? error,
  }) {
    return GetRoomsInitial(
      statuses: statuses ?? this.statuses,
      allRooms: allRooms ?? this.allRooms,
      myRooms: myRooms ?? this.myRooms,
      otherRooms: otherRooms ?? this.otherRooms,
      error: error ?? this.error,
    );
  }

}