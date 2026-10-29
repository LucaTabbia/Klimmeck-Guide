part of 'character_cubit.dart';

@immutable
sealed class CharacterState extends Equatable {
  const CharacterState();
}

class CharacterInitial extends CharacterState {
  @override
  List<Object> get props => [];
}

class CharacterLoaded extends CharacterState {
  final Character character;

  const CharacterLoaded(this.character);

  @override
  List<Object> get props => [character];
}

class CharacterLoading extends CharacterState {
  @override
  List<Object> get props => [];
}

class CharacterError extends CharacterState {
  final String errorMessage;

  const CharacterError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

/// Personaggio ancora corrente per `me` ma invisibile al backend (morto, in
/// attesa della conferma del foglio: 09-CONTEXT D-13). Nessun errore a schermo;
/// il foglio di morte arriva dalla query dei risultati non confermati.
class CharacterUnavailable extends CharacterState {
  const CharacterUnavailable();

  @override
  List<Object> get props => [];
}
