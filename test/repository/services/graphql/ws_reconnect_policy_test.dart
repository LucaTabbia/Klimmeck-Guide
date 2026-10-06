import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

const _tokenExpired = 4401;
const _forbidden = 4403;
const _abnormalClosure = 1006;

void main() {
  late MockAuthTokenService mockService;
  late MockUnauthorizedRecovery mockRecovery;
  late DateTime current;

  setUp(() {
    mockService = MockAuthTokenService();
    mockRecovery = MockUnauthorizedRecovery();
    current = DateTime(2026, 10, 6, 12);
    when(() => mockService.getAccessToken()).thenAnswer((_) async => 'T1');
  });

  WsReconnectPolicy policyWith({bool withRecovery = true}) => WsReconnectPolicy(
    authService: mockService,
    recovery: withRecovery ? mockRecovery : null,
    now: () => current,
  );

  void recoveryAnswers(String? token) => when(
    () => mockRecovery.recoverFromUnauthorized(
      rejectedToken: any(named: 'rejectedToken'),
    ),
  ).thenAnswer((_) async => token);

  group('buildInitialPayload', () {
    test('sends the current token as a bearer authorization', () async {
      final payload = await policyWith().buildInitialPayload();

      expect(payload, {'Authorization': 'Bearer T1'});
    });

    test('reads the token again on every connect (no cache)', () async {
      final policy = policyWith();
      await policy.buildInitialPayload();
      when(() => mockService.getAccessToken()).thenAnswer((_) async => 'T2');

      final payload = await policy.buildInitialPayload();

      expect(payload, {'Authorization': 'Bearer T2'});
      verify(() => mockService.getAccessToken()).called(2);
    });

    test('returns an empty payload when there is no token', () async {
      when(() => mockService.getAccessToken()).thenAnswer((_) async => null);

      expect(await policyWith().buildInitialPayload(), isEmpty);
    });

    test('returns an empty payload when the token is empty', () async {
      when(() => mockService.getAccessToken()).thenAnswer((_) async => '');

      expect(await policyWith().buildInitialPayload(), isEmpty);
    });

    test('never throws when the token lookup fails', () async {
      when(
        () => mockService.getAccessToken(),
      ).thenAnswer((_) async => throw StateError('storage unavailable'));

      expect(await policyWith().buildInitialPayload(), isEmpty);
    });
  });

  group('onConnectionLost on auth rejection', () {
    test(
      '4401 recovers with the last sent token and reconnects quickly',
      () async {
        recoveryAnswers('T2');
        final policy = policyWith();
        await policy.buildInitialPayload();

        final delay = await policy.onConnectionLost(
          _tokenExpired,
          'Token expired',
        );

        expect(delay, WsReconnectPolicy.authRetryDelay);
        expect(delay, const Duration(milliseconds: 500));
        verify(
          () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'T1'),
        ).called(1);
      },
    );

    test('4403 recovers with the last sent token as well', () async {
      recoveryAnswers('T2');
      final policy = policyWith();
      await policy.buildInitialPayload();

      final delay = await policy.onConnectionLost(_forbidden, null);

      expect(delay, WsReconnectPolicy.authRetryDelay);
      verify(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'T1'),
      ).called(1);
    });

    test(
      'falls back to backoff when the session cannot be recovered',
      () async {
        recoveryAnswers(null);
        final policy = policyWith();
        await policy.buildInitialPayload();

        final delay = await policy.onConnectionLost(
          _tokenExpired,
          'Token expired',
        );

        expect(delay, const Duration(seconds: 1));
      },
    );

    test('falls back to backoff when the recovery throws', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      ).thenAnswer((_) async => throw StateError('network down'));
      final policy = policyWith();
      await policy.buildInitialPayload();

      final delay = await policy.onConnectionLost(_forbidden, null);

      expect(delay, const Duration(seconds: 1));
    });

    test('without a recovery uses backoff and never refreshes', () async {
      final policy = policyWith(withRecovery: false);
      await policy.buildInitialPayload();

      expect(
        await policy.onConnectionLost(_tokenExpired, 'Token expired'),
        const Duration(seconds: 1),
      );
      expect(
        await policy.onConnectionLost(_forbidden, null),
        const Duration(seconds: 2),
      );
      verifyZeroInteractions(mockRecovery);
    });

    test('repeated unrecoverable rejections grow up to the cap', () async {
      recoveryAnswers(null);
      final policy = policyWith();

      final delays = [
        for (var i = 0; i < 10; i++)
          await policy.onConnectionLost(_tokenExpired, 'Token expired'),
      ];

      expect(delays, _expectedBackoffSequence);
    });

    test(
      'repeated rejections right after a recovered token do not loop hot',
      () async {
        recoveryAnswers('T2');
        final policy = policyWith();

        final delays = [
          for (var i = 0; i < 4; i++)
            await policy.onConnectionLost(_forbidden, null),
        ];

        expect(delays, const [
          WsReconnectPolicy.authRetryDelay,
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
        ]);
      },
    );
  });

  group('onConnectionLost on other close codes', () {
    test('null or 1006 closes back off 1/2/4… and never above 60 s', () async {
      final policy = policyWith();

      final delays = [
        for (var i = 0; i < 10; i++)
          await policy.onConnectionLost(
            i.isEven ? null : _abnormalClosure,
            null,
          ),
      ];

      expect(delays, _expectedBackoffSequence);
      expect(
        delays.every((d) => d <= WsReconnectPolicy.maxReconnectDelay),
        isTrue,
      );
    });

    test('a connection stable for 30 s resets the backoff', () async {
      final policy = policyWith();
      await policy.onConnectionLost(_abnormalClosure, null);
      await policy.onConnectionLost(_abnormalClosure, null);
      await policy.buildInitialPayload();
      current = current.add(WsReconnectPolicy.stableConnection);

      final delay = await policy.onConnectionLost(_abnormalClosure, null);

      expect(delay, const Duration(seconds: 1));
    });

    test('a short-lived connection keeps the backoff growing', () async {
      final policy = policyWith();
      await policy.onConnectionLost(_abnormalClosure, null);
      await policy.buildInitialPayload();
      current = current.add(const Duration(seconds: 5));

      final delay = await policy.onConnectionLost(_abnormalClosure, null);

      expect(delay, const Duration(seconds: 2));
    });
  });
}

const _expectedBackoffSequence = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 16),
  Duration(seconds: 32),
  Duration(seconds: 60),
  Duration(seconds: 60),
  Duration(seconds: 60),
  Duration(seconds: 60),
];
