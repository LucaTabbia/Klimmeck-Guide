import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/ambush_city.dart';
import 'package:klimmeck_guide/models/quest_result/ambush_report.dart';

import '../../helpers/fixtures/quest_result_fixtures.dart';

void main() {
  test('parses the instant as UTC and the near city (D-01)', () {
    final report = AmbushReport.fromJson(ambushReportJson());

    expect(report.at, DateTime.utc(2026, 10, 27, 11, 20));
    expect(report.at.isUtc, isTrue);
    expect(
      report.nearCity,
      const AmbushCity(id: 'city-andogan', name: 'Andogan'),
    );
    expect(report.reachedCity, isNull);
  });

  test('parses the city reached after a defeat (D-01)', () {
    final report = AmbushReport.fromJson(
      ambushReportJson(
        reachedCity: ambushCityJson(id: 'city-bosa', name: 'Bosa'),
      ),
    );

    expect(report.reachedCity!.name, 'Bosa');
    expect(report.reachedCity!.id, 'city-bosa');
  });

  test('throws on a missing instant or near city (D-01)', () {
    expect(
      () => AmbushReport.fromJson(ambushReportJson()..remove('at')),
      throwsA(anything),
    );
    expect(
      () => AmbushReport.fromJson(ambushReportJson()..['nearCity'] = null),
      throwsA(anything),
    );
    expect(
      () => AmbushReport.fromJson(
        ambushReportJson()..['nearCity'] = {'id': 'city-andogan'},
      ),
      throwsA(anything),
    );
    expect(
      () => AmbushReport.fromJson(
        ambushReportJson(nearCity: ambushCityJson(name: '')),
      ),
      throwsA(anything),
    );
  });

  test('throws on a malformed reached city (D-01)', () {
    expect(
      () => AmbushReport.fromJson(
        ambushReportJson(reachedCity: {'id': 'city-bosa'}),
      ),
      throwsA(anything),
    );
    expect(
      () => AmbushReport.fromJson(ambushReportJson()..['reachedCity'] = 'Bosa'),
      throwsA(anything),
    );
  });

  test('round-trips through toJson (D-01)', () {
    final won = AmbushReport.fromJson(ambushReportJson());
    final lost = AmbushReport.fromJson(
      ambushReportJson(
        reachedCity: ambushCityJson(id: 'city-bosa', name: 'Bosa'),
      ),
    );

    expect(AmbushReport.fromJson(won.toJson()), won);
    expect(AmbushReport.fromJson(lost.toJson()), lost);
  });

  test('onFoot is read leniently, default false (D-28)', () {
    expect(
      AmbushReport.fromJson(ambushReportJson(onFoot: true)).isOnFoot,
      isTrue,
    );
    expect(AmbushReport.fromJson(ambushReportJson()).isOnFoot, isFalse);
    for (final flag in <Object?>['yes', null, 1]) {
      final json = ambushReportJson()..['onFoot'] = flag;

      expect(AmbushReport.fromJson(json).isOnFoot, isFalse, reason: '$flag');
    }
  });

  test('onFoot round-trips and is part of the props (D-28)', () {
    final onFoot = AmbushReport.fromJson(ambushReportJson(onFoot: true));

    expect(AmbushReport.fromJson(onFoot.toJson()), onFoot);
    expect(onFoot, isNot(AmbushReport.fromJson(ambushReportJson())));
  });
}
