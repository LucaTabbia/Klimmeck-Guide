import 'dart:io';

class SvgCache {
  static final SvgCache _instance = SvgCache._internal();
  factory SvgCache() => _instance;
  SvgCache._internal();

  final Map<String, File> cachedFiles = {};

  File? getFile(String url) => cachedFiles[url];

  void add(String url, File file) {
    cachedFiles[url] = file;
  }
}
