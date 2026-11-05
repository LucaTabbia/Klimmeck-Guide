part of 'quest_generation_cubit.dart';

sealed class QuestGenerationState extends Equatable {
  const QuestGenerationState();

  @override
  List<Object?> get props => [];
}

/// Nessuna corsa chiesta (o l'esito precedente è già stato mostrato).
final class QuestGenerationIdle extends QuestGenerationState {
  const QuestGenerationIdle();
}

/// Corsa in volo: il pulsante è disabilitato (D-09).
final class QuestGenerationSubmitting extends QuestGenerationState {
  const QuestGenerationSubmitting();
}

/// Quante quest ha creato il BE; 0 = mondo pieno (D-09).
final class QuestGenerationSucceeded extends QuestGenerationState {
  const QuestGenerationSucceeded({required this.created});

  final int created;

  @override
  List<Object?> get props => [created];
}

/// Esito fallito; [serial] cresce a ogni fallimento: lo stesso codice due
/// volte resta un evento (D-10).
final class QuestGenerationFailed extends QuestGenerationState {
  const QuestGenerationFailed({required this.failure, required this.serial});

  final InnkeeperFailure failure;
  final int serial;

  @override
  List<Object?> get props => [failure, serial];
}
