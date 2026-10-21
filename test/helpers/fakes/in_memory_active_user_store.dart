import 'dart:async';

import 'package:klimmeck_guide/repository/storage/active_user_store.dart';

/// [ActiveUserStore] in memoria che registra scritture e cancellazioni.
class InMemoryActiveUserStore implements ActiveUserStore {
  String? userId;
  final List<String> writes = [];
  int clears = 0;
  Object? readFailure;

  /// Se impostato, la scrittura si applica solo quando il test lo completa.
  Completer<void>? pendingWrite;

  @override
  Future<String?> read() async {
    final failure = readFailure;
    if (failure != null) throw failure;
    return userId;
  }

  @override
  Future<void> write(String userId) async {
    writes.add(userId);
    await pendingWrite?.future;
    this.userId = userId;
  }

  @override
  Future<void> clear() async {
    clears++;
    userId = null;
  }
}
