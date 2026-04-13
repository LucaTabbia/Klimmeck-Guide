# Naming conventions

## File Dart

- **`snake_case.dart`** per tutti i file. Esempi: `active_spell.dart`, `cached_svg.dart`, `character_cubit.dart`.

## Directory

- **lowerCamelCase** per feature directory e sotto-cartelle di stato: `mainScreen/`, `onBoarding/`, `signIn/`, `characterCubit/`, `questCubit/`.
- **lowercase** per cartelle "tecniche" top-level: `config/`, `graphql/`, `models/`, `repository/`, `routes/`, `screens/`, `shared/`, `theme/`, `utils/`, `test/`.
- **snake_case** per sotto-cartelle dentro `models/` che raggruppano per dominio: `models/character/`, `models/quest/`, `models/enums/`, `models/request/`.

## Classi Dart

- **`PascalCase`** sempre: `CharacterCubit`, `QuestInfoSheet`, `CachedSvg`, `EnemyDamage`.
- **Suffissi obbligatori per stato:**
  - BLoC: `XxxBloc` + `XxxEvent` (classe base astratta) + `XxxState` (classe base astratta)
  - Cubit: `XxxCubit` + `XxxState`
  - Sottostati: `XxxInitial`, `XxxLoading`, `XxxLoaded`, `XxxError`, oppure stati di dominio parlanti (`QuestAccepting`, `TravelInProgress`).
- **Widget:** nome parlante senza suffisso `Widget` (`QuestCard`, non `QuestCardWidget`). Suffisso ammesso solo se rimuove ambiguità con un modello (`SpellDisplay` vs `Spell`).
- **Screen:** suffisso `Screen` (`MainScreen`, `SignInScreen`, `SplashScreen`).
- **Repository/Service:** suffisso `Repository` o `Service` (`CharacterRepository`, `GraphqlClientProvider`).

## Variabili, funzioni, parametri

- **`lowerCamelCase`** sempre: `channelPoints`, `acceptQuest()`, `onTapAccept`.
- **Private:** prefisso `_` per membri private nella stessa libreria: `_client`, `_fetchCharacter()`.
- **Costanti:** `lowerCamelCase` per `const` di istanza/top-level (`defaultTimeout`). `SCREAMING_SNAKE_CASE` **non** si usa in Dart.
- **Booleani:** prefisso verbo modale: `isLoading`, `hasError`, `canAccept`, `shouldRefresh`.

## Enums

- **`PascalCase`** per tipo, **`lowerCamelCase`** per valori: `enum QuestType { hunt, enemy, boss, dungeon, heal, aid, job, study, story, worldMission }`.

## GraphQL

- **Operazioni:** `PascalCase` con verbo esplicito: `GetCharacter`, `AcceptQuest`, `OnCharacterChanged`.
- **File query/mutation/subscription:** `<domain>_<kind>.dart` (es. `character_queries.dart`, `quest_mutations.dart`).
- **Variabili GraphQL:** `lowerCamelCase`.

## Asset

- **`snake_case`** per nomi file: `quest_pawn_red.svg`, `injury_bleeding.svg`.
- Ordinamento per dominio in `assets/` (vedi `docs/rules/assets.md`).

## Test

- **`<target>_test.dart`**: `character_cubit_test.dart`, `quest_card_test.dart`.
- Describe block in inglese, case italiano ammesso se descrive dominio di gioco.

## Anti-pattern

- Nomi generici: `data`, `info`, `manager`, `helper`, `utils` per classi → vietato.
- Abbreviazioni non standard: `chr` per character, `qst` per quest → vietato.
- Prefissi tipo ungherese (`strName`, `bIsLoading`) → vietato.
