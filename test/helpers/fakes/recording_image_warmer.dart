import 'dart:async';
import 'dart:io';

import 'package:klimmeck_guide/repository/cache/image_warmer.dart';

/// Riscaldatore che registra gli url ricevuti invece di scaricarli.
///
/// `holds[n]` tiene in sospeso la n-esima chiamata finché il test non la
/// completa; da [throwFromCall] in poi ogni chiamata fallisce.
class RecordingImageWarmer extends ImageWarmer {
  RecordingImageWarmer({this.throwFromCall, this.progressReports = const []})
    : super(fetch: _neverDownloads);

  /// Avanzamenti `(fatti, totale)` riferiti durante la prima chiamata.
  final List<(int, int)> progressReports;

  final List<List<String>> calls = [];
  final Map<int, Completer<void>> holds = {};
  final int? throwFromCall;

  static Future<File> _neverDownloads(String url) =>
      throw StateError('RecordingImageWarmer never downloads');

  @override
  Future<void> warm(Iterable<String> urls, {WarmProgress? onProgress}) async {
    calls.add(List.unmodifiable(urls));
    final call = calls.length;
    if (call == 1) {
      for (final (done, total) in progressReports) {
        onProgress?.call(done, total);
      }
    }
    if (throwFromCall != null && call >= throwFromCall!) {
      throw StateError('warm-up failed');
    }
    final hold = holds[call];
    if (hold != null) await hold.future;
  }
}
