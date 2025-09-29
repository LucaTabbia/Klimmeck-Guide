part of 'journal_cubit.dart';

@immutable
abstract class JournalState {}

class JournalInitial extends JournalState {}

class JournalLoadData extends JournalState {
  final List<EquipmentItem> equipmentItems;
  final Equipment equipment;
  final List<LootItem> lootItems;

  JournalLoadData(this.equipmentItems, this.lootItems, this.equipment);
}

class JournalLoading extends JournalState {}

class JournalError extends JournalState {
  final String errorMessage;

  JournalError(this.errorMessage);
}
