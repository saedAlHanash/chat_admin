
import '../../../core/api_manager/api_url.dart';

class FirebaseChatCoreConfig {
  static FirebaseChatCoreConfig? _instance;

  /// Singleton accessor
  static FirebaseChatCoreConfig get instance {
    _instance ??= FirebaseChatCoreConfig._internal(
      null,
      'rooms',
      'users',
      'sentMessagesIds',
    );

    return _instance!;
  }

  /// Private constructor
  FirebaseChatCoreConfig._internal(
      this._firebaseAppName,
      this._roomsCollectionName,
      this._usersCollectionName,
      this._sentMessagesIds,
      );

  final String? _firebaseAppName;
  final String _roomsCollectionName;
  final String _usersCollectionName;
  final String _sentMessagesIds;

  String? get firebaseAppName => _firebaseAppName;

  String get roomsCollectionName =>
      '${isTestMode ? 'test_' : ''}$_roomsCollectionName';

  String get usersCollectionName =>
      '${isTestMode ? 'test_' : ''}$_usersCollectionName';

  String get sentMessagesIds =>
      '${isTestMode ? 'test_' : ''}$_sentMessagesIds';
}
