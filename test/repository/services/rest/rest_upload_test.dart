import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/rest/image_upload_exception.dart';
import 'package:klimmeck_guide/repository/services/rest/rest.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/scripted_http_client_adapter.dart';
import '../../../helpers/mocks.dart';

void main() {
  late File file;

  setUp(() {
    dotenv.loadFromString(envString: 'BASE_URL=http://localhost:3000/');
    final dir = Directory.systemTemp.createTempSync('upload_test');
    file = File('${dir.path}/portrait.jpg')..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  KlimmeckRest buildRest(ScriptedHttpClientAdapter adapter) {
    final service = MockAuthTokenService();
    when(() => service.getAccessToken()).thenAnswer((_) async => 'token-abc');
    final client = RestClient(authTokenService: service);
    client.dio.httpClientAdapter = adapter;
    return KlimmeckRest(client);
  }

  test(
    'posts the file to cloudinary/uploadImage with bearer and timeouts',
    () async {
      final adapter = ScriptedHttpClientAdapter([
        const ScriptedResponse.json(201, {
          'url': 'https://res.cloudinary.com/x.jpg',
        }),
      ]);

      final url = await buildRest(adapter).uploadImage(file);

      expect(url, 'https://res.cloudinary.com/x.jpg');
      final options = adapter.requests.single;
      expect(options.path, 'cloudinary/uploadImage');
      expect(options.headers['Authorization'], 'Bearer token-abc');
      expect(options.sendTimeout, const Duration(seconds: 30));
      expect(options.receiveTimeout, const Duration(seconds: 30));
      final part = (options.data as FormData).files.single;
      expect(part.key, 'file');
      expect(part.value.filename, 'portrait.jpg');
    },
  );

  test('accepts a 200 with url', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(200, {
        'url': 'https://res.cloudinary.com/y.jpg',
      }),
    ]);

    expect(
      await buildRest(adapter).uploadImage(file),
      'https://res.cloudinary.com/y.jpg',
    );
  });

  test('throws ImageUploadException on a 2xx failure body', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(201, {
        'message': 'Upload failed',
        'error': {},
      }),
    ]);

    expect(
      buildRest(adapter).uploadImage(file),
      throwsA(isA<ImageUploadException>()),
    );
  });

  test('throws ImageUploadException on an empty url', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(201, {'url': ''}),
    ]);

    expect(
      buildRest(adapter).uploadImage(file),
      throwsA(isA<ImageUploadException>()),
    );
  });

  test('throws DioException on a 500', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.json(500),
    ]);

    expect(
      buildRest(adapter).uploadImage(file),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('throws DioException on a receive timeout', () async {
    final adapter = ScriptedHttpClientAdapter([
      const ScriptedResponse.failure(DioExceptionType.receiveTimeout),
    ]);

    expect(
      buildRest(adapter).uploadImage(file),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );
  });
}
