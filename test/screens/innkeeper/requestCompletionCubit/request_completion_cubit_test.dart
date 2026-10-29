import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/mocks.dart';

const String _bea = 'char-bea';
const String _cosimo = 'char-cosimo';

final Character _beaCharacter = Character.fromJson(
  participantCharacterJson(id: _bea, name: 'Bea'),
);
final Character _cosimoCharacter = Character.fromJson(
  participantCharacterJson(id: _cosimo, name: 'Cosimo'),
);

final RequestCard _card = requestCardsOf(
  worldMissionEntriesJson().map(PendingRequest.fromJson).toList(),
).single;

final ParticipantDraft _beaDraft = ParticipantDraft.from(
  _beaCharacter,
  fallbackName: 'Bea',
);
final ParticipantDraft _cosimoDraft = ParticipantDraft.from(
  _cosimoCharacter,
  fallbackName: 'Cosimo',
);

final RequestCompletionEditing _editing = RequestCompletionEditing(
  drafts: [_beaDraft, _cosimoDraft],
);

RequestCompletionEditing _withBea(ParticipantDraft bea) =>
    RequestCompletionEditing(drafts: [bea, _cosimoDraft]);

void main() {
  late MockInnkeeperRepository repository;

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.readCharacter(_bea),
    ).thenAnswer((_) async => _beaCharacter);
    when(
      () => repository.readCharacter(_cosimo),
    ).thenAnswer((_) async => _cosimoCharacter);
  });

  RequestCompletionCubit build() =>
      RequestCompletionCubit(repository: repository, card: _card);

  test('starts loading', () {
    expect(build().state, const RequestCompletionLoading());
  });

  group('load', () {
    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'reads every participant and opens the form in card order',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [_editing],
      verify: (_) {
        verify(() => repository.readCharacter(_bea)).called(1);
        verify(() => repository.readCharacter(_cosimo)).called(1);
      },
    );

    test('reads the participants in parallel', () async {
      final beaRead = Completer<Character>();
      final cosimoRead = Completer<Character>();
      when(
        () => repository.readCharacter(_bea),
      ).thenAnswer((_) => beaRead.future);
      when(
        () => repository.readCharacter(_cosimo),
      ).thenAnswer((_) => cosimoRead.future);
      final cubit = build();

      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.readCharacter(_bea)).called(1);
      verify(() => repository.readCharacter(_cosimo)).called(1);
      beaRead.complete(_beaCharacter);
      cosimoRead.complete(_cosimoCharacter);
      await loading;
      expect(cubit.state, _editing);
      await cubit.close();
    });

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'a failing read ends in a load failure with its code',
      build: build,
      setUp: () => when(
        () => repository.readCharacter(_cosimo),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const RequestCompletionLoadFailed(failure: InnkeeperFailure.connection),
      ],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'a retry after a failure loads again and opens the form',
      build: build,
      seed: () => const RequestCompletionLoadFailed(
        failure: InnkeeperFailure.connection,
      ),
      act: (cubit) => cubit.load(),
      expect: () => [const RequestCompletionLoading(), _editing],
    );
  });

  group('edits', () {
    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'setHp changes only that participant',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.setHp(_bea, 5),
      expect: () => [_withBea(_beaDraft.withHp(5))],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'setHp is clamped by the draft',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.setHp(_bea, 0),
      expect: () => [_withBea(_beaDraft.withHp(1))],
      verify: (cubit) => expect(
        (cubit.state as RequestCompletionEditing).drafts.first.hpAfter,
        1,
      ),
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'toggleInjury adds a new injury',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.toggleInjury(_bea, InjuryType.brokenLeftArm),
      expect: () => [
        _withBea(_beaDraft.withInjuryToggled(InjuryType.brokenLeftArm)),
      ],
      verify: (cubit) => expect(
        (cubit.state as RequestCompletionEditing).drafts.first.addedInjuries,
        [InjuryType.brokenLeftArm],
      ),
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'setConsumableUsed marks a used consumable',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.setConsumableUsed(_bea, potionItemId, 2),
      expect: () => [_withBea(_beaDraft.withConsumableUsed(potionItemId, 2))],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'setSpellUsed marks a used spell',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.setSpellUsed(_bea, fireballSpellId, 1),
      expect: () => [_withBea(_beaDraft.withSpellUsed(fireballSpellId, 1))],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'an unknown participant emits nothing',
      build: build,
      seed: () => _editing,
      act: (cubit) => cubit.setHp('char-nobody', 5),
      expect: () => <RequestCompletionState>[],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'an edit clears the previous failure',
      build: build,
      seed: () => RequestCompletionEditing(
        drafts: [_beaDraft, _cosimoDraft],
        failure: InnkeeperFailure.overrideInvalid,
        failureSerial: 1,
      ),
      act: (cubit) => cubit.setHp(_bea, 5),
      expect: () => [
        RequestCompletionEditing(
          drafts: [_beaDraft.withHp(5), _cosimoDraft],
          failureSerial: 1,
        ),
      ],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'edits while loading are ignored',
      build: build,
      act: (cubit) => cubit.setHp(_bea, 5),
      expect: () => <RequestCompletionState>[],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'edits after a load failure are ignored',
      build: build,
      seed: () => const RequestCompletionLoadFailed(
        failure: InnkeeperFailure.connection,
      ),
      act: (cubit) => cubit.toggleInjury(_bea, InjuryType.brokenLeftArm),
      expect: () => <RequestCompletionState>[],
    );

    blocTest<RequestCompletionCubit, RequestCompletionState>(
      'edits while submitting are ignored',
      build: build,
      seed: () => RequestCompletionEditing(
        drafts: [_beaDraft, _cosimoDraft],
        isSubmitting: true,
      ),
      act: (cubit) => cubit.setSpellUsed(_bea, fireballSpellId, 1),
      expect: () => <RequestCompletionState>[],
    );
  });

  test('overrides are the changed participants only', () {
    final edited = _withBea(_beaDraft.withHp(5));

    expect(_editing.overrides, isEmpty);
    expect(edited.overrides, overridesOf(edited.drafts));
    expect(edited.overrides.single.characterId, _bea);
  });
}
