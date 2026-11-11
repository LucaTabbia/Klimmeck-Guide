import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';

/// Campi del personaggio che decidono cosa la query `quests` restituisce.
typedef _QuestScope = ({
  String? locationId,
  TitleType? title,
  String? pendingQuestId,
  String? storyQuestId,
  String? worldMissionQuestId,
  int? currentLifePoints,
  int? maxLifePoints,
  String? injuries,
});

/// Il BE serve `quests` per area del personaggio corrente (BE 13.1 D-05): la
/// lista dipende da dove sta, dal titolo (le story visibili) e dalle corsie.
/// Quando `characterUpdated` cambia uno di questi campi la lista è riletta in
/// silenzio (CLAUDE.md regola 2) con la città corrente per i POI della board;
/// i filtri client di `board_policy.dart` restano come difesa.
/// La lista dipende anche da vita e ferite (BE Phase 18, D-20: `noEffect` è per
/// chi guarda): in città un loro cambio la rilegge in silenzio.
class QuestScopeListener extends StatelessWidget {
  const QuestScopeListener({
    super.key,
    required this.cities,
    required this.child,
  });

  final List<City> cities;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<CharacterCubit, CharacterState>(
        listenWhen: _scopeChanged,
        listener: _reread,
        child: child,
      );

  bool _scopeChanged(CharacterState previous, CharacterState current) {
    final before = _scopeOf(previous);
    final after = _scopeOf(current);
    return before != null && after != null && before != after;
  }

  void _reread(BuildContext context, CharacterState state) {
    if (state is! CharacterLoaded) return;
    final location = state.character.status?.location;
    context.read<QuestCubit>().refreshQuests(
      cityId: currentCityOf(cities, location)?.id,
    );
  }

  _QuestScope? _scopeOf(CharacterState state) {
    if (state is! CharacterLoaded) return null;
    final status = state.character.status;
    final lanes = state.character.quests;
    final isInCity = currentCityOf(cities, status?.location) != null;
    return (
      locationId: status?.location?.id,
      title: status?.title,
      pendingQuestId: lanes?.pendingQuest?.quest?.id,
      storyQuestId: lanes?.activeStoryQuest?.quest?.id,
      worldMissionQuestId: lanes?.activeWorldMissionQuest?.quest?.id,
      currentLifePoints: isInCity ? status?.currentLifePoints : null,
      maxLifePoints: isInCity ? status?.maxLifePoints : null,
      // Una lista nel record si confronta per identità: le ferite viaggiano
      // come valore unico, ordinato, per non rileggere a ogni emissione né
      // per lo stesso insieme in un altro ordine.
      injuries: isInCity ? _injurySetOf(status?.injuries) : null,
    );
  }

  String? _injurySetOf(List<InjuryType>? injuries) =>
      (injuries?.map((injury) => injury.name).toList()?..sort())?.join(',');
}
