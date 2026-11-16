import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/spell_origin.dart';

void main() {
  test('the wire names are void, arcane and shamanic (D-01)', () {
    expect(SpellOrigin.values.map((origin) => origin.wireName), [
      'void',
      'arcane',
      'shamanic',
    ]);
  });

  test('the origins read Vuoto, Arcana and Sciamanica (D-06)', () {
    expect(SpellOrigin.values.map((origin) => origin.label), [
      'Vuoto',
      'Arcana',
      'Sciamanica',
    ]);
  });

  test('fromWire reads the wire value void as theVoid (D-01)', () {
    expect(SpellOrigin.fromWire('void'), SpellOrigin.theVoid);
    expect(SpellOrigin.fromWire('arcane'), SpellOrigin.arcane);
    expect(SpellOrigin.fromWire('shamanic'), SpellOrigin.shamanic);
  });

  test('the Dart name never crosses the wire (D-01)', () {
    expect(SpellOrigin.fromWire('theVoid'), isNull);
  });

  test('the legacy quest type name magic is not an origin (D-01, D-20)', () {
    expect(SpellOrigin.fromWire('magic'), isNull);
  });

  test('fromWire reads null for an unknown or non-string value (D-01)', () {
    for (final value in <Object?>['chaos', null, 7]) {
      expect(SpellOrigin.fromWire(value), isNull, reason: '$value');
    }
  });

  test('the origin icons point to their files (D-05, D-21)', () {
    expect(
      CloudinaryAssets.arcaneOrigin,
      'v1794764154/arcaneOrigin_retjhh.svg',
    );
    expect(
      CloudinaryAssets.shamanicOrigin,
      'v1794764172/shamanicOrigin_vkxq6d.svg',
    );
    expect(CloudinaryAssets.voidOrigin, 'v1794764163/voidOrigin_mxgwls.svg');
  });

  test('every origin has its own icon (D-05)', () {
    expect(
      SpellOrigin.arcane.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.arcaneOrigin),
    );
    expect(
      SpellOrigin.shamanic.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.shamanicOrigin),
    );
    expect(
      SpellOrigin.theVoid.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.voidOrigin),
    );
    expect(
      SpellOrigin.values.map((origin) => origin.imagePath).toSet(),
      hasLength(3),
    );
  });
}
