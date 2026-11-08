import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/cache/image_warmer.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';

String _url(String name) =>
    'https://res.cloudinary.com/x/image/upload/v1/image_warmer_test_$name.svg';

void main() {
  final seed = File(
    '${Directory.systemTemp.createTempSync('kg_warm').path}/seed.svg',
  )..writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg"/>');

  test(
    'downloads at most the configured number of files at a time (D-22)',
    () async {
      final pending = <Completer<File>>[];
      var inFlight = 0;
      var peak = 0;
      Future<File> fetch(String url) {
        inFlight++;
        peak = max(peak, inFlight);
        final download = Completer<File>();
        pending.add(download);
        return download.future.whenComplete(() => inFlight--);
      }

      final urls = [for (var i = 0; i < 5; i++) _url('bounded_$i')];
      final warming = ImageWarmer(fetch: fetch, concurrency: 2).warm(urls);
      await pumpEventQueue();

      expect(pending.length, 2);
      var completed = 0;
      while (completed < urls.length) {
        pending[completed++].complete(seed);
        await pumpEventQueue();
        expect(inFlight, lessThanOrEqualTo(2));
      }
      await warming;

      expect(peak, 2);
      expect(pending.length, urls.length);
      for (final url in urls) {
        expect(SvgCache().getFile(url), same(seed));
      }
    },
  );

  test('skips the urls already cached and the failures, records every fetched '
      'file (D-22)', () async {
    SvgCache().add(_url('cached'), seed);
    final fetched = <String>[];
    Future<File> fetch(String url) async {
      fetched.add(url);
      if (url == _url('broken')) throw const HttpException('400');
      return seed;
    }

    await ImageWarmer(
      fetch: fetch,
      concurrency: 3,
    ).warm([_url('cached'), _url('broken'), _url('fresh')]);

    expect(fetched, unorderedEquals([_url('broken'), _url('fresh')]));
    expect(SvgCache().getFile(_url('fresh')), same(seed));
    expect(SvgCache().getFile(_url('broken')), isNull);
    expect(SvgCache().getFile(_url('cached')), same(seed));
  });

  test('deduplicates the urls (D-22)', () async {
    var fetches = 0;
    Future<File> fetch(String url) async {
      fetches++;
      return seed;
    }

    await ImageWarmer(
      fetch: fetch,
    ).warm([_url('twin'), _url('twin'), _url('twin')]);

    expect(fetches, 1);
    expect(SvgCache().getFile(_url('twin')), same(seed));
  });

  test('downloads six files at a time by default (D-22)', () {
    expect(ImageWarmer(fetch: (_) async => seed).concurrency, 6);
  });
}
