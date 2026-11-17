import 'dart:io';

import 'package:klimmeck_guide/utils/app_log.dart';

import 'svg_cache.dart';
import 'svg_cache_manager.dart';

/// Avanzamento di un riscaldamento: url conclusi sul totale da scaricare.
typedef WarmProgress = void Function(int done, int total);

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

  /// [onProgress] riceve, dopo ogni url concluso (anche se fallito), quanti
  /// sono fatti sul totale da scaricare.
  Future<void> warm(Iterable<String> urls, {WarmProgress? onProgress}) async {
    final pending = urls.where((url) => _cache.getFile(url) == null).toSet();
    var done = 0;
    void reportOneDone() => onProgress?.call(++done, pending.length);
    final queue = pending.iterator;
    await Future.wait([
      for (var i = 0; i < concurrency; i++) _drain(queue, reportOneDone),
    ]);
  }

  Future<void> _drain(Iterator<String> queue, void Function() onDone) async {
    while (queue.moveNext()) {
      final url = queue.current;
      try {
        _cache.add(url, await _download(url));
      } catch (error) {
        appLog('[ImageWarmer] skipped ${error.runtimeType}');
      }
      onDone();
    }
  }

  Future<File> _download(String url) {
    final fetch = _fetch;
    return fetch == null ? _manager.imageFile(url) : fetch(url);
  }
}
