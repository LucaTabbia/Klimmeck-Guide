import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';

import 'sync_event_fixtures.dart';

void main() {
  group('userJson', () {
    test('builds a User with the given points, role and character', () {
      final user = User.fromJson(
        userJson(twitchPoints: 42, role: 'innkeeper', characterId: 'c9'),
      );

      expect(user.twitchPoints, 42);
      expect(user.role, RoleType.innkeeper);
      expect(user.currentCharacter?.id, 'c9');
    });

    test('has no current character by default', () {
      expect(User.fromJson(userJson()).currentCharacter, isNull);
    });
  });

  test('characterJson builds a Character with life points and gold', () {
    final character = Character.fromJson(
      characterJson(id: 'c1', currentLifePoints: 7, gold: 3),
    );

    expect(character.id, 'c1');
    expect(character.status?.currentLifePoints, 7);
    expect(character.status?.coins?.gold, 3);
  });

  test('errorCodeResponse carries only the extensions code', () {
    final response = errorCodeResponse('FORBIDDEN');

    expect(response.errors!.single.extensions!['code'], 'FORBIDDEN');
    expect(response.data, isNull);
  });

  test('dataResponse exposes the data map', () {
    expect(dataResponse({'a': 1}).data, {'a': 1});
  });

  test('malformedUserResponse cannot be parsed into a User', () {
    final data = malformedUserResponse().data!;

    expect(
      () => User.fromJson(data['userUpdated'] as Map<String, dynamic>),
      throwsA(isA<TypeError>()),
    );
  });
}
