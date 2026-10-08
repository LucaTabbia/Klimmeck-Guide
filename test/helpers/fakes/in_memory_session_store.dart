import 'package:klimmeck_guide/repository/storage/session_store.dart';

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore({String? refreshToken}) : _refreshToken = refreshToken;

  String? _refreshToken;
  int writes = 0;
  int clears = 0;
  bool failNextWrite = false;
  Object? readFailure;

  String? get refreshToken => _refreshToken;

  @override
  Future<String?> readRefreshToken() async {
    final failure = readFailure;
    if (failure != null) throw failure;
    return _refreshToken;
  }

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('write failed');
    }
    writes++;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    clears++;
    _refreshToken = null;
  }
}
