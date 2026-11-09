import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_error_page.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../helpers/landscape.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

void main() {
  testWidgets(
    'shows the faded-pages line and goes back to the shelves from the bookmark (D-06)',
    (tester) async {
      var backs = 0;
      useLandscapePhone(tester);
      seedSvgCache([CloudinaryAssets.bookmarkRed]);
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: LibraryErrorPage(
              book: LibraryBook.bestiary,
              onBack: () => backs++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(LibraryErrorPage.errorLine), findsOneWidget);
      expect(
        LibraryErrorPage.errorLine,
        'Le pagine di questo libro sono sbiadite. Riprova più tardi.',
      );
      expect(find.byKey(LibraryErrorPage.errorKey), findsOneWidget);
      expect(find.text('Bestiario'), findsOneWidget);
      expect(find.byType(Placeholder), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CachedSvg &&
              widget.url == LibraryBook.bestiary.bookmarkUrl,
        ),
      );
      expect(backs, 1);
    },
  );
}
