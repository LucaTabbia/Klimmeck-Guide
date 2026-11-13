import 'dart:math' show max, min;

import '../enums/quest_type.dart';
import '../enums/title_type.dart';
import 'adventurer_slot.dart';
import 'registered_adventurer.dart';

const List<AdventurerSlot> _soloSlots = [AdventurerSlot(title: null, count: 1)];

/// Una `enemy` la prende un solo giocatore, qualunque posto porti il filo
/// (quick 261111-enm); il rango minimo lo decide `isTitleEligible`.
bool isSinglePlayerQuest(QuestType? type) => type == QuestType.enemy;

/// Posti con cui una quest è giudicata (specchio di `questSlotsOf` del BE):
/// ogni controllo di capienza passa da qui, mai dai posti del filo.
List<AdventurerSlot> questSlotsOf(
  QuestType? type,
  List<AdventurerSlot> wireSlots,
) => isSinglePlayerQuest(type) ? _soloSlots : wireSlots;

int totalSlots(List<AdventurerSlot> slots) =>
    slots.fold(0, (sum, slot) => sum + slot.count);

bool isFullForEveryone(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
) => slots.isNotEmpty && registered.length >= totalSlots(slots);

/// BE Phase 8 D-32: gli slot esatti si riempiono prima di quelli jolly; un
/// registrato di rango ignoto (forma Phase 7) occupa un posto jolly.
/// BE 13.1 D-08: i legend oltre i posti legend occupano posti hero; nessun
/// altro titolo scala.
bool canRegisterWithTitle(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  TitleType title,
) {
  final counts = foldedCountsOf(slots, registered);
  final own = seatTitleOf(slots, registered, title);
  return counts[own]! < exactSeatsOf(slots, own) ||
      anyRankOverflowOf(slots, registered) < exactSeatsOf(slots, null);
}

/// Posti esatti per titolo; `null` sono i posti di qualsiasi rango.
int exactSeatsOf(List<AdventurerSlot> slots, TitleType? title) =>
    slots.where((s) => s.title == title).fold(0, (sum, s) => sum + s.count);

int _countOf(List<RegisteredAdventurer> registered, TitleType title) =>
    registered.where((r) => r.title == title).length;

/// I legend oltre i posti legend contano sui posti hero (specchio di
/// `foldedCountsOf` del BE, 13.1 D-08).
Map<TitleType, int> foldedCountsOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
) {
  final legendSeats = exactSeatsOf(slots, TitleType.legend);
  final counts = {
    for (final title in TitleType.values) title: _countOf(registered, title),
  };
  final extraLegends = max(0, counts[TitleType.legend]! - legendSeats);
  counts[TitleType.legend] = min(counts[TitleType.legend]!, legendSeats);
  counts[TitleType.hero] = counts[TitleType.hero]! + extraLegends;
  return counts;
}

/// Registrati sui posti di qualsiasi rango: l'eccedenza dei posti esatti
/// (sui conteggi piegati) più i registrati di rango ignoto (BE Phase 8 D-32).
int anyRankOverflowOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
) {
  final counts = foldedCountsOf(slots, registered);
  return TitleType.values.fold(
    registered.where((r) => r.title == null).length,
    (sum, t) => sum + max(0, counts[t]! - exactSeatsOf(slots, t)),
  );
}

/// Un legend siede sui posti legend finché ce n'è uno libero, poi su quelli
/// hero (specchio di `seatTitleOf` del BE).
TitleType seatTitleOf(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  TitleType title,
) =>
    title == TitleType.legend &&
        _countOf(registered, TitleType.legend) >=
            exactSeatsOf(slots, TitleType.legend)
    ? TitleType.hero
    : title;

bool isFullFor(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  TitleType? title,
) {
  if (slots.isEmpty) return false;
  if (isFullForEveryone(slots, registered)) return true;
  if (title == null) return false;
  return !canRegisterWithTitle(slots, registered, title);
}
