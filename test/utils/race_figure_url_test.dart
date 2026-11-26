import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/utils/race_figure_url.dart';

void main() {
  group('raceFigureUrl', () {
    test('points at the race and sex figure on Cloudinary', () {
      expect(
        raceFigureUrl(RaceType.human, SexType.female),
        CloudinaryAssets.url('main/races/human_female.svg'),
      );
      expect(
        raceFigureUrl(RaceType.halfelf, SexType.male),
        CloudinaryAssets.url('main/races/halfelf_male.svg'),
      );
    });

    test('points at the figures of the two renamed races', () {
      expect(
        raceFigureUrl(RaceType.infernal, SexType.male),
        CloudinaryAssets.url('main/races/infernal_male.svg'),
      );
      expect(
        raceFigureUrl(RaceType.volucri, SexType.female),
        CloudinaryAssets.url('main/races/volucri_female.svg'),
      );
    });
  });
}
