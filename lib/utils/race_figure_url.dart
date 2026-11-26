import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';

/// Figura scontornata della razza e del sesso su Cloudinary
/// (`main/races/<razza>_<sesso>.svg`), al posto del ritratto del personaggio
/// che può avere qualsiasi forma (Phase 26 D-10).
String raceFigureUrl(RaceType race, SexType sex) =>
    CloudinaryAssets.url('main/races/${_figureSlugOf(race)}_${sex.name}.svg');

/// Le figure usano già i nomi nuovi di due razze: vale finché il rename
/// dell'enum (PR #58) non entra.
String _figureSlugOf(RaceType race) => switch (race) {
  RaceType.tiefling => 'infernal',
  RaceType.aarakocra => 'volucri',
  _ => race.name,
};
