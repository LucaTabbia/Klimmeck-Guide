import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/character_creation_repository.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import 'character_draft.dart';

part 'character_creation_state.dart';

/// Scheda di creazione (pagina unica, D-04): un solo stato, mai azzerato dagli errori.
class CharacterCreationCubit extends Cubit<CharacterCreationState>
    with SafeEmit<CharacterCreationState> {
  CharacterCreationCubit(this._repository)
    : super(const CharacterCreationState());

  final CharacterCreationRepository _repository;

  Future<void> loadRaceTraits() async {
    emit(state.copyWith(raceTraitsStatus: RaceTraitsStatus.loading));
    try {
      final traits = await _repository.loadRaceTraits();
      emit(
        state.copyWith(
          raceTraits: traits,
          raceTraitsStatus: RaceTraitsStatus.loaded,
        ),
      );
    } catch (_) {
      emit(state.copyWith(raceTraitsStatus: RaceTraitsStatus.failed));
    }
  }

  void selectSex(SexType sex) => _editDraft(state.draft.copyWith(sex: sex));

  void updateName(String name) => _editDraft(state.draft.copyWith(name: name));

  void selectPronoun(PronounType pronoun) =>
      _editDraft(state.draft.copyWith(pronoun: pronoun));

  void selectRace(RaceType race) =>
      _editDraft(state.draft.copyWith(race: race));

  void selectClass(ClassType classType) =>
      _editDraft(state.draft.copyWith(classType: classType));

  void updateAge(String ageText) =>
      _editDraft(state.draft.copyWith(ageText: ageText));

  void updateBackground(String background) =>
      _editDraft(state.draft.copyWith(background: background));

  Future<void> pickPortrait(PortraitSource source) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(pickFailure: null));
    try {
      final path = await _repository.pickPortrait(source);
      if (path == null) return;
      emit(state.copyWith(portraitPath: path));
    } on PortraitPickException catch (error) {
      emit(state.copyWith(pickFailure: error.failure));
    }
  }

  void removePortrait() {
    if (state.isSubmitting) return;
    emit(state.copyWith(portraitPath: null, uploadedPortrait: null));
  }

  void _editDraft(CharacterDraft draft) {
    if (state.isSubmitting) return;
    emit(state.copyWith(draft: draft, submitFailure: null));
  }
}
