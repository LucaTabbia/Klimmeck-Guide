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
  List<Object> get props => [character, DateTime.now()];
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
