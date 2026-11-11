import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';

/// Ferite del personaggio caricato; `null` finché non c'è un personaggio.
List<InjuryType>? characterInjuriesOf(CharacterState state) =>
    state is CharacterLoaded ? state.character.status?.injuries : null;
