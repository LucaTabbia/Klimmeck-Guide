import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

void main() {
  setUp(() {
    seedSvgCache([
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.bookmarkRed,
    ]);
  });

  Future<void> pump(WidgetTester tester, Pet pet, {bool? isMarked}) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Center(
            child: CompanionCard(pet: pet, size: 120, isMarked: isMarked),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the name and the speed of a riding companion (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(petJson()));

    expect(find.text('Cavallo da viaggio'), findsOneWidget);
    expect(find.text('Velocità ×2'), findsOneWidget);
    expect(find.byType(CoinsDisplay), findsNothing);
    expect(find.byType(CardBookmark), findsNothing);
  });

  testWidgets('shows only the name of a companion without speed (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(catPetJson()));

    expect(find.text('Gatto di bottega'), findsOneWidget);
    expect(find.textContaining('Velocità'), findsNothing);
  });

  testWidgets('carries the bookmark when asked to mark the card (D-17)', (
    tester,
  ) async {
    await pump(tester, Pet.fromJson(petJson()), isMarked: true);

    final bookmark = tester.widget<CardBookmark>(find.byType(CardBookmark));
    expect(bookmark.isMarked, isTrue);
  });
}
