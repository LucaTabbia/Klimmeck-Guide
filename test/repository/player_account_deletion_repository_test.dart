import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_repository.dart';

import '../helpers/fakes/fake_account_deletion_api.dart';

Matcher _failsWith(PlayerAccountDeletionFailure failure) => throwsA(
  isA<PlayerAccountDeletionException>().having(
    (e) => e.failure,
    'failure',
    failure,
  ),
);

void main() {
  late FakeAccountDeletionApi api;
  late PlayerAccountDeletionRepository repository;

  setUp(() {
    api = FakeAccountDeletionApi();
    repository = PlayerAccountDeletionRepository(api: api);
  });

  group('deletePlayerAccount', () {
    test('asks the deletion of the given Twitch login once (D-15)', () async {
      await repository.deletePlayerAccount('rossa_k');

      expect(api.deletedTwitchLogins, ['rossa_k']);
    });

    test('a refusal throws its failure', () async {
      api.error = operationExceptionWithCode('TWITCH_USER_NOT_FOUND');

      await expectLater(
        repository.deletePlayerAccount('rossa_k'),
        _failsWith(PlayerAccountDeletionFailure.twitchUserNotFound),
      );
    });

    test('a malformed answer is unknown', () async {
      api.error = const FormatException('bad payload');

      await expectLater(
        repository.deletePlayerAccount('rossa_k'),
        _failsWith(PlayerAccountDeletionFailure.unknown),
      );
    });

    test('never calls deleteMyAccount', () async {
      await repository.deletePlayerAccount('rossa_k');

      expect(api.deleteMyAccountCalls, 0);
    });
  });
}
