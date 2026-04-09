part of 'journal_cubit.dart';

@immutable
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoadData extends JournalState {
  final Equipment equipment;

  const JournalLoadData(this.equipment);

  @override
  List<Object?> get props => [equipment];
}

class JournalLoading extends JournalState {}

class JournalError extends JournalState {
  final String errorMessage;

  const JournalError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
