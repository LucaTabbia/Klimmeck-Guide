import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/quest_board_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures/quest_fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockKlimmeckGraphQl graphQl;
  late QuestBoardRepository repository;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = QuestBoardRepository(graphQl: graphQl);
  });

  test('getQuests returns what the service returns', () async {
    final quests = [buildQuest(id: 'a')];
    when(() => graphQl.getQuests()).thenAnswer((_) async => quests);

    expect(await repository.getQuests(), quests);
    verify(() => graphQl.getQuests()).called(1);
  });

  test('getQuests rethrows the service error', () async {
    when(
      () => graphQl.getQuests(),
    ).thenAnswer((_) async => throw Exception('boom'));

    await expectLater(repository.getQuests(), throwsA(isA<Exception>()));
  });

  test('getCityPointIds delegates with the same city id', () async {
    when(
      () => graphQl.getCityPointIds('city-1'),
    ).thenAnswer((_) async => {'p-1'});

    expect(await repository.getCityPointIds('city-1'), {'p-1'});
    verify(() => graphQl.getCityPointIds('city-1')).called(1);
  });
}
