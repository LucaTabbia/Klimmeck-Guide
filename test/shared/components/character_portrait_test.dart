import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';

import '../../helpers/test_app.dart';

void main() {
  const silhouette = AssetImage('assets/images/placeholders/silhouette.jpeg');

  group('CharacterPortrait.resolve', () {
    test('falls back to the silhouette without any source', () {
      expect(CharacterPortrait.resolve(), silhouette);
    });

    test('falls back to the silhouette for a blank imagePath', () {
      expect(CharacterPortrait.resolve(imagePath: ''), silhouette);
    });

    test('prefers the local file over the remote imagePath', () {
      final provider = CharacterPortrait.resolve(
        imagePath: 'https://res.cloudinary.com/x.jpg',
        localFilePath: '/tmp/p.jpg',
      );

      expect(provider, isA<FileImage>());
      expect((provider as FileImage).file.path, '/tmp/p.jpg');
    });

    test('uses the cached network provider for a remote imagePath', () {
      final provider = CharacterPortrait.resolve(
        imagePath: 'https://res.cloudinary.com/x.jpg',
      );

      expect(provider, isA<CachedNetworkImageProvider>());
      expect(
        (provider as CachedNetworkImageProvider).url,
        'https://res.cloudinary.com/x.jpg',
      );
    });
  });

  group('CharacterPortrait widget', () {
    Future<Image> pumpPortrait(WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: const SizedBox(
            width: 120,
            height: 160,
            child: CharacterPortrait(),
          ),
        ),
      );
      await tester.pump();
      return tester.widget<Image>(find.byType(Image));
    }

    testWidgets('renders a covering, labelled image', (tester) async {
      final image = await pumpPortrait(tester);

      expect(image.image, silhouette);
      expect(image.fit, BoxFit.cover);
      expect(image.semanticLabel, 'Ritratto del personaggio');
      expect(image.errorBuilder, isNotNull);
    });

    testWidgets('shows the silhouette when the image fails to load', (
      tester,
    ) async {
      final image = await pumpPortrait(tester);
      late Widget fallback;
      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              fallback = image.errorBuilder!(context, Object(), null);
              return fallback;
            },
          ),
        ),
      );

      expect(fallback, isA<Image>());
      expect((fallback as Image).image, silhouette);
    });
  });
}
