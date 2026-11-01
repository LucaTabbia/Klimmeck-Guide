---
phase: 10-admin-panel-innkeeper
plan: 11
subsystem: admin
tags: [flutter, graphql, schema-gate, device-e2e, innkeeper, teleport, bloc]

requires:
  - phase: BE Phase 10 (hardening)
    provides: "PendingRequestCharacter.pendingQuest: ID and QUEST_IN_PROGRESS on completePendingRequest (BE-HARD-08), merged on BE develop at 4dc7e89"
  - phase: 10-01..10-10
    provides: "queue models, documents, cubits, panel, completion form, teleport mode"
provides:
  - "pendingQuest selected in PendingRequestFragment (the D-07 hiding rule is live against the BE)"
  - "phase gates on the merged BE: schema check 42/42 OK, full suite green, analyzer 51/0/0"
  - "Android device E2E 10/10 pass («approved») with six product-rule fixes made during the UAT"
  - "ADMIN-01..08 complete; BACKEND-NOTES §6 for the BE"
affects: [phase-12-hardening, phase-13-city-shops, phase-17-unlockable-lore, be-phase-10-uat]

tech-stack:
  added: []
  patterns:
    - "Actionable-only queue: a card is listed only when every seat is covered and no participant is hidden, travelling or awaiting aid"
    - "Card-level teleport: one pawn «Gruppo · N», N sequential teleportCharacter calls"

key-files:
  created:
    - lib/screens/mainScreen/tabs/map/components/teleport_mode_badge.dart
    - .planning/phases/10-admin-panel-innkeeper/10-11-SUMMARY.md
  modified:
    - lib/graphql/fragments/pending_request_fragment.dart
    - lib/models/pending_request/request_card.dart
    - lib/models/pending_request/participant_presence.dart
    - lib/models/travel/teleport_target.dart
    - lib/screens/innkeeper/components/request_card_view.dart
    - lib/screens/innkeeper/components/participant_row.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart
    - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_state.dart
    - lib/screens/mainScreen/components/teleport_mode_landing.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_state.dart
    - lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - .planning/phases/10-admin-panel-innkeeper/10-HUMAN-UAT.md
    - .planning/phases/10-admin-panel-innkeeper/10-VALIDATION.md
    - .planning/phases/10-admin-panel-innkeeper/10-CONTEXT.md
    - .planning/phases/10-admin-panel-innkeeper/BACKEND-NOTES.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "UAT rule: one card per story request, a shared card only for a worldMission (D-05 amended)"
  - "UAT rule: the queue lists only actionable cards; a worldMission appears only when complete (D-06/C6, D-07 amended; partly-busy caption removed)"
  - "UAT rule: one «Teletrasporta» per card moving every participant (pawn «Gruppo · N», N sequential calls) (D-15/D-19 amended)"
  - "UAT rule: «Annulla» reopens the panel and the Map shows the «Modalità Locanda» badge (D-17 amended)"
  - "UAT rule: the Board stays after a story/worldMission accept; the map jump is for the standard lane only (Phase 6 D-03 noted)"
  - "UAT rule: a participant awaiting aid blocks (hides) his story/worldMission card"

patterns-established:
  - "Product rules found at the device E2E are fixed TDD on the phase branch and recorded as CONTEXT amendments"

requirements-completed: [ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-08]

duration: ~2h10m (Task 1 18:04 → record 20:11, device E2E included)
completed: 2026-11-01
---

# Phase 10 Plan 11: BE-HARD-08 gate, device E2E and phase close Summary

**`pendingQuest` selected against the merged BE (`4dc7e89`, schema check 42/42), Android device E2E 10/10 pass («approved») after six TDD fixes of the product rules given by the user during the session, ADMIN-01..08 complete.**

## Performance

- **Duration:** ~2h10m (gate, E2E with live fixes, record)
- **Started:** 2026-11-01T18:04+01:00 (`7f0ada5`)
- **Completed:** 2026-11-01T20:11+01:00
- **Tasks:** 3/3 (Task 1 auto, Task 2 human E2E checkpoint, Task 3 record)
- **Files modified:** 28 code/test files across Task 1 and the UAT fixes (1 created), 8 planning files

## Task 1 — BE gate and phase gates (commits `7f0ada5`, `df9ccc1`, `8349295`, `d5df824`)

BE `origin/develop` = `4dc7e89` (Merge pull request #16 from `feat/10-hardening`). Block-level gate:

```
type PendingRequestCharacter {
  activeTravel: ActiveTravel
  awaitingAid: AwaitingAid
  id: ID!
  location: ID!
  name: String!
  pendingQuest: ID
  title: String!
}
```

- RED `7f0ada5` (`test(admin): expect the busy-lane field in the queue`): the documents test flipped to «contains `pendingQuest`» plus the merged-shape fixture (busy lane and explicit null lane); the documents test failed until the fragment selected the field.
- GREEN `df9ccc1` (`feat(admin): select the busy standard lane of queued characters`): one `pendingQuest` line under `character` in `PendingRequestFragment`, doc comment naming D-07.
- Schema check: «dumped 42 documents», 42 `OK` / 0 failures against `origin/develop:src/schema.gql` at `4dc7e89`.
- Full `flutter test`: **2833 passed** at Task 1; **2852 passed** after the UAT fixes.
- Repo-wide analyzer: **51 issues, 0 errors, 0 warnings** (gate ≤ 52), unchanged after the UAT fixes.
- DIRTY files: `quest_type.dart`, `injury_type.dart`, `asset_item.dart` untouched by the phase; `character_marker_layer.dart`, `map_utils.dart`, `city_markers_layer.dart` carry only the hand edits of 10-08/10-09 and are untouched by 10-11 and by the UAT fixes; no new file unformatted.
- Trailers: `git log develop..HEAD --format=%B | grep -c "Co-Authored-By\|Generated with"` = **0**.
- `8349295` filled `10-VALIDATION.md`; `d5df824` opened `10-HUMAN-UAT.md`.

## Task 2 — Device E2E (Android, BE `develop` `4dc7e89` local)

Verdict of the user: **«approved»**. All ten steps pass; results quoted in `10-HUMAN-UAT.md`.

| Step | Result | User's words / evidence |
|------|--------|-------------------------|
| 1 Role gate | pass | «aperto» (account already innkeeper) |
| 2 Live queue | pass after fixes | «dovrebbero essere 3…» → `f7c6dd1`; «pass»; no map jump → `9c54218` |
| 3 Free travel | pass, new rule | «Tutto giusto»; «non voglio vedere le card su cui non posso fare nulla» → `a919ade`; «sono visibili» |
| 4 Busy lane | pass | «caccia accettata»; `QUEST_IN_PROGRESS` from the stale client; abandon «è una scelta di design»; awaiting-aid rule → `abaf9b4` |
| 5 Teleport | pass | «funziona, i due personaggi sono a Talmvere»; badge + «Annulla» → «Confermo tutto» |
| 6, 7 Completions | pass | «Fatto entrambi i punti e hanno funzionato.» |
| 8 FORBIDDEN | pass | curl as adventurer → `FORBIDDEN` |
| 9 Audit | pass | completions, `QUEST_IN_PROGRESS`, 7 `teleportCharacter` rows |
| 10 Lifecycle | pass | background/foreground refresh after a curl completion; «approved» |

Requirement map: ADMIN-01 (1), ADMIN-02 (2, 3, 4), ADMIN-03 (4, 6, 7), ADMIN-04 (5), ADMIN-05 (7), ADMIN-06 (7), ADMIN-07 (1, 8), ADMIN-08 (9) → all eight pass.

## Fix durante la UAT (all TDD, test commit first)

| Commits | User rule implemented |
|---------|-----------------------|
| `6c5fe5a` + `f7c6dd1` | one card per story request; shared card only for a worldMission (`cardKeyOf`) |
| `4bf0866` + `9c54218` | the Board stays after a story/worldMission accept; map jump only for the standard lane |
| `635aab0` + `a919ade` + `327d83e` | the queue lists only actionable cards (all seats covered, nobody hidden, nobody travelling); worldMission only when complete |
| `30870b3` + `3067699` + `1565abe` + `616d726` | one «Teletrasporta» per card, pawn «Gruppo · N», N sequential `teleportCharacter` calls |
| `cff54eb` + `25294e2` | «Modalità Locanda» badge on the Map; «Annulla» reopens the panel via `TeleportCancelled` |
| `ba1a77d` + `abaf9b4` + `660e7b0` | a participant awaiting aid blocks the card |

Final gates after them: full `flutter test` 2852 passed, analyzer 51 issues / 0 errors / 0 warnings.

## Task 3 — Record

- `10-HUMAN-UAT.md` `status: complete`, 10 result cells, not-observed list, fixes, session notes.
- `10-VALIDATION.md` rows 10-11-02/03 `✅ green`, `nyquist_compliant: true`, `status: approved`, approved 2026-11-01.
- `requirements mark-complete` ADMIN-01..08 (checkboxes verified), traceability row `Complete (… merged 4dc7e89; Android device E2E 2026-11-01)`.
- ROADMAP: 11/11 plans ticked, phase line completed 2026-11-01, ADMIN rows `Complete`, Progress Table `11/11 | Complete | 2026-11-01`.
- `10-CONTEXT.md` block «Amended (UAT 2026-11-01)»; `BACKEND-NOTES.md` §6 for the BE.
- STATE: Phase 10 complete, BE-HARD-08 open item resolved with `4dc7e89`, next = FE PR then BE 11 → FE 13 … FE 12 last.

## Deviations from Plan

### Rule changes vs CONTEXT (user decisions at the E2E, not auto-fixes)

1. **Queue shape (D-05):** one card per story request instead of one card per quest; shared card only for a worldMission.
2. **Actionable-only queue (D-06/C6, D-07):** a free traveller is no longer shown greyed; cards with a travelling, busy, hidden or awaiting-aid participant are hidden, a worldMission appears only complete; the partly-busy caption default is removed and the all-busy worldMission default is superseded.
3. **Teleport per card (D-15/D-19, D-17):** one group pawn per card with N sequential calls; «Annulla» reopens the panel; «Modalità Locanda» badge. Also Phase 6 D-03: no map jump after a story/worldMission accept.

The FORBIDDEN SnackBar default (D-04/C8) stays, confirmed by absence of veto.

### Not observed on the device

- Step 1 «before the promotion» half (account already innkeeper).
- Step 4 abandoning the hunt (by design a started hunt cannot be abandoned).
- Step 5 teleport during a free travel; tab change during the teleport mode.
- Step 10 push tap with the panel open (optional).

## DB seeds used for the UAT (no ids, no secrets)

Two fresh characters (one per account) teleported to Talmvere; channel points seeded on both accounts; worldMission seats lowered to 2 for the session and restored; a free travel shortened and a hunt expired in the DB; the character who lost the hunt healed in the DB (aid quest removed); the second character raised to mage with one active spell and two consumables for step 7. An older character was unlinked from the account at the user's request and stayed out of the UAT.

## Issues Encountered

- «Failed host lookup: 'localhost'» (WebSocket closed) logged a few times with the adb tunnel and the BE up; no step failed; to clarify with the user (Wi-Fi / airplane mode?). Recorded in STATE open questions.
- BE observations routed in BACKEND-NOTES §6.4 (audit target of `teleportCharacter`, stale unowned pending excluded with a WARN, rookie vs 100 HP enemy, list queries on unpopulated ids).

## Known Stubs

None.

## Next

FE PR `feat/10-admin-panel` → `develop` (orchestrator, `--base develop`, never `main`); mention in the PR the D-04 SnackBar default, the superseded D-07 defaults, the shared pawn drag extraction, the `confirmButtonStyle` dialog parameter, the `isTeleportMode` flag and the BE Phase 10 dependency (`4dc7e89`).

## Self-Check: PASSED

Files found: `10-11-SUMMARY.md`, `10-HUMAN-UAT.md`, `teleport_mode_badge.dart`. Commits found: `7f0ada5`, `df9ccc1`, `8349295`, `d5df824`, the 17 UAT fix commits `6c5fe5a`..`660e7b0`, `a44536a`.
