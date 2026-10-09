part of 'character_creation_cubit.dart';

enum RaceTraitsStatus { loading, loaded, failed }

const Object _unset = Object();

/// URL già caricato per un file locale: riusato al retry solo se il file è lo stesso (D-30).
final class UploadedPortrait extends Equatable {
  const UploadedPortrait({required this.localPath, required this.url});

  final String localPath;
  final String url;

  @override
  List<Object?> get props => [localPath, url];
}

final class CharacterCreationState extends Equatable {
  const CharacterCreationState({
    this.draft = const CharacterDraft(),
    this.raceTraits = const {},
    this.raceTraitsStatus = RaceTraitsStatus.loading,
    this.portraitPath,
    this.uploadedPortrait,
    this.isSubmitting = false,
    this.submitFailure,
    this.pickFailure,
    this.createdUser,
  });

  final CharacterDraft draft;
  final Map<RaceType, RaceTraits> raceTraits;
  final RaceTraitsStatus raceTraitsStatus;
  final String? portraitPath;
  final UploadedPortrait? uploadedPortrait;
  final bool isSubmitting;
  final CharacterCreationFailure? submitFailure;
  final PortraitPickFailure? pickFailure;
  final User? createdUser;

  RaceTraits? get selectedRaceTraits {
    final race = draft.race;
    return race == null ? null : raceTraits[race];
  }

  bool get isAgeEnabled => selectedRaceTraits != null;
  NameError? get nameError => draft.nameError;
  AgeError? get ageError => draft.ageErrorFor(selectedRaceTraits);
  bool get canSubmit =>
      !isSubmitting && createdUser == null && draft.isCompleteFor(raceTraits);

  CharacterCreationState copyWith({
    CharacterDraft? draft,
    Map<RaceType, RaceTraits>? raceTraits,
    RaceTraitsStatus? raceTraitsStatus,
    Object? portraitPath = _unset,
    Object? uploadedPortrait = _unset,
    bool? isSubmitting,
    Object? submitFailure = _unset,
    Object? pickFailure = _unset,
    Object? createdUser = _unset,
  }) => CharacterCreationState(
    draft: draft ?? this.draft,
    raceTraits: raceTraits ?? this.raceTraits,
    raceTraitsStatus: raceTraitsStatus ?? this.raceTraitsStatus,
    portraitPath: identical(portraitPath, _unset)
        ? this.portraitPath
        : portraitPath as String?,
    uploadedPortrait: identical(uploadedPortrait, _unset)
        ? this.uploadedPortrait
        : uploadedPortrait as UploadedPortrait?,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    submitFailure: identical(submitFailure, _unset)
        ? this.submitFailure
        : submitFailure as CharacterCreationFailure?,
    pickFailure: identical(pickFailure, _unset)
        ? this.pickFailure
        : pickFailure as PortraitPickFailure?,
    createdUser: identical(createdUser, _unset)
        ? this.createdUser
        : createdUser as User?,
  );

  @override
  List<Object?> get props => [
    draft,
    raceTraits,
    raceTraitsStatus,
    portraitPath,
    uploadedPortrait,
    isSubmitting,
    submitFailure,
    pickFailure,
    createdUser,
  ];
}
