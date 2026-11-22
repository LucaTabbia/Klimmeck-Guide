import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';

/// Ferite del personaggio e, fra queste, quelle dell'oste.
typedef CharacterWounds = ({
  List<InjuryType> injuries,
  List<InjuryType> innkeeperInjuries,
});

/// Le ferite per la sezione «Ferite» del Diario; `null` finché non c'è un
/// personaggio con il suo stato, nessuna ferita per una lista non servita.
CharacterWounds? woundsOf(CharacterState state) {
  if (state is! CharacterLoaded) return null;
  final status = state.character.status;
  if (status == null) return null;
  return (
    injuries: status.injuries ?? const <InjuryType>[],
    innkeeperInjuries: status.innkeeperInjuries,
  );
}

/// Ferite che una cura può raggiungere: quelle del personaggio meno quelle
/// dell'oste (BE Phase 25, D-14). Filtro di visualizzazione; `null` finché non
/// c'è un personaggio.
List<InjuryType>? curableInjuriesOf(CharacterState state) {
  if (state is! CharacterLoaded) return null;
  final status = state.character.status;
  if (status == null) return null;
  return [
    for (final injury in status.injuries ?? const <InjuryType>[])
      if (!status.innkeeperInjuries.contains(injury)) injury,
  ];
}
