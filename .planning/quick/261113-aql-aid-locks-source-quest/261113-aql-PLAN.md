---
phase: quick-261113-aql
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/quest/quest.dart
  - lib/models/quest/quest_availability.dart
  - lib/models/quest/quest_blocked_reason.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/graphql/fragments/quest_fragment.dart
  - test/helpers/fixtures/quest_fixtures.dart
  - test/models/quest/quest_test.dart
  - test/models/quest/quest_availability_test.dart
  - test/models/quest/quest_blocked_reason_test.dart
  - test/screens/mainScreen/tabs/board/board_test.dart
  - test/graphql/board_documents_test.dart
autonomous: true

must_haves:
  truths:
    - "A hunt or a dungeon served with awaitingRescue: true is not acceptable and drawn torn for every viewer, whatever its title, and without a viewer title"
    - "Its open sheet prints «Soccorso in corso: la missione riapre quando il soccorso si conclude.» and ignores the swipe"
    - "The same quest with awaitingRescue false or absent is judged as before"
    - "The app only reads the served boolean: no lock is derived from the aid quests"
  artifacts:
    - path: "lib/models/quest/quest.dart"
      contains: "awaitingRescue"
    - path: "lib/graphql/fragments/quest_fragment.dart"
      contains: "awaitingRescue"
---

# Quick 261113-aql: a quest with an open rescue born from it is torn for everyone (FE)

**User rule (2026-11-13), verbatim:**

> «Quando un personaggio attiva una aid a partire da una hunt o da un dungeon (quindi le uniche quest ripetibili che possono creare una aid) la quest che le ha generate deve risultare strappata e quindi non accettable, finché il soccorso non va a buon fine.»

**User answers to two orchestrator questions (options picked by the user, 2026-11-13):**

1. The source quest is locked **for everyone** (not only for the wounded character).
2. It **becomes free again whenever the aid closes**: rescue done, wounded dead by timeout, wounded archived. A lost rescue opens a new aid from the same quest and the lock continues.

**Superseded decision:** this replaces D-15 of Phase 20 (`20-CONTEXT.md`) and of BE Phase 21 («no lock of the dungeon for others while the aid is open (today's behaviour)»). From now on the dungeon (or hunt) that generated an open aid is locked for every viewer.

BE twin: quick `261113-aql` on the BE repo, branch `feat/quick-aid-locks-source-quest` (read-only from here, not awaited).

## Contract (fixed by the orchestrator)

| On the wire | Meaning |
|-------------|---------|
| `Quest.awaitingRescue: Boolean!` (additive) | `true` for a hunt/dungeon with an open aid born from it, `false` for every other quest; the same for every viewer |
| `acceptQuest` on such a quest | refused with the existing code `QUEST_NOT_ACCEPTABLE` (→ `QuestAcceptanceFailure.notAcceptable`, no new code) |
| `questUpdated` | republishes the source quest when the aid is born and when it closes |

The backend is the source of truth: the FE reads the boolean, never derives the lock from the list of aids.

## Design (pattern of `noEffect`, BE Phase 18 D-20)

- `Quest.awaitingRescue` (`bool`, lenient: `json['awaitingRescue'] == true`) in `fromJson`, `toJson`, `copyWith`, `props`.
- `QuestAvailability.awaitingRescue`: torn (`isSheetTorn` → `true`), not acceptable.
- Precedence in `_availabilityOf`: after `tornForOwner`, `imprisoned` and the catalogue checks (`type == null`, `_isCatalogueDefect`), before every other viewer-dependent check (`alreadyDone`, `titleMismatch`, `laneBusy`, `full`, `notInCity`, `insufficientPoints`, `noEffect`). So every viewer that is not the lane owner and not in prison sees the same reason, whatever title, lane, city or balance.
- Reason line (orchestrator's copy, amended by IN-03 of `20-REVIEW-UAT.md`): `questAwaitingRescueLine = 'Soccorso in corso: la missione riapre quando il soccorso si conclude.'` next to `questNoEffectLine` in `quest_blocked_reason.dart`.
- Board: the open sheet is not draggable (`isEnabled` false) like a `noEffect` sheet.
- Fragment: `awaitingRescue` selected once in `QuestFragment.fields` (used by `quests` and `OnQuestUpdated`). No schema gate against the BE here: the BE `develop` SDL has no such field until the twin is merged; the orchestrator runs the schema check after that merge.
- Nothing in `QuestScopeListener`: the change arrives on `questUpdated`, not on `characterUpdated`.

## Tests (titles carry «quick 261113-aql»)

1. `quest_test.dart`: `true` read; absent / malformed (`'true'`, `1`, `null`, `{}`) → `false`; `toJson` / `fromJson` round trip, `copyWith`, `props`.
2. `quest_availability_test.dart`: hunt and dungeon with `awaitingRescue: true` → `awaitingRescue`, torn, not acceptable, for every title and for a viewer without title; with a busy lane, out of city, poor balance still `awaitingRescue`; `false` / absent unchanged; no travel preview; torn-sheet table extended.
3. `quest_blocked_reason_test.dart`: the reason line text.
4. `board_test.dart`: a locked dungeon is drawn torn, its open sheet prints the reason, ignores the swipe and never calls accept; an unlocked one is whole; when `questUpdated` clears the flag the sheet is whole and tearable again.
5. `board_documents_test.dart`: `awaitingRescue` selected exactly once in `QuestFragment.fields`.

## Gates

Targeted `flutter test test/models/quest test/repository test/shared/components/popup test/screens test/graphql` in the foreground, `flutter analyze --no-fatal-infos` (47 info / 0 warning / 0 error).

## Out of scope

Schema check against the BE (after the BE merge), new error codes, any client inspection of aid quests, the map sheet (it shows only the character's own lane quest, no availability), ROADMAP / REQUIREMENTS / VALIDATION.

## Amendments after the review of the UAT fixes (2026-11-13, `20-REVIEW-UAT-FIX.md`)

- IN-03: the reason line was «Soccorso in corso: la missione riapre quando il ferito è stato raggiunto.» (technical default); it now reads «Soccorso in corso: la missione riapre quando il soccorso si conclude.», true for every way the aid closes.
- WR-01: the Board does not subscribe `questUpdated` for a listed quest (the subscription takes one `questId` and `QuestCubit` follows only the viewer's own waiting lane quest), so the lock is not live on an open Board. A refused swipe (`QUEST_NOT_ACCEPTABLE` → `notAcceptable`) now silently rereads `quests`, so the sheet turns torn with its reason; a lock that starts or ends while the Board is open shows at the next list read (Board opening, scope change of the viewer, refused swipe). The Board test once named after `questUpdated` is now «when a reread list drops the lock…», paired with «when a reread list brings the lock…».
