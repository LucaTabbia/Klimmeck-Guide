import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';

void main() {
  late UserRefreshRequestBus bus;

  setUp(() => bus = UserRefreshRequestBus());
  tearDown(() => bus.close());

  test('delivers one event per request', () async {
    var received = 0;
    bus.requests.listen((_) => received++);

    bus.requestUserRefresh();
    bus.requestUserRefresh();
    await Future<void>.delayed(Duration.zero);

    expect(received, 2);
  });

  test('a request without listeners is neither thrown nor buffered', () async {
    expect(bus.requestUserRefresh, returnsNormally);

    var received = 0;
    bus.requests.listen((_) => received++);
    await Future<void>.delayed(Duration.zero);

    expect(received, 0);
  });

  test('after close requests are ignored and the stream is done', () async {
    final done = bus.requests.isEmpty;

    await bus.close();

    expect(bus.requestUserRefresh, returnsNormally);
    expect(await done, isTrue);
  });
}
