import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_state_channel.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

void main() {
  late AuthStateChannel channel;

  setUp(() => channel = AuthStateChannel());
  tearDown(() => channel.close());

  test('current is null before the first emit and tracks the last state', () {
    expect(channel.current, isNull);

    channel.emit(const AuthBootstrapping());
    channel.emit(const AuthUnauthenticated());

    expect(channel.current, const AuthUnauthenticated());
  });

  test('late listener gets the last state replayed, then updates', () async {
    channel.emit(const AuthBootstrapping());

    final received = <AuthState>[];
    final sub = channel.stream.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    channel.emit(const AuthUnauthenticated());
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(received, [const AuthBootstrapping(), const AuthUnauthenticated()]);
  });

  test('concurrent listeners receive the same states', () async {
    final a = <AuthState>[];
    final b = <AuthState>[];
    final subA = channel.stream.listen(a.add);
    final subB = channel.stream.listen(b.add);

    channel.emit(const AuthBootstrapping());
    channel.emit(const AuthUnauthenticated());
    await Future<void>.delayed(Duration.zero);
    await subA.cancel();
    await subB.cancel();

    expect(a, [const AuthBootstrapping(), const AuthUnauthenticated()]);
    expect(b, a);
  });

  test(
    'close completes the stream and emit afterwards does not throw',
    () async {
      final done = expectLater(channel.stream, emitsDone);

      await channel.close();
      await done;

      expect(() => channel.emit(const AuthBootstrapping()), returnsNormally);
    },
  );
}
