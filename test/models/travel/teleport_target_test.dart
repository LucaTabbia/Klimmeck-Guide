import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fixtures/pending_request_fixtures.dart';

Character beaWith({
  Object? name = 'Bea',
  Object? sex = 'female',
  bool withPoint = true,
}) {
  final json = participantCharacterJson(
    id: 'char-bea',
    locationId: 'poi-borgo-marker',
  );
  json['infos'] = {'name': name, 'sex': sex};
  if (!withPoint) {
    (json['status'] as Map<String, dynamic>)['location'] = {
      'id': 'poi-borgo-marker',
      'location': [null, null],
    };
  }
  return Character.fromJson(json);
}

void main() {
  test('reads id, name, point and sex from the character (D-15/C3)', () {
    final target = TeleportTarget.fromCharacter(
      beaWith(),
      fallbackName: 'Fallback',
    );

    expect(target, isNotNull);
    expect(target!.characterId, 'char-bea');
    expect(target.name, 'Bea');
    expect(target.location.id, 'poi-borgo-marker');
    expect(target.location.location, const LatLng(10, 20));
    expect(target.sex, SexType.female);
  });

  test('falls back to the queue name when the character has none', () {
    final target = TeleportTarget.fromCharacter(
      beaWith(name: null),
      fallbackName: 'Bea',
    );

    expect(target?.name, 'Bea');
  });

  test('is null without a sex for the pawn', () {
    expect(
      TeleportTarget.fromCharacter(beaWith(sex: null), fallbackName: 'Bea'),
      isNull,
    );
  });

  test('is null without a point on the map', () {
    expect(
      TeleportTarget.fromCharacter(
        beaWith(withPoint: false),
        fallbackName: 'Bea',
      ),
      isNull,
    );
  });

  test('two targets with the same fields are equal', () {
    expect(
      TeleportTarget.fromCharacter(beaWith(), fallbackName: 'Bea'),
      TeleportTarget.fromCharacter(beaWith(), fallbackName: 'Bea'),
    );
  });
}
