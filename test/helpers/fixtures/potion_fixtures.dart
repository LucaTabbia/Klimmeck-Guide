import 'shop_fixtures.dart';

const Object _defaultRecovery = Object();

/// `LootItem.recovery` sul filo (BE Phase 18): tempo in millisecondi e turni.
Map<String, dynamic> lootRecoveryJson({
  Object? time = 1800000,
  Object? turns = 3,
}) => {'time': time, 'turns': turns};

/// Pozione heal come la servono `LootFragment.fields` + `recovery`; di default
/// le erbe da campo con mezz'ora di ricarica.
Map<String, dynamic> healPotionJson({
  String id = 'l-herb',
  String name = 'Erbe da campo',
  int power = 400,
  List<String> canHeal = const ['contusion'],
  Object? recovery = _defaultRecovery,
}) => {
  'id': id,
  'name': name,
  'description': 'Oggetto $id',
  'effect': 'heal',
  'power': power,
  'canHeal': canHeal,
  'buyPrice': coinsJson(silver: 5),
  'sellPrice': coinsJson(silver: 2),
  'recovery': identical(recovery, _defaultRecovery)
      ? lootRecoveryJson()
      : recovery,
};

/// Voce di `ownedItems` con una pozione heal.
Map<String, dynamic> ownedHealPotionJson({
  int quantity = 2,
  Map<String, dynamic>? item,
}) => {'quantity': quantity, 'item': item ?? healPotionJson()};

/// Risposta di `useItem` (BE Phase 18): di default le erbe da campo bevute
/// alle 10:00 del clock di test, ricarica fino alle 10:30.
Map<String, dynamic> useItemResultJson({
  int hpBefore = 4,
  int hpAfter = 8,
  List<Object?> injuriesHealed = const ['contusion'],
  int quantityLeft = 1,
  Object? recoveryUntil = '2026-10-27T10:30:00.000Z',
  List<Object?> loreUnlocked = const [],
}) => {
  'hpBefore': hpBefore,
  'hpAfter': hpAfter,
  'injuriesHealed': injuriesHealed,
  'quantityLeft': quantityLeft,
  'recoveryUntil': recoveryUntil,
  'loreUnlocked': loreUnlocked,
};
