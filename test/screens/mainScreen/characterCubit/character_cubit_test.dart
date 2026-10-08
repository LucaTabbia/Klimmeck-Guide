import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class _FakeCharacter extends Fake implements Character {}

void main() {
  late MockKlimmeckGraphQl api;

  setUp(() => api = MockKlimmeckGraphQl());

  group('CharacterCubit closed by a logout while loading', () {
    test('never opens the character subscription afterwards', () async {
      final pendingCharacter = Completer<Character>();
      when(
        () => api.getCharacter('c1'),
      ).thenAnswer((_) => pendingCharacter.future);
      when(
        () => api.subscribeToCharacter(any()),
      ).thenAnswer((_) => const Stream<Character>.empty());
      final cubit = CharacterCubit(api);
      final load = cubit.loadCharacter('c1');

      await cubit.close();
      pendingCharacter.complete(_FakeCharacter());

      await expectLater(load, completes);
      verifyNever(() => api.subscribeToCharacter(any()));
    });

    test('an open subscription is cancelled on close', () async {
      final updates = StreamController<Character>();
      when(
        () => api.getCharacter('c1'),
      ).thenAnswer((_) async => _FakeCharacter());
      when(
        () => api.subscribeToCharacter('c1'),
      ).thenAnswer((_) => updates.stream);
      final cubit = CharacterCubit(api);
      await cubit.loadCharacter('c1');
      expect(updates.hasListener, isTrue);

      await cubit.close();

      expect(updates.hasListener, isFalse);
      await updates.close();
    });
  });
}
