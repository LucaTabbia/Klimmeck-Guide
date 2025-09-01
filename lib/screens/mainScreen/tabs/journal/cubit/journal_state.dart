part of 'journal_cubit.dart';

@immutable
abstract class JournalState {}

class JournalInitial extends JournalState {}

class JournalLoadData extends JournalState {
  final List<EquipmentItem> equipmentItems;

  JournalLoadData(this.equipmentItems);
}

class JournalLoading extends JournalState {}

class JournalError extends JournalState {
  final String errorMessage;

  JournalError(this.errorMessage);
}
