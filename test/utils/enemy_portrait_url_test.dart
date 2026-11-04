import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/utils/enemy_portrait_url.dart';

void main() {
  group('enemyPortraitUrl', () {
    test('null, empty and blank paths resolve to nothing (D-03)', () {
      expect(enemyPortraitUrl(null), isNull);
      expect(enemyPortraitUrl(''), isNull);
      expect(enemyPortraitUrl('   '), isNull);
    });

    test('an https URL with a host is used as is (D-03)', () {
      const url =
          'https://res.cloudinary.com/dzuhywp53/image/upload/v1/goblin.png';
      expect(enemyPortraitUrl(url), url);
    });

    test('a Cloudinary-relative v<n>/ path goes through CloudinaryAssets.url '
        '(D-03)', () {
      expect(
        enemyPortraitUrl('v1757660751/goblin_abc.png'),
        CloudinaryAssets.url('v1757660751/goblin_abc.png'),
      );
    });

    test('the DB placeholders assets/images/<slug>.png stay hidden (D-03)', () {
      expect(enemyPortraitUrl('assets/images/goblin.png'), isNull);
      expect(enemyPortraitUrl('assets/images/arbustoMaligno.png'), isNull);
    });

    test('other relative paths stay hidden (D-03)', () {
      expect(enemyPortraitUrl('enemies/wolf.png'), isNull);
      expect(enemyPortraitUrl('v1/'), isNull);
    });

    test('http, file and data URLs stay hidden (D-03)', () {
      expect(enemyPortraitUrl('http://example.com/a.png'), isNull);
      expect(enemyPortraitUrl('file:///a.png'), isNull);
      expect(enemyPortraitUrl('data:image/png;base64,AAAA'), isNull);
      expect(enemyPortraitUrl('https:///nohost.png'), isNull);
    });

    test('surrounding spaces are trimmed (D-03)', () {
      expect(
        enemyPortraitUrl('  v1/goblin.svg '),
        CloudinaryAssets.url('v1/goblin.svg'),
      );
    });
  });
}
