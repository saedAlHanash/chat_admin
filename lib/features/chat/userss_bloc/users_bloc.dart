import 'dart:async';

import 'package:chat_lib/chat_lib.dart';
import 'package:chat_lib/chat_lib.dart' as types;
import 'package:collection/collection.dart';
import 'package:m_cubit/m_cubit.dart';

part 'users_state.dart';

class UsersCubit extends MCubit<UsersInitial> {
  UsersCubit() : super(UsersInitial.initial());

  @override
  String get nameCache => 'users_admin';

  @override
  bool get withSupperFilet => false;

  List<types.User> _rawUsers = [];

  Future<void> getChatUsers() async {
    emit(state.copyWith(statuses: CubitStatuses.loading));
    await users();
  }

  /// Returns a stream of users from Firebase synchronized with local cache.
  Future<void> users() async {
    await state.stream?.cancel();

    final usersStream = FirebaseChatCore.instance.getUsersStream();
    final stream = usersStream.listen(
      (listUsers) async {
        _rawUsers = List<types.User>.from(listUsers);
        await processAndEmitUsers();
      },
      onError: (e) {
        emit(state.copyWith(error: e.toString(), statuses: CubitStatuses.done));
      },
    );

    emit(
      state.copyWith(
        stream: stream,
        statuses: .done
      ),
    );
  }

  Future<void> processAndEmitUsers() async {
    var filtered = List<types.User>.from(_rawUsers);

    // Filter out guests
    filtered.removeWhere((user) => (user.firstName ?? '').toLowerCase() == 'guest');

    // Sort by createdAt descending
    filtered.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

    if (state.search.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              (user.firstName ?? '').toLowerCase().contains(state.search.toLowerCase()) ||
              (user.lastName ?? '').toLowerCase().contains(state.search.toLowerCase()))
          .toList();
    }

    emit(state.copyWith(result: filtered, statuses: CubitStatuses.done));
  }

  Future<void> addUser(types.User e) async {
    await ChatCacheManager.instance.cacheUser(e);
  }

  void search({required String q}) {
    emit(state.copyWith(search: q));
    processAndEmitUsers();
  }

  Future<types.User?> fetchUser(String id) async {
    return await FirebaseChatCore.instance.fetchUser(id);
  }

  types.User? findUser(String id) {
    return state.result.firstWhereOrNull((e) => e.id == id);
  }

  @override
  Future<void> close() async {
    await state.stream?.cancel();
    return super.close();
  }
}
