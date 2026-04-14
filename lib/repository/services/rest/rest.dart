import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> fetchCloudinaryFolderUrls(String folder) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _restClient.dio.post(
        'uploadImage',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'] as String;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
