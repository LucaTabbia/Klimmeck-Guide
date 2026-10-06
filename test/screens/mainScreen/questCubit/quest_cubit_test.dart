import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockKlimmeckGraphQl api;

  setUp(() => api = MockKlimmeckGraphQl());

  group('QuestCubit closed by a logout while a request is pending', () {
    test('a late response is ignored without errors', () async {
      final pendingQuests = Completer<List<Quest>>();
      when(() => api.getQuests()).thenAnswer((_) => pendingQuests.future);
      final cubit = QuestCubit(api);
      final load = cubit.loadQuest();

      await cubit.close();
      pendingQuests.complete(const <Quest>[]);

      await expectLater(load, completes);
      expect(cubit.state, isA<QuestLoading>());
    });

    test('a late failure is ignored without errors', () async {
      final pendingQuests = Completer<List<Quest>>();
      when(() => api.getQuests()).thenAnswer((_) => pendingQuests.future);
      final cubit = QuestCubit(api);
      final load = cubit.loadQuest();

      await cubit.close();
      pendingQuests.completeError(Exception('UNAUTHENTICATED'));

      await expectLater(load, completes);
      expect(cubit.state, isA<QuestLoading>());
    });
  });
}
