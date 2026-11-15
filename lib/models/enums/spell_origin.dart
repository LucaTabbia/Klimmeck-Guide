import 'package:klimmeck_guide/config/cloudinary_assets.dart';

/// Origine di una magia (D-01): macro-classe sopra uso ed energia. `void` è
/// una parola riservata in Dart: il valore attraversa il filo solo col suo
/// nome esplicito.
enum SpellOrigin {
  theVoid(
    wireName: 'void',
    label: 'Vuoto',
    imageId: CloudinaryAssets.voidOrigin,
  ),
  arcane(
    wireName: 'arcane',
    label: 'Arcana',
    imageId: CloudinaryAssets.arcaneOrigin,
  ),
  shamanic(
    wireName: 'shamanic',
    label: 'Sciamanica',
    imageId: CloudinaryAssets.shamanicOrigin,
  );

  const SpellOrigin({
    required this.wireName,
    required this.label,
    required String imageId,
  }) : _imageId = imageId;

  final String wireName;
  final String label;
  final String _imageId;

  String get imagePath => CloudinaryAssets.url(_imageId);

  static SpellOrigin? fromWire(Object? value) {
    for (final origin in values) {
      if (origin.wireName == value) return origin;
    }
    return null;
  }
}
