import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/lore.dart';

/// Esito di una pozione bevuta dal Diario (`useItem`, BE Phase 18, D-11):
/// serve solo al riscontro sul foglio; lo stato del personaggio arriva dal
/// flusso `characterUpdated`.
class UseItemResult extends Equatable {
  const UseItemResult({
    required this.hpBefore,
    required this.hpAfter,
    required this.injuriesHealed,
    required this.quantityLeft,
    required this.recoveryUntil,
    required this.loreUnlocked,
  });

  final int hpBefore;
  final int hpAfter;
  final List<InjuryType> injuriesHealed;
  final int quantityLeft;

  /// Fine della ricarica, istante UTC del server.
  final DateTime recoveryUntil;
  final List<Lore> loreUnlocked;

  /// Numeri e data sono obbligatori (lancia se mancano); le due liste sono
  /// tolleranti voce per voce.
  factory UseItemResult.fromJson(Map<String, dynamic> json) => UseItemResult(
    hpBefore: (json['hpBefore'] as num).toInt(),
    hpAfter: (json['hpAfter'] as num).toInt(),
    injuriesHealed: injuryTypesFrom(json['injuriesHealed']),
    quantityLeft: (json['quantityLeft'] as num).toInt(),
    recoveryUntil: DateTime.parse(json['recoveryUntil'] as String).toUtc(),
    loreUnlocked: Lore.lenientRefsFrom(json['loreUnlocked']),
  );

  Map<String, dynamic> toJson() => {
    'hpBefore': hpBefore,
    'hpAfter': hpAfter,
    'injuriesHealed': injuriesHealed.map((injury) => injury.name).toList(),
    'quantityLeft': quantityLeft,
    'recoveryUntil': recoveryUntil.toUtc().toIso8601String(),
    'loreUnlocked': [
      for (final lore in loreUnlocked)
        {'id': lore.id, 'name': lore.name, 'type': lore.type?.name},
    ],
  };

  @override
  List<Object?> get props => [
    hpBefore,
    hpAfter,
    injuriesHealed,
    quantityLeft,
    recoveryUntil,
    loreUnlocked,
  ];
}
