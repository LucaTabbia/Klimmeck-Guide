import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klimmeck_guide/bootstrap/app_bootstrap.dart';
import 'package:klimmeck_guide/bootstrap/insecure_transport_screen.dart';
import 'package:klimmeck_guide/config/env_config.dart';

const Map<String, String> _cleartextUrls = {
  'BASE_URL': 'http://h/',
  'GRAPHQL_HTTP_URL': 'http://h/api/graphql',
  'GRAPHQL_WS_URL': 'ws://h/api/graphql',
};

const Map<String, String> _secureUrls = {
  'BASE_URL': 'https://h/',
  'GRAPHQL_HTTP_URL': 'https://h/api/graphql',
  'GRAPHQL_WS_URL': 'wss://h/api/graphql',
};

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(EnvConfig.resetRuntimeOverrides);

  group('InsecureTransportScreen', () {
    testWidgets(
      'shows the insecure transport message centred with no button (D-03, D-19)',
      (tester) async {
        await tester.pumpWidget(const InsecureTransportScreen());

        final message = find.text(insecureTransportMessage);
        expect(message, findsOneWidget);
        expect(
          find.ancestor(of: message, matching: find.byType(Center)),
          findsWidgets,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ButtonStyleButton ||
                widget is IconButton ||
                widget is GestureDetector && widget.onTap != null,
          ),
          findsNothing,
        );
        expect(find.byType(AppBar), findsNothing);
      },
    );

    test('the message is the fixed copy (D-19)', () {
      expect(
        insecureTransportMessage,
        'Questa versione dell\'app non può collegarsi al server in modo sicuro. '
        'Installa una versione aggiornata.',
      );
    });
  });

  group('secureTransportBlocker', () {
    test('release with a cleartext URL is blocked by the screen (D-03)', () {
      EnvConfig.installRuntimeOverrides(_cleartextUrls);

      expect(
        secureTransportBlocker(isRelease: true),
        isA<InsecureTransportScreen>(),
      );
    });

    test('release with TLS URLs is not blocked (D-03)', () {
      EnvConfig.installRuntimeOverrides(_secureUrls);

      expect(secureTransportBlocker(isRelease: true), isNull);
    });

    test('debug with cleartext URLs is not blocked (D-03)', () {
      EnvConfig.installRuntimeOverrides(_cleartextUrls);

      expect(secureTransportBlocker(isRelease: false), isNull);
    });
  });
}
