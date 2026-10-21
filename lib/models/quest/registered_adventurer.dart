import 'package:equatable/equatable.dart';

import '../enums/title_type.dart';

/// Registrato a una quest: forma Phase 8 `{character, title}` oppure Phase 7
/// (id stringa, rango ignoto).
class RegisteredAdventurer extends Equatable {
  const RegisteredAdventurer({required this.characterId, required this.title});

  final String characterId;
  final TitleType? title;

  static RegisteredAdventurer? from(Object? wire) => switch (wire) {
    {'character': final String characterId} => RegisteredAdventurer(
      characterId: characterId,
      title: TitleType.values.asNameMap()[(wire as Map)['title']],
    ),
    final String characterId => RegisteredAdventurer(
      characterId: characterId,
      title: null,
    ),
    _ => null,
  };

  static List<RegisteredAdventurer> listFrom(Object? wire) => switch (wire) {
    final List<dynamic> list => List.unmodifiable(
      list.map(from).whereType<RegisteredAdventurer>(),
    ),
    _ => const [],
  };

  Map<String, dynamic> toJson() => {
    'character': characterId,
    'title': title?.name,
  };

  @override
  List<Object?> get props => [characterId, title];
}
