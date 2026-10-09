import 'dart:io';

import 'package:dio/dio.dart';
import 'package:klimmeck_guide/repository/services/rest/image_upload_exception.dart';
import 'package:klimmeck_guide/repository/services/rest/rest_client_provider.dart';

/// Servizio REST dell'app. Riceve il `RestClient` via DI costruttore.
///
/// Il singleton statico di `RestClient` è stato rimosso: l'istanza è
/// fornita da `main.dart` dopo la costruzione dell'`AuthTokenService`,
/// garantendo che ogni request HTTP porti l'header `Authorization`.
class KlimmeckRest {
  KlimmeckRest(this._restClient);

  final RestClient _restClient;

  Future<List<String>> fetchCloudinarySubfoldersUrls(String folder) async {
    final response = await _restClient.dio.post(
      'cloudinary/getSubfoldersUrls',
      data: {'folder': folder},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['urls'] as List<dynamic>;
      return data.cast<String>();
    } else {
      throw Exception(
        'Failed to fetch Cloudinary URLs: ${response.statusCode}',
      );
    }
  }

  Future<List<String>> fetchCloudinaryFolderUrls(String folder) async {
    final response = await _restClient.dio.post(
      'cloudinary/getUrls',
      data: {'folder': folder},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['urls'] as List<dynamic>;
      return data.cast<String>();
    } else {
      throw Exception(
        'Failed to fetch Cloudinary URLs: ${response.statusCode}',
      );
    }
  }

  /// Timeout dedicato: il backend inoltra il file a Cloudinary prima di rispondere.
  static const Duration uploadTimeout = Duration(seconds: 30);

  /// Carica un'immagine su `POST /cloudinary/uploadImage` e restituisce l'URL.
  /// Lancia [DioException] (rete, non-2xx, timeout) o [ImageUploadException].
  Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await _restClient.dio.post<Map<String, dynamic>>(
      'cloudinary/uploadImage',
      data: formData,
      options: Options(
        sendTimeout: uploadTimeout,
        receiveTimeout: uploadTimeout,
      ),
    );
    final url = response.data?['url'];
    if (url is! String || url.isEmpty) throw const ImageUploadException();
    return url;
  }
}
