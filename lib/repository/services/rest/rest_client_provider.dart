import 'package:dio/dio.dart';

class RestClient {
  final Dio _dio;

  RestClient._internal(this._dio);

  static final RestClient _instance = RestClient._internal(
    Dio(
      BaseOptions(
        baseUrl: "http://192.168.0.13:3000/",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    ),
  );

  factory RestClient() => _instance;

  Dio get dio => _dio;
}
