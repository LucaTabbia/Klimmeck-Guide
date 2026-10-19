import 'dart:async';

import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';

/// [PushMessagingPort] scriptabile: token, errore e stream controllati dal test.
class FakePushMessagingPort implements PushMessagingPort {
  String? currentToken = 'token-1';
  Object? tokenFailure;
  int tokenCalls = 0;
  final StreamController<String> refreshes =
      StreamController<String>.broadcast();
  final StreamController<Map<String, String>> foreground =
      StreamController<Map<String, String>>.broadcast();

  @override
  Future<String?> token() async {
    tokenCalls++;
    final failure = tokenFailure;
    if (failure != null) throw failure;
    return currentToken;
  }

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<Map<String, String>> get foregroundMessages => foreground.stream;

  Future<void> close() async {
    await refreshes.close();
    await foreground.close();
  }
}
