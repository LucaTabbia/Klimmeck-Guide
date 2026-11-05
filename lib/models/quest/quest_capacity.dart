import 'dart:math' show max, min;

import '../enums/title_type.dart';
import 'adventurer_slot.dart';
import 'registered_adventurer.dart';

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
  int exact(TitleType? t) =>
      slots.where((s) => s.title == t).fold(0, (sum, s) => sum + s.count);
  final legendSeats = exact(TitleType.legend);
  final counts = _foldedCountsOf(registered, legendSeats: legendSeats);
  final own = _seatTitleOf(title, registered, legendSeats: legendSeats);
  final anyRank = exact(null);
  final unknownRank = registered.where((r) => r.title == null).length;
  final overflow = TitleType.values.fold(
    unknownRank,
    (sum, t) => sum + max(0, counts[t]! - exact(t)),
  );
  return counts[own]! < exact(own) || overflow < anyRank;
}

int _countOf(List<RegisteredAdventurer> registered, TitleType title) =>
    registered.where((r) => r.title == title).length;

/// I legend oltre i posti legend contano sui posti hero (BE 13.1 D-08).
Map<TitleType, int> _foldedCountsOf(
  List<RegisteredAdventurer> registered, {
  required int legendSeats,
}) {
  final counts = {
    for (final title in TitleType.values) title: _countOf(registered, title),
  };
  final extraLegends = max(0, counts[TitleType.legend]! - legendSeats);
  counts[TitleType.legend] = min(counts[TitleType.legend]!, legendSeats);
  counts[TitleType.hero] = counts[TitleType.hero]! + extraLegends;
  return counts;
}

/// Un legend siede sui posti legend finché ce n'è uno libero, poi su quelli
/// hero (specchio di `seatTitleOf` del BE).
TitleType _seatTitleOf(
  TitleType title,
  List<RegisteredAdventurer> registered, {
  required int legendSeats,
}) =>
    title == TitleType.legend &&
        _countOf(registered, TitleType.legend) >= legendSeats
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
