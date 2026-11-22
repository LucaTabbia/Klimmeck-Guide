part of 'mission_participants_cubit.dart';

sealed class MissionParticipantsState extends Equatable {
  const MissionParticipantsState();

  @override
  List<Object?> get props => [];
}

final class MissionParticipantsIdle extends MissionParticipantsState {
  const MissionParticipantsIdle();
}

final class MissionParticipantsLoading extends MissionParticipantsState {
  const MissionParticipantsLoading();
}

/// Una lettura è fallita: il retry è un nuovo `load`.
final class MissionParticipantsFailed extends MissionParticipantsState {
  const MissionParticipantsFailed({required this.failure});

  final InnkeeperFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// Personaggi e luoghi letti (luoghi vuoti se la loro lettura è fallita,
/// D-31), solo per nomi ed etichette: i limiti di vita, consumabili e magie
/// arrivano dalla bozza servita (D-29, regola 4).
final class MissionParticipantsLoaded extends MissionParticipantsState {
  const MissionParticipantsLoaded({
    required this.characters,
    required this.places,
    this.isRereadingPositions = false,
    this.positionsFailure,
  });

  /// Id del personaggio → personaggio.
  final Map<String, Character> characters;

  /// Id del luogo → luogo.
  final Map<String, PointOfInterest> places;

  /// Una rilettura è in corso: storie e nomi restano, le posizioni no.
  final bool isRereadingPositions;

  /// L'ultima rilettura è fallita: le posizioni in mano sono vecchie.
  final InnkeeperFailure? positionsFailure;

  bool get _arePositionsCurrent =>
      !isRereadingPositions && positionsFailure == null;

  MissionParticipantsLoaded rereadingPositions() => MissionParticipantsLoaded(
    characters: characters,
    places: places,
    isRereadingPositions: true,
  );

  MissionParticipantsLoaded withPositionsFailure(InnkeeperFailure failure) =>
      MissionParticipantsLoaded(
        characters: characters,
        places: places,
        positionsFailure: failure,
      );

  /// Dove si trova il personaggio; `null` per un id sconosciuto o finché le
  /// posizioni non sono quelle dell'ultima lettura riuscita.
  String? locationIdOf(String characterId) => _arePositionsCurrent
      ? characters[characterId]?.status?.location?.id
      : null;

  /// Il luogo in cui si trova tutto il gruppo; `null` per un gruppo diviso o
  /// per posizioni non più valide.
  String? get commonLocationId {
    final locationIds = {
      for (final characterId in characters.keys) locationIdOf(characterId),
    };
    if (locationIds.length != 1) return null;
    return locationIds.single;
  }

  /// «Tipo presso città» (D-29); stringa vuota per un luogo sconosciuto.
  String placeLabelFor(String? locationId) {
    final place = places[locationId];
    if (place == null) return '';
    return placeLabelOf(place);
  }

  /// Voci della storia nell'ordine servito; `null` per un id sconosciuto.
  List<String>? backgroundOf(String characterId) {
    final character = characters[characterId];
    if (character == null) return null;
    return character.infos?.background ?? const [];
  }

  /// Rango servito; `null` per un id sconosciuto o un rango non servito.
  TitleType? titleOf(String characterId) =>
      characters[characterId]?.status?.title;

  String? itemNameOf(String characterId, String itemId) {
    final ownedItems = characters[characterId]?.assets?.ownedItems ?? const [];
    for (final owned in ownedItems) {
      final item = owned.item;
      if (item?.id == itemId) return item?.name;
    }
    return null;
  }

  String? spellNameOf(String characterId, String spellId) {
    final spellStates =
        characters[characterId]?.status?.spellStates ?? const [];
    for (final spellState in spellStates) {
      if (spellState.spell.id == spellId) return spellState.spell.name;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    characters,
    places,
    isRereadingPositions,
    positionsFailure,
  ];
}
