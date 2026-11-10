---
quick: 261110-cgd
title: Crime arrest (prison) and guard encounter
date: 2026-11-10
branch: feat/18-heal-quests-by-size
commits: [431c6ef, 479dbfe, 56f3470, 793ed8a, e6ef360, bf868b4, ee2e543, f36a1a3, 02d0c9a, 0732db3, fb77c94, 3f45727, 6998b40, c8b47cb, d264db4, a947100, 7496c98, 7147cdc]
status: complete (device UAT pending, plan 18-13; selections gated, plan 18-12)
---

# Quick task 261110-cgd — crime arrest and guard encounter

**Trigger (user, 2026-11-10), verbatim:**

- «Le quest study e crime non hanno grado di entrata, possono farlo tutti. Le quest crime fanno guadagnare bene, con poco tempo di attesa, ma quando accetti una quest crime hai una probabilità del 20% di venire arrestato. Questo mette il personaggio in fase di attesa, con segnalino sopra la pedina "In prigione" per 10 ore. Le quest guard hanno tutte come rango di ingresso paladin e hanno una percentuale del 20% di farti scontrare contro un nemico casuale che sia presente nelle city o all. In caso di sconfitta resti con 1 di vita in città (niente attesa di soccorso, come per le imboscate), in caso di vittoria ottieni il doppio del denaro dato dalla quest e l'xp del nemico.»
- «Se per il livello del personaggio non c'è un nemico in fascia allora si possono mettere 2 o 3 nemici […]. Quando finisci in prigione perdi anche il 25% delle tue monete. Le job anche devono essere tutte rookie»
- Answers: the arrest is rolled at the END of the quest, no prize; prison blocks EVERYTHING like waiting for aid (no quests, no travel, no shop; potions and Journal stay usable).

BE twin: branch `feat/18-quest-heal-per-taglia`, contract §1.6 of its `BACKEND-NOTES.md` (read-only from here). Not merged yet.

## Fragment policy: deferred to plan 18-12

Phase 18 plans 01–11 parsed `potionRecoveryUntil` / `injuriesHealed` / `noEffect` / `recovery` / `cure` leniently and left every fragment selection to the gated plan 18-12. This quick follows the same policy: the models parse the four new fields leniently, **no fragment selects them yet**, and `.planning/phases/18-heal-quests-by-size/18-12-PLAN.md` now carries them:

- schema gate names: `imprisonedUntil`, `arrested: Boolean!`, `coinsLost`, `guardEncounter` (in the `for` loop of the interfaces block and in the Task 1 `<verify>`);
- contract proof: `CharacterStatus.imprisonedUntil: DateTime` nullable, `QuestResult.arrested: Boolean!`, `coinsLost: Coins` nullable, `guardEncounter: Boolean!`;
- Task 2: `imprisonedUntil` right after `potionRecoveryUntil` in `statusFields`; `arrested`, `coinsLost { ${CoinsFragment.fields} }`, `guardEncounter` right after `injuriesHealed` in the quest result fragment; two new document tests and three acceptance greps.

Until 18-12 runs, the prison reaches the app only through the `CHARACTER_IMPRISONED` extension (the status field is not on the wire) and the result sheet lines stay dormant (`arrested`/`guardEncounter` read `false`).

## What changed, per screen

### Models (`lib/models`)

- `CharacterStatus.imprisonedUntil` (`DateTime?`, UTC, malformed → `null`), in `toJson`, `copyWith`, props.
- `QuestResult.arrested` (`== true`), `coinsLost` (`Coins?`, map only), `guardEncounter` (`== true`); lenient, in `toJson` and props.
- `QuestAvailability.imprisoned` right after `tornForOwner` (the owner's own lane quest keeps «Missione già accettata»), before every other check; `isSheetTorn` → always torn. `QuestViewer.imprisonedFor` (`Duration?`, `null` = free). `questImprisonedLine = 'Sei in prigione'` (models, like `questNoEffectLine`). `QuestSheetDetails.isImprisoned` (the widget completes the line; models import nothing from `lib/utils`).

### Prison state

- `lib/shared/bloc/server_deadline_countdown.dart` (new): the timing code extracted from `PotionRecoveryCubit` (server-clock countdown, rounded up to the minute, timer only while something remains, recomputed on clock resync). `PotionRecoveryCubit` now delegates to it (refactor, its 9 tests unchanged and green).
- `lib/screens/mainScreen/prisonCubit/` (new): `PrisonCubit` + `PrisonState(remaining)`. `followStatus(imprisonedUntil)` (character status) and `learnRelease(imprisonedUntil)` (refusal extension); the later of the two wins, a status without the field never erases a refusal date. Frees itself at the instant (no server sweep, no event). Provided by `AuthenticatedShell` on `ServerClockService`.
- `lib/screens/mainScreen/components/prison_status_listener.dart` (new): feeds `status.imprisonedUntil` on mount and on change; mounted in the `MainScreen` session chain under `QuestScopeListener`.

### Map

- `CharacterMarkerLayer`: label **«In prigione»** (`prisonLabelKey`) over the idle pawn while `PrisonState.isImprisoned`, built with the same `PawnLabel` marker as «In attesa di soccorso» (text only: the aid marker shows no time). The three label markers now share `_labelMarker` (Boy Scout). The pawn drag is blocked in prison; marker and block disappear at the release.

### Board

- Every sheet is torn in prison (except the owner's own lane quest, still `tornForOwner`); `canTear` is off (`canAccept` false). The open sheet reads **«Sei in prigione: uscirai fra 9 h 12 min»** (`prisonReleaseLine`, `lib/utils/prison_lines.dart`, same `formatGameDuration` «fra …» form as the potion «pronta fra …» line; «Sei in prigione» alone without a time). At the release the sheets turn whole again.

### Satchel / Shop

- `disabledSatchelPages(isImprisoned:)`: in prison only the **Shop** closes (board stays open to show the torn sheets — see deviations); `_isPageDisabled` uses the same input.

### Failures (four operations)

| Operation | Failure value | Release carried on | Notice (non-blocking `KGNotification` banner) |
|---|---|---|---|
| `acceptQuest` | `QuestAcceptanceFailure.imprisoned` | `QuestAcceptanceException.imprisonedUntil` → `QuestAcceptanceFailed.imprisonedUntil` | «Missione non accettata» / «Sei in prigione: uscirai fra …» via `QuestAcceptanceOutcomeListener` |
| `travelPreview`, `startTravel` | `TravelFailure.imprisoned` | `TravelException.imprisonedUntil` → `TravelFailed.imprisonedUntil` | «Viaggio non partito» / same line via `TravelOutcomeListener` |
| `doTransaction` | `TransactionFailure.imprisoned` | `TransactionError.imprisonedUntil` (read by `TransactionCubit`) | «Negozio non disponibile» / same line via `TransactionOutcomeListener`; no shopkeeper bubble line (like `shopNotInCity`) |

- `lib/repository/character_imprisoned.dart` (new): `characterImprisonedCode`, `imprisonedUntilExtension`, `imprisonedUntilFrom(OperationException)` (only with that code). `graphQlErrorInstant` (new, `graphql_error_code.dart`) is now shared by the potion `recoveryUntil` and the prison release (Boy Scout).
- Each listener feeds `PrisonCubit.learnRelease(...)` first, then announces with `PrisonCubit.state.remaining` (a stale client corrects itself; the time is the server's).
- `questTravelPreview` shares `travelFailureFrom` but the BE never refuses it in prison.

### Quest result sheet

- `lib/utils/quest_outcome_lines.dart` (new, pure): `arrestLine` → **«Sei stato arrestato.»** (no duration printed), `confiscatedCoinsOf` (server `coinsLost`, `null` when absent or zero) shown as section **«Monete confiscate»** with the existing `CoinsDisplay`, `guardEncounterLine` → **«Scontro durante la guardia: vittoria, paga raddoppiata»** / **«Scontro durante la guardia: sconfitta»**. Nothing is doubled or derived; the sheet never had an aid-wait copy and the lost-encounter test pins that no «soccorso» text appears. Order: after the dungeon stages, before the HP bar.

### Not changed

- Potions (`PotionSheet`, items section) and the Journal: not gated on prison (the items section still hides potions only on `awaitingAid`).
- `QuestScopeListener`: see deviations (decision 7).

## Pinned tests updated (RED-first)

- `test/models/quest/quest_availability_test.dart` «every availability has a torn decision»: table gains `QuestAvailability.imprisoned: (true, true)`.
- `test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart`: «every other failure stays in the shopkeeper bubble» and «only the off-city refusal has no bubble line» exclude `imprisoned` (title of the second → «only the off-city and prison refusals have no bubble line: they are banners (Phase 9 D-16, quick 261110-cgd)»); `dart format` reflowed the file's two long titles.
- Harnesses gaining a `PrisonCubit` provider: `board_test.dart`, `board_acceptance_test.dart`, `character_marker_layer_test.dart`, `main_screen_test.dart` (`pumpMainScreen`), `main_screen_quest_results_test.dart`, `world_map_travel_test.dart` (shared by the availability/teleport map tests); `MockPrisonCubit` in `test/helpers/mocks.dart`; fixtures `arrestResultJson`, `guardEncounterResultJson`, `travellingCharacterJson(imprisonedUntil:)`, `buildViewer(imprisonedFor:)`.

## TDD (RED failures observed)

| RED | Failure | GREEN |
|---|---|---|
| 431c6ef models | `getter 'imprisonedUntil' isn't defined for CharacterStatus`, `getter 'arrested' isn't defined for QuestResult` | 479dbfe |
| — | refactor only (potion countdown tests green before and after) | 56f3470 |
| 793ed8a prison | `Error when reading prison_cubit.dart`, `Method not found: 'PrisonCubit'` | e6ef360 |
| bf868b4 repository | `Error when reading character_imprisoned.dart`, `Method not found: 'imprisonedUntilFrom'` / `'questAcceptanceExceptionFrom'` | f36a1a3 |
| ee2e543 notices | `Error when reading prison_lines.dart`, `Method not found: 'prisonReleaseLine'`, no `imprisoned` member / `imprisonedFor` parameter | f36a1a3 |
| 02d0c9a refusal states | `No named parameter with the name 'imprisonedUntil'` (QuestAcceptanceFailed, TravelFailed) | 0732db3 |
| fb77c94 listeners | `Error when reading prison_status_listener.dart`; the three «prison refusal feeds the prison» tests fail (no `learnRelease`, generic copy) | 3f45727 |
| 6998b40 board | `No named parameter 'imprisonedFor'`, `Member not found: 'imprisoned'`, `getter 'isImprisoned' isn't defined` | c8b47cb |
| d264db4 map/satchel | `named parameter 'isImprisoned' isn't defined`, `getter 'prisonLabelKey' isn't defined` | a947100 |
| 7496c98 result sheet | `Error when reading quest_outcome_lines.dart`, `Method not found: 'arrestLine'` | 7147cdc |

New tests: 69 (suite 3934 → 4003), all titled `(quick 261110-cgd)` (plus the retitled transaction pin).

## Gates

- Full suite `flutter test -r expanded`: **4003 tests, All tests passed** (3934 before).
- `flutter analyze --no-fatal-infos`: **47 issues (info only), 0 error, 0 warning** (baseline).
- `bash tool/hardening_check.sh`: **OK**.
- Trailer check on `2f17c14..HEAD`: **0**. Longest subject: 66 bytes. Every added/modified Dart file format-clean. `git status --short` after each commit: only ` M pubspec.lock`.

## Deviations

1. **Board reachable in prison (decision 4 vs the code).** Today `awaitingAid` gates the Board at satchel level (the whole page is disabled), not per sheet. Gating prison the same way would make the torn-sheet rule and the «Sei in prigione: uscirai fra …» reason unreachable, so the specific design of decision 4 was followed: the Board stays open with every sheet torn and non-tearable; only the Shop closes in the satchel. Travel is blocked on the pawn like aid. If the Board page should close too, it is one argument in `disabledSatchelPages`.
2. **Decision 7 not implemented: contradicted by the code.** `QuestScopeListener` does not re-read vitals after a heal result; it re-reads the `quests` list when `characterUpdated` changes the scope (location, title, lanes, and in a city vitals/injuries). The new character state after an arrest or a guard encounter arrives from the character stream (BE change stream), as for the potions (no refetch). The lost guard encounter (HP 1 in city) already re-reads the list through the existing vitals scope; prison does not change what `quests` returns (the Board tears locally). No second listener, no new refetch.
3. «Existing coins formatter»: the app has no text coin formatter, only the `CoinsDisplay` widget; «Monete confiscate» is a section title followed by `CoinsDisplay` (same layout as «Ricompense»).
4. «Aid-wait copy» on the result sheet: none exists; the lost-encounter widget test pins its absence.
5. Two RED tests fixed in their GREEN commits: the transaction cubit RED matcher called `.having` on a `Matcher` (rewritten as `isA<TransactionError>()…`, 0732db3); the board «at the release» RED test stubbed `state` over `whenListen` and pumped once (stub dropped, second pump added, c8b47cb). The quest outcome lines RED test had an unused fixture import, removed in 7147cdc.
6. The release-time copy «Sei in prigione: uscirai fra …» is gender-neutral on purpose (provisional, like every label).

## Device UAT (plan 18-13)

Only after plan 18-12 (fragments selected, BE merged):

1. **Marker:** arrest a character (crime result with `arrested: true`) → «In prigione» floats over the pawn on the map; the pawn cannot be dragged.
2. **Board in prison:** every sheet torn; opening one shows «Sei in prigione: uscirai fra …» and the swipe resists.
3. **Travel blocked:** no drag; a stale client that previews a trip gets the «Viaggio non partito» banner with the release time.
4. **Shop blocked:** the satchel Shop cell is disabled; a stale transaction shows the «Negozio non disponibile» banner with the release time.
5. **Potions and Journal still usable** while imprisoned.
6. **Result sheet, three cases:** arrest («Sei stato arrestato.», «Monete confiscate» with the coins, no rewards, no duration); guard won («Scontro durante la guardia: vittoria, paga raddoppiata», rewards as served); guard lost («Scontro durante la guardia: sconfitta», HP 1, no aid wait, no «soccorso»).
7. **Self-release at the instant:** with `imprisonedUntil` moved a few minutes ahead, the marker disappears, the Board sheets turn whole and the Shop cell reopens without any refetch or loading.
