import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/character_status.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

Map<String, dynamic> statusJson({Object? activeTravel}) => {
  'title': 'rookie',
  'xp': 1,
  'location': {'id': 'city-marker-1', 'location': departureWire},
  'activeTravel': activeTravel,
};

void main() {
  test('parses activeTravel', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    expect(status.activeTravel, ActiveTravel.fromJson(activeTravelJson()));
  });

  test('a missing activeTravel is null', () {
    final json = statusJson()..remove('activeTravel');
    expect(CharacterStatus.fromJson(json).activeTravel, isNull);
  });

  test('a null activeTravel is null', () {
    expect(CharacterStatus.fromJson(statusJson()).activeTravel, isNull);
  });

  test('a malformed activeTravel is null and the status still parses', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: {'startTime': 'x'}),
    );
    expect(status.activeTravel, isNull);
    expect(status.location!.id, 'city-marker-1');
    expect(status.title, TitleType.rookie);
  });

  test('toJson emits activeTravel and round trips', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    expect(
      ActiveTravel.fromJson(
        status.toJson()['activeTravel'] as Map<String, dynamic>,
      ),
      status.activeTravel,
    );
    expect(
      CharacterStatus.fromJson(statusJson()).toJson()['activeTravel'],
      isNull,
    );
  });

  test('props include activeTravel', () {
    expect(
      CharacterStatus.fromJson(statusJson(activeTravel: activeTravelJson())) ==
          CharacterStatus.fromJson(statusJson()),
      isFalse,
    );
  });

  test('copyWith keeps the current activeTravel (Pitfall 6)', () {
    final status = CharacterStatus.fromJson(
      statusJson(activeTravel: activeTravelJson()),
    );
    final copy = status.copyWith(xp: 3);
    expect(copy.xp, 3);
    expect(copy.activeTravel, status.activeTravel);
  });

  test('Character.fromJson carries activeTravel.to as a plain id', () {
    final character = Character.fromJson(
      travellingCharacterJson(activeTravel: activeTravelJson()),
    );
    expect(character.status!.activeTravel!.to, 'city-marker-2');
  });
}
