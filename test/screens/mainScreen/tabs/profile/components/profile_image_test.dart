import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/profile/components/profile_image.dart';
import 'package:klimmeck_guide/shared/components/character_portrait.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  const url = 'https://res.cloudinary.com/x.jpg';

  Future<void> pumpProfileImage(
    WidgetTester tester, {
    String? imagePath,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Center(child: ProfileImage(imagePath: imagePath)),
      ),
    );
    await tester.pump();
  }

  Image resolvedImage(WidgetTester tester) => tester.widget<Image>(
    find
        .descendant(
          of: find.byType(CharacterPortrait),
          matching: find.byType(Image),
        )
        .first,
  );

  testWidgets('shows the silhouette through the portrait without imagePath', (
    tester,
  ) async {
    await pumpProfileImage(tester);

    final portrait = tester.widget<CharacterPortrait>(
      find.byType(CharacterPortrait),
    );
    expect(portrait.imagePath, isNull);
    final image = resolvedImage(tester).image;
    expect(image, isA<AssetImage>());
    expect((image as AssetImage).assetName, CharacterPortrait.silhouetteAsset);
  });

  testWidgets('shows the remote portrait for the given imagePath', (
    tester,
  ) async {
    await pumpProfileImage(tester, imagePath: url);

    final portrait = tester.widget<CharacterPortrait>(
      find.byType(CharacterPortrait),
    );
    expect(portrait.imagePath, url);
    final image = resolvedImage(tester).image;
    expect(image, isA<CachedNetworkImageProvider>());
    expect((image as CachedNetworkImageProvider).url, url);
  });

  testWidgets('keeps the 200x200 clipped frame around the portrait', (
    tester,
  ) async {
    await pumpProfileImage(tester);

    final frame = find
        .ancestor(
          of: find.byType(CharacterPortrait),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.getSize(frame), const Size(200, 200));
    expect(tester.widget<Container>(frame).clipBehavior, Clip.hardEdge);
  });
}
