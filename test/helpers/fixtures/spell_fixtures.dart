import 'package:klimmeck_guide/models/character/character.dart';

/// Istante fisso dei test sulle magie: le `recoveries` di default cadono 12 e 42 minuti dopo.
final DateTime spellFixtureNow = DateTime.utc(2026, 10, 27, 10);

/// `recoveryTime` e `requiredLearnTime` in millisecondi (BE: delay di Bull);
/// l'unità di `requiredLearnTime` va confermata dall'handoff BE 9.1 (A3).
Map<String, dynamic> spellJson({
  String id = 'spell-1',
  String name = 'Dardo di fuoco',
  String description = 'Un dardo che brucia il bersaglio',
  int? maxUsages = 3,
  int? recoveryTime = 7200000,
  String? energy = 'fire',
  int? power = 12,
  String? useType = 'attack',
  int? minXpToLearn = 100,
  int? requiredLearnTime = 3600000,
}) => {
  'id': id,
  'name': name,
  'description': description,
  'useType': useType,
  'maxUsages': maxUsages,
  'recoveryTime': recoveryTime,
  'minXpToLearn': minXpToLearn,
  'requiredLearnTime': requiredLearnTime,
  'energyDamage': energy == null ? null : {'type': energy, 'power': power},
};

Map<String, dynamic> activeSpellJson({
  String spellId = 'spell-1',
  int usages = 3,
  Map<String, dynamic>? spell,
}) => {'usages': usages, 'spell': spell ?? spellJson(id: spellId)};

Map<String, dynamic> spellStateJson({
  String spellId = 'spell-1',
  int usages = 1,
  List<Object?> recoveries = const [
    '2026-10-27T10:12:00.000Z',
    '2026-10-27T10:42:00.000Z',
  ],
}) => {
  'spell': {'id': spellId},
  'usages': usages,
  'recoveries': recoveries,
};

/// `spellStates == null` = payload pre-9.1 (campo assente).
Map<String, dynamic> spellbookCharacterJson({
  String id = 'c-1',
  int? maxActiveSpells = 2,
  List<Map<String, dynamic>>? spells,
  List<Map<String, dynamic>> activeSpells = const [],
  List<Map<String, dynamic>>? spellStates,
}) => {
  'id': id,
  'status': {
    'maxActiveSpells': maxActiveSpells,
    'spells': spells ?? [spellJson()],
    if (spellStates != null) 'spellStates': spellStates,
  },
  'assets': {'activeSpells': activeSpells},
};

Character spellbookCharacter({
  String id = 'c-1',
  int? maxActiveSpells = 2,
  List<Map<String, dynamic>>? spells,
  List<Map<String, dynamic>> activeSpells = const [],
  List<Map<String, dynamic>>? spellStates,
}) => Character.fromJson(
  spellbookCharacterJson(
    id: id,
    maxActiveSpells: maxActiveSpells,
    spells: spells,
    activeSpells: activeSpells,
    spellStates: spellStates,
  ),
);
