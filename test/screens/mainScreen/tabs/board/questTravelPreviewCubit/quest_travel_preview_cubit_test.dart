import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/mocks.dart';

void main() {
  late MockTravelRepository repository;

  final preview = TravelPreview.fromJson(
    travelPreviewJson(food: [travelFoodItemJson()]),
  );
  final starving = TravelPreview.fromJson(
    travelPreviewJson(food: const [], hpLost: 20910, arrivesAlive: false),
  );

  setUp(() => repository = MockTravelRepository());

  QuestTravelPreviewCubit build() => QuestTravelPreviewCubit(repository);

  When<Future<TravelPreview?>> stubPreview() => when(
    () => repository.previewQuest(
      characterId: any(named: 'characterId'),
      questId: any(named: 'questId'),
    ),
  );

  void stubAnswers(List<Future<TravelPreview?> Function()> answers) {
    var call = 0;
    stubPreview().thenAnswer((_) => answers[call++]());
  }

  Future<void> loadQuest(QuestTravelPreviewCubit cubit) =>
      cubit.load(characterId: 'c-1', questId: 'q-1');

  test('starts idle (D-08)', () {
    expect(build().state, const QuestTravelPreviewIdle());
  });

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'loads the acceptance preview of the character and the quest (D-04, D-08)',
    setUp: () => stubPreview().thenAnswer((_) async => preview),
    build: build,
    act: loadQuest,
    expect: () => [
      const QuestTravelPreviewLoading(),
      QuestTravelPreviewLoaded(preview),
    ],
    verify: (_) => verify(
      () => repository.previewQuest(characterId: 'c-1', questId: 'q-1'),
    ).called(1),
  );

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'loads a null preview when the acceptance involves no travel (D-04)',
    setUp: () => stubPreview().thenAnswer((_) async => null),
    build: build,
    act: loadQuest,
    expect: () => const [
      QuestTravelPreviewLoading(),
      QuestTravelPreviewLoaded(null),
    ],
  );

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'fails silently on a travel failure (D-04)',
    setUp: () =>
        stubPreview().thenThrow(const TravelException(TravelFailure.forbidden)),
    build: build,
    act: loadQuest,
    expect: () => const [
      QuestTravelPreviewLoading(),
      QuestTravelPreviewFailed(TravelFailure.forbidden),
    ],
  );

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'fails as unknown on an unexpected error (D-04)',
    setUp: () => stubPreview().thenThrow(StateError('x')),
    build: build,
    act: loadQuest,
    expect: () => const [
      QuestTravelPreviewLoading(),
      QuestTravelPreviewFailed(TravelFailure.unknown),
    ],
  );

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'refresh asks the same character and quest again (D-05)',
    setUp: () => stubAnswers([() async => preview, () async => starving]),
    build: build,
    act: (cubit) async {
      await loadQuest(cubit);
      await cubit.refresh();
    },
    expect: () => [
      const QuestTravelPreviewLoading(),
      QuestTravelPreviewLoaded(preview),
      const QuestTravelPreviewLoading(),
      QuestTravelPreviewLoaded(starving),
    ],
    verify: (_) => verify(
      () => repository.previewQuest(characterId: 'c-1', questId: 'q-1'),
    ).called(2),
  );

  blocTest<QuestTravelPreviewCubit, QuestTravelPreviewState>(
    'refresh before any load does nothing (D-05)',
    build: build,
    act: (cubit) => cubit.refresh(),
    expect: () => const <QuestTravelPreviewState>[],
    verify: (_) => verifyNever(
      () => repository.previewQuest(
        characterId: any(named: 'characterId'),
        questId: any(named: 'questId'),
      ),
    ),
  );

  test('drops a superseded answer (D-08)', () async {
    final first = Completer<TravelPreview?>();
    stubAnswers([() => first.future, () async => starving]);
    final cubit = build();

    final loading = loadQuest(cubit);
    await cubit.refresh();
    first.complete(preview);
    await loading;

    expect(cubit.state, QuestTravelPreviewLoaded(starving));
    await cubit.close();
  });

  test('drops a late answer after close (D-08)', () async {
    final answer = Completer<TravelPreview?>();
    stubPreview().thenAnswer((_) => answer.future);
    final cubit = build();
    final states = <QuestTravelPreviewState>[];
    final subscription = cubit.stream.listen(states.add);

    final loading = loadQuest(cubit);
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    answer.complete(preview);
    await loading;

    expect(states, const [QuestTravelPreviewLoading()]);
    await subscription.cancel();
  });
}
