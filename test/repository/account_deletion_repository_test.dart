import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/account_deletion_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes/fake_account_deletion_api.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(AccountDeletionFailure failure) => throwsA(
  isA<AccountDeletionException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late FakeAccountDeletionApi api;
  late MockSessionTerminator terminator;
  late AccountDeletionRepository repository;

  setUp(() {
    api = FakeAccountDeletionApi();
    terminator = MockSessionTerminator();
    when(() => terminator.terminateSession(any())).thenAnswer((_) async {});
    repository = AccountDeletionRepository(api: api, terminator: terminator);
  });

  setUpAll(() {
    registerFallbackValue(UnauthenticatedReason.signedOut);
  });

  group('deleteOwnAccount', () {
    test(
      'a successful deletion ends the session locally as accountDeleted (D-06)',
      () async {
        await repository.deleteOwnAccount();

        verify(
          () =>
              terminator.terminateSession(UnauthenticatedReason.accountDeleted),
        ).called(1);
      },
    );

    test(
      'the deletion is asked once and nothing else is called (D-06)',
      () async {
        await repository.deleteOwnAccount();

        expect(api.deleteMyAccountCalls, 1);
        expect(api.deletedTwitchLogins, isEmpty);
        verify(
          () =>
              terminator.terminateSession(UnauthenticatedReason.accountDeleted),
        ).called(1);
        verifyNoMoreInteractions(terminator);
      },
    );

    test(
      'a refused deletion keeps the session and throws its failure (D-06)',
      () async {
        api.error = operationExceptionWithCode('INNKEEPER_ACCOUNT_PROTECTED');

        await expectLater(
          repository.deleteOwnAccount(),
          _failsWith(AccountDeletionFailure.innkeeperProtected),
        );
        verifyNever(() => terminator.terminateSession(any()));
      },
    );

    test('a malformed answer is unknown', () async {
      api.error = const FormatException('bad payload');

      await expectLater(
        repository.deleteOwnAccount(),
        _failsWith(AccountDeletionFailure.unknown),
      );
      verifyNever(() => terminator.terminateSession(any()));
    });
  });
}
