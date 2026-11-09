import 'dart:io';

import 'package:klimmeck_guide/utils/app_log.dart';

import 'svg_cache.dart';
import 'svg_cache_manager.dart';

/// Riscalda la cache degli SVG (disco + [SvgCache]) scaricando gli url non
/// ancora in memoria, al più [concurrency] alla volta; un url che fallisce
/// viene saltato, gli altri arrivano comunque (Phase 17 D-22).
class ImageWarmer {
  ImageWarmer({
    Future<File> Function(String url)? fetch,
    SvgCache? cache,
    this.concurrency = defaultConcurrency,
  }) : assert(concurrency > 0),
       _fetch = fetch,
       _cache = cache ?? SvgCache();

  static const int defaultConcurrency = 6;

  final int concurrency;
  final Future<File> Function(String url)? _fetch;
  final SvgCache _cache;
  late final SvgCacheManager _manager = SvgCacheManager();

  Future<void> warm(Iterable<String> urls) async {
    final pending = urls
        .where((url) => _cache.getFile(url) == null)
        .toSet()
        .iterator;
    await Future.wait([for (var i = 0; i < concurrency; i++) _drain(pending)]);
  }

  Future<void> _drain(Iterator<String> pending) async {
    while (pending.moveNext()) {
      final url = pending.current;
      try {
        _cache.add(url, await _download(url));
      } catch (error) {
        appLog('[ImageWarmer] skipped ${error.runtimeType}');
      }
    }
  }

  Future<File> _download(String url) {
    final fetch = _fetch;
    return fetch == null ? _manager.getSingleFile(url) : fetch(url);
  }
}
