import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/shared/components/kg_notification_banner.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../helpers/landscape.dart';
import '../../helpers/test_app.dart';

void main() {
  const travelEnd = KGNotification(
    title: 'Viaggio completato',
    description: 'Il tuo personaggio è arrivato a destinazione.',
  );

  late int taps;

  setUp(() => taps = 0);

  Future<void> pumpBanner(
    WidgetTester tester, {
    KGNotification notification = travelEnd,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Material(
          child: Align(
            alignment: Alignment.topCenter,
            child: KgNotificationBanner(
              notification: notification,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
  }

  Finder inBanner(Finder matching) => find.descendant(
    of: find.byType(KgNotificationBanner),
    matching: matching,
  );

  testWidgets('renders the title and the description', (tester) async {
    await pumpBanner(tester);

    expect(find.text('Viaggio completato'), findsOneWidget);
    expect(
      find.text('Il tuo personaggio è arrivato a destinazione.'),
      findsOneWidget,
    );
  });

  testWidgets('reports a tap anywhere on the strip once', (tester) async {
    await pumpBanner(tester);

    await tester.tap(find.byType(KgNotificationBanner));

    expect(taps, 1);
  });

  testWidgets('is a thin strip with a comfortable tap target', (tester) async {
    await pumpBanner(tester);

    final size = tester.getSize(find.byType(KgNotificationBanner));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, lessThanOrEqualTo(480));
  });

  testWidgets('uses no app chrome', (tester) async {
    await pumpBanner(tester);

    expect(inBanner(find.byType(SnackBar)), findsNothing);
    expect(inBanner(find.byType(MaterialBanner)), findsNothing);
    expect(inBanner(find.byType(Scaffold)), findsNothing);
  });

  testWidgets('exposes a button labelled with the title', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBanner(tester);

    final node = tester.getSemantics(find.byType(KgNotificationBanner));
    expect(node, containsSemantics(isButton: true, hasTapAction: true));
    expect(node.label, contains('Viaggio completato'));
    semantics.dispose();
  });

  testWidgets('is drawn on parchment with a bronze border', (tester) async {
    await pumpBanner(tester);

    final decoration =
        tester.widget<Ink>(inBanner(find.byType(Ink))).decoration!
            as BoxDecoration;
    expect(decoration.color, KlimmeckGuideTheme.parchment);
    expect(decoration.border, Border.all(color: KlimmeckGuideTheme.darkBronze));
  });

  testWidgets('ellipsises a long description to two lines', (tester) async {
    final long = 'Una descrizione molto lunga del viaggio. ' * 20;
    await pumpBanner(
      tester,
      notification: KGNotification(
        title: 'Viaggio completato',
        description: long,
      ),
    );

    expect(tester.takeException(), isNull);
    final description = tester.widget<Text>(find.text(long));
    expect(description.maxLines, 2);
    expect(description.overflow, TextOverflow.ellipsis);
  });
}
