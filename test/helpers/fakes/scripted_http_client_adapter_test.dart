import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth_fixtures.dart';
import 'scripted_http_client_adapter.dart';

Dio _dioWith(ScriptedHttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://localhost:3000/'))
      ..httpClientAdapter = adapter;

void main() {
  test('answers the scripted statuses in order and records requests', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(200),
      const ScriptedResponse.json(204),
    ]);
    final dio = _dioWith(adapter);

    final first = await dio.get<Object?>('a');
    final second = await dio.get<Object?>('b');

    expect(first.statusCode, 200);
    expect(second.statusCode, 204);
    expect(adapter.requests.map((r) => r.path), ['a', 'b']);
  });

  test('returns the scripted JSON body through a real Dio', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(201, {'url': 'https://x'}),
    ]);

    final response = await _dioWith(adapter).post<Map<String, dynamic>>('up');

    expect(response.data!['url'], 'https://x');
  });

  test('throws a DioException of the scripted failure type', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.failure(DioExceptionType.receiveTimeout),
    ]);

    expect(
      _dioWith(adapter).post<Object?>('up'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
  });

  test('buildTestUserWithCharacter owns a character', () {
    final user = buildTestUserWithCharacter();

    expect(user.id, testUserId);
    expect(user.currentCharacter?.id, testCharacterId);
  });
}
