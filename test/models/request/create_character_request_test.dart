import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';

CreateCharacterRequest buildRequest({String background = '', String? imagePath}) =>
    CreateCharacterRequest(
      name: 'Aria',
      sex: SexType.female,
      pronoun: PronounType.she,
      race: RaceType.elf,
      classType: ClassType.wizard,
      age: 120,
      background: background,
      imagePath: imagePath,
    );

void main() {
  test('toJson sends enum names and omits optional fields', () {
    expect(buildRequest().toJson(), {
      'name': 'Aria',
      'sex': 'female',
      'pronoun': 'she',
      'race': 'elf',
      'classType': 'wizard',
      'age': 120,
    });
  });

  test('toJson includes background and imagePath when present', () {
    final json = buildRequest(background: 'Storia', imagePath: 'https://x').toJson();

    expect(json['background'], 'Storia');
    expect(json['imagePath'], 'https://x');
  });

  test('requests with equal fields are equal', () {
    expect(buildRequest(), buildRequest());
  });
}
