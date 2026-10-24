import 'dart:math' show max;

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
bool canRegisterWithTitle(
  List<AdventurerSlot> slots,
  List<RegisteredAdventurer> registered,
  TitleType title,
) {
  int exact(TitleType? t) =>
      slots.where((s) => s.title == t).fold(0, (sum, s) => sum + s.count);
  int reg(TitleType t) => registered.where((r) => r.title == t).length;
  final anyRank = exact(null);
  final unknownRank = registered.where((r) => r.title == null).length;
  final overflow = TitleType.values.fold(
    unknownRank,
    (sum, t) => sum + max(0, reg(t) - exact(t)),
  );
  return reg(title) < exact(title) || overflow < anyRank;
}

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
