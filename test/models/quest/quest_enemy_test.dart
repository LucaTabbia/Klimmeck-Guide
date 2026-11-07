import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest_enemy.dart';

Map<String, dynamic> _entry(
  String id,
  String? name, {
  int quantity = 1,
  int? xp,
  String? imagePath,
  bool? known = true,
}) => {
  'quantity': quantity,
  if (known != null) 'known': known,
  'enemy': {'id': id, 'name': name, 'imagePath': imagePath, 'xp': xp},
};

List<QuestEnemy> _enemies(List<Map<String, dynamic>> entries) =>
    QuestEnemy.listFrom(entries);

void main() {
  group('QuestEnemy.fromJson', () {
    test('parses enemy and quantity with only id, name, imagePath and xp '
        '(D-01)', () {
      final entry = QuestEnemy.fromJson({
        'quantity': 3,
        'known': true,
        'enemy': {
          'id': 'goblin',
          'name': 'Goblin',
          'imagePath': 'v1/goblin.png',
          'xp': 7,
          'locations': ['forest'],
          'relatedLore': [
            {'id': 'l'},
          ],
        },
      });

      expect(entry.quantity, 3);
      expect(entry.enemy.id, 'goblin');
      expect(entry.enemy.name, 'Goblin');
      expect(entry.enemy.imagePath, 'v1/goblin.png');
      expect(entry.enemy.xp, 7);
      expect(entry.enemy.locations, isNull);
      expect(entry.enemy.relatedLore, isEmpty);
    });

    test('throws FormatException for a missing enemy, a non-string id or a '
        'quantity below 1 (D-01)', () {
      final enemy = {'id': 'goblin', 'name': 'Goblin'};
      for (final json in <Map<String, dynamic>>[
        {'quantity': 1},
        {
          'quantity': 1,
          'enemy': {'name': 'x'},
        },
        {'quantity': 0, 'enemy': enemy},
        {'quantity': '2', 'enemy': enemy},
      ]) {
        expect(
          () => QuestEnemy.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });

    test('toJson round-trips the whitelisted enemy (D-01)', () {
      final entry = QuestEnemy.fromJson(
        _entry('goblin', 'Goblin', quantity: 2, xp: 7, imagePath: 'v1/g.png'),
      );

      expect(QuestEnemy.fromJson(entry.toJson()), entry);
    });

    test('reads whether the character knows the exact enemy (D-03)', () {
      expect(
        QuestEnemy.fromJson(_entry('goblin', 'Goblin', known: false)).known,
        isFalse,
      );
      expect(
        QuestEnemy.fromJson(_entry('goblin', 'Goblin', known: true)).known,
        isTrue,
      );
    });

    test('toJson writes known so the result round trip keeps the entry '
        '(D-03, D-19)', () {
      final entry = QuestEnemy.fromJson(
        _entry('goblin', 'Goblin', xp: 7, known: false),
      );

      expect(entry.toJson()['known'], false);
      expect(QuestEnemy.fromJson(entry.toJson()), entry);
      expect(QuestEnemy.lenientListFrom([entry.toJson()]), [entry]);
    });

    test('entries differing only by known are not equal (D-03)', () {
      expect(
        QuestEnemy.fromJson(_entry('goblin', 'Goblin', known: true)),
        isNot(QuestEnemy.fromJson(_entry('goblin', 'Goblin', known: false))),
      );
    });
  });

  group('QuestEnemy lists', () {
    test('listFrom is strict: one malformed entry throws (D-01)', () {
      expect(
        () => QuestEnemy.listFrom([
          _entry('goblin', 'Goblin'),
          {'quantity': 1},
        ]),
        throwsFormatException,
      );
      expect(QuestEnemy.listFrom(null), isEmpty);
      expect(() => QuestEnemy.listFrom('x'), throwsFormatException);

      final list = QuestEnemy.listFrom([_entry('goblin', 'Goblin')]);
      expect(list, hasLength(1));
      expect(() => list.add(list.first), throwsUnsupportedError);
    });

    test('lenientListFrom drops malformed entries and keeps the rest '
        '(D-01)', () {
      final list = QuestEnemy.lenientListFrom([
        _entry('goblin', 'Goblin'),
        {'quantity': 1},
        'x',
      ]);

      expect(list.map((e) => e.enemy.id), ['goblin']);
      expect(() => list.add(list.first), throwsUnsupportedError);
      expect(QuestEnemy.lenientListFrom(null), isEmpty);
      expect(QuestEnemy.lenientListFrom('x'), isEmpty);
    });

    test('a board entry without known or with a non-boolean known drops the '
        'quest (D-03)', () {
      expect(
        () => QuestEnemy.listFrom([_entry('goblin', 'Goblin', known: null)]),
        throwsFormatException,
      );
      expect(
        () => QuestEnemy.listFrom([
          {..._entry('goblin', 'Goblin'), 'known': 'yes'},
        ]),
        throwsFormatException,
      );
    });

    test('a result entry without known is dropped and the others stay '
        '(D-03)', () {
      final list = QuestEnemy.lenientListFrom([
        _entry('goblin', 'Goblin', known: null),
        _entry('troll', 'Troll'),
      ]);

      expect(list, hasLength(1));
      expect(list.single.enemy.id, 'troll');
    });
  });

  group('enemyLinesOf', () {
    test('enemyLinesOf writes «Nx nome» in BE order (D-02)', () {
      final enemies = _enemies([
        _entry('goblin', 'Goblin', quantity: 3, xp: 7),
        _entry('goblin-chief', 'Capo goblin', xp: 21),
      ]);

      expect(enemyLinesOf(enemies), ['3x Goblin', '1x Capo goblin']);
    });

    test('enemyLinesOf merges entries of the same enemy id keeping the first '
        'position (D-02)', () {
      final enemies = _enemies([
        _entry('goblin', 'Goblin', quantity: 2),
        _entry('wolf', 'Lupo'),
        _entry('goblin', 'Goblin'),
      ]);

      expect(enemyLinesOf(enemies), ['3x Goblin', '1x Lupo']);
    });

    test('a single enemy with quantity 1 reads the bare name (D-02)', () {
      expect(enemyLinesOf(_enemies([_entry('shrub', 'Arbusto maligno')])), [
        'Arbusto maligno',
      ]);
      expect(enemyLinesOf(_enemies([_entry('troll', 'Troll', quantity: 2)])), [
        '2x Troll',
      ]);
    });

    test('enemyLinesOf skips enemies without a name (D-02)', () {
      final enemies = _enemies([
        _entry('nameless', null, quantity: 2),
        _entry('blank', ''),
        _entry('wolf', 'Lupo', quantity: 2),
      ]);

      expect(enemyLinesOf(enemies), ['2x Lupo']);
      expect(enemyLinesOf(_enemies([_entry('nameless', null)])), isEmpty);
    });

    test('a named enemy beside unnamed ones keeps its count (D-02)', () {
      final enemies = _enemies([
        _entry('goblin', 'Goblin'),
        _entry('nameless', null, quantity: 2),
      ]);

      expect(enemyLinesOf(enemies), ['1x Goblin']);
      expect(enemyLinesOf(_enemies([_entry('goblin', 'Goblin')])), ['Goblin']);
    });
  });

  group('strongestEnemyOf', () {
    test('strongestEnemyOf picks the highest xp, null xp counts as 0, first '
        'wins ties (D-02)', () {
      final strongest = strongestEnemyOf(
        _enemies([
          _entry('goblin', 'Goblin', xp: 7),
          _entry('chief', 'Capo', xp: 21),
          _entry('orc', 'Orco', xp: 21),
        ]),
      );
      expect(strongest?.id, 'chief');

      final tie = strongestEnemyOf(
        _enemies([_entry('a', 'A'), _entry('b', 'B')]),
      );
      expect(tie?.id, 'a');

      expect(strongestEnemyOf(const []), isNull);
    });
  });
}
