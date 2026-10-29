import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';

/// Override di un partecipante (`ParticipantOverrideInput`, BE 09 §1/§9): solo ciò che il GM ha cambiato; quantità ≥ 1 (C1).
class ParticipantOverride extends Equatable {
  const ParticipantOverride({
    required this.characterId,
    this.hpAfter,
    this.injuries = const [],
    this.consumablesUsed = const {},
    this.spellsUsed = const {},
  });

  final String characterId;
  final int? hpAfter;

  /// Solo le ferite aggiunte.
  final List<InjuryType> injuries;

  /// Id dell'oggetto → quantità usata.
  final Map<String, int> consumablesUsed;

  /// Id della magia → usi consumati.
  final Map<String, int> spellsUsed;

  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    if (hpAfter != null) 'hpAfter': hpAfter,
    if (injuries.isNotEmpty)
      'injuries': [for (final injury in injuries) injury.name],
    if (consumablesUsed.isNotEmpty)
      'consumablesUsed': [
        for (final MapEntry(key: item, value: quantity)
            in consumablesUsed.entries)
          {'item': item, 'quantity': quantity},
      ],
    if (spellsUsed.isNotEmpty)
      'spellsUsed': [
        for (final MapEntry(key: spell, value: usages) in spellsUsed.entries)
          {'spell': spell, 'usages': usages},
      ],
  };

  @override
  List<Object?> get props => [
    characterId,
    hpAfter,
    injuries,
    consumablesUsed,
    spellsUsed,
  ];
}
