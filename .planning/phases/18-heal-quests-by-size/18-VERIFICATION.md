---
phase: 18-heal-quests-by-size
verified: 2026-11-10T11:50:00Z
status: human_needed
score: "5/5 ROADMAP success criteria verified in code and tests for plans 18-01..18-11 (SC 3 and the device halves of SC 4/5 wait for the gated plans 18-12 and 18-13)"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "The seven contract names (type QuestCure, injuriesHealed, noEffect, type LootRecovery, potionRecoveryUntil, useItem(, type UseItemResult) proved on the merged BE Phase 18 SDL"
    addressed_in: "Plan 18-12"
    evidence: "REPO-RULES §Gate / CONTEXT D-07: gated by the BE Phase 18 merge; the BE phase is being executed in the other repo"
  - truth: "The four fragment selections (cure { lifePointsShare canHeal }, noEffect, injuriesHealed, recovery { time turns }, potionRecoveryUntil) added to the shared fragments"
    addressed_in: "Plan 18-12"
    evidence: "18-12-PLAN: fragments must not select fields a pre-Phase-18 BE rejects; verified by grep that lib/graphql/fragments selects none of them yet (only the UseItem mutation document, registry 46, exists)"
  - truth: "46/46 documents validated against the merged BE schema (schema gate)"
    addressed_in: "Plan 18-12"
    evidence: "18-VALIDATION row 18-12-02: dump_documents.dart + validate_documents.js on the merged schema"
  - truth: "Gate full suite, repo-wide analyzer, format/trailer/product-rule greps and 18-VALIDATION.md approval"
    addressed_in: "Plan 18-12"
    evidence: "18-VALIDATION rows 18-12-03; Sign-Off and Approval still pending"
  - truth: "18-HUMAN-UAT.md, BACKEND-NOTES.md, HEAL-01..06 ticked in REQUIREMENTS.md, ROADMAP/STATE closure, VALIDATION sign-off (HEAL-03 is the device UAT requirement)"
    addressed_in: "Plan 18-13"
    evidence: "18-13-PLAN: device E2E with a player identity as a blocking human checkpoint; requirements ticked only on passed steps; gated by 18-12"
human_verification:
  - test: "1. Village - sheet. Character in a village with HP below half and two seeded injuries, one in the village list (e.g. «contusione») and one not (e.g. «cecità»). On the Board open the temple heal: the announcement paper with its description and «Tempo richiesto» of the village; «Cura le tue ferite: contusione» (only the listed one, lowercase) and «Vita: almeno il 50%» (HEAL-01, HEAL-03; D-03, D-04)"
    expected: "Paper, description, village time; only the listed injury in the cure line; life row at 50%"
    why_human: "needs the merged BE, the content by city size at DB, a player identity and orchestrator seeds"
  - test: "2. Village - result. Accept it (time shortened by the orchestrator): the result sheet shows the HP bar rising in green to half of the maximum and «Guarite: contusione» between the bar and the injuries; in the Journal the unlisted injury is still there and the HP is at 50 % (HEAL-02, HEAL-03; D-06)"
    expected: "HP to 50%, «Guarite: contusione», unlisted injury still in the Journal"
    why_human: "real BE resolution of the quest (injuriesHealed) and animation review"
  - test: "3. City. Character moved to a city with HP below 80 % and two seeded injuries (one in the city list, one only in the capital list): the sheet shows the cure line with the listed one and «Vita: almeno l'80%»; the result shows HP to 80 % and «Guarite: …» with that injury only (HEAL-01, HEAL-02, HEAL-03)"
    expected: "Listed injury only; HP to 80%"
    why_human: "real content by size and BE cure"
  - test: "4. Capital. Character moved to a capital with several seeded injuries and low HP: the sheet lists every injury of the character and «Vita: al massimo»; the result shows HP full and «Guarite: …» with all of them; the Journal shows no injury (HEAL-01, HEAL-02, HEAL-03)"
    expected: "All injuries listed and healed, HP full"
    why_human: "real content by size and BE cure"
  - test: "5. No cure, no rows. In the same city open a quest without a cure (a hunt or a job): neither «Cura le tue ferite» nor «Vita» (HEAL-01; D-05)"
    expected: "No cure rows"
    why_human: "needs real quests from the BE with prizes.cure null"
  - test: "6. Useless heal torn. The character is now healthy (HP full, no injury) in a city: the temple sheet is still in its place on the Board but drawn torn; open it: it says «Il tempio non può fare nulla per te adesso», the swipe does nothing and nothing is accepted (HEAL-06; D-20)"
    expected: "Torn inert sheet with the fixed line, nothing accepted"
    why_human: "per-viewer noEffect computed by the BE on the real character; torn paper is a provisional visual to review"
  - test: "7. Whole again. With the Board open, the orchestrator seeds an injury of that temple's list (or lowers the HP): without leaving the Board and without any spinner the temple sheet is whole again; it can be opened and torn to accept (HEAL-06; D-20)"
    expected: "Sheet whole again live, no spinner, acceptable"
    why_human: "needs the live characterUpdated + silent quests reread against the real BE and a DB seed"
  - test: "8. «Ricarica» rows. In the shop of a city and in the Journal «Oggetti» the heal potions show «Cura: …» and under it «Ricarica: …» (the field herb: «Ricarica: 30 min»); the other items show no such line (HEAL-05; D-13, D-17)"
    expected: "Recovery rows only on heal potions"
    why_human: "recovery content lives at DB and is served by the real BE"
  - test: "9. Drink a field herb. Character with HP below the maximum and one injury the herb cures, no recovery in course. Journal «Oggetti»: tap the herb parchment → a parchment sheet «Bevi <nome>?» with its «Cura: …» and «Ricarica: …» lines and the actions «Bevi» / «Non ora»; «Non ora» closes it and nothing changes; tap again and «Bevi»: no spinner, the same sheet shows the HP bar rising in green, «Guarite: …» and «Conoscenza appresa: Il limite del corpo»; «Continua» closes it; in the Journal the HP and the stack are updated without any reload (HEAL-04; D-11, D-18)"
    expected: "Confirmation, HP gain, Guarite and lore line on the same sheet, state updated from the stream"
    why_human: "real useItem against the merged BE, animation and layout review on the phone"
  - test: "10. Countdown. Right after step 9 every heal parchment of «Oggetti» is dimmed with «pronta fra …» (about 30 min) and a tap on any of them does nothing; send the app to the background and back: the countdown is coherent (HEAL-05; D-12)"
    expected: "Dimmed parchments with countdown, coherent after background/foreground"
    why_human: "real clock and app lifecycle"
  - test: "11. Lore. Library: the «Conoscenze» book has the «Nuovo» bookmark and the page «Il limite del corpo» (HEAL-04; D-16)"
    expected: "Bookmark and page present"
    why_human: "Phase 17 flow against the real BE with the lore at DB"
  - test: "12. Second potion - orchestrator's probe. During the countdown the orchestrator sends `useItem` for a heal potion with the player's bearer: the answer is a refusal with `extensions.code` `POTION_RECOVERING` and an `extensions.recoveryUntil` equal to the recovery end; inventory and HP unchanged. Recorded from the orchestrator's words (the disabled parchment never sends the call, D-19) (HEAL-05; D-12, D-19)"
    expected: "POTION_RECOVERING with recoveryUntil, inventory and HP unchanged"
    why_human: "the call is unreachable from the disabled parchment; GraphQL probe by the orchestrator with a real bearer"
  - test: "13. No effect. The orchestrator clears the recovery end and leaves the character with full HP and no injury the herb cures: tap the herb → «Bevi» → the sheet closes and the parchment banner «Pozione non bevuta» says «Questa pozione non ti farebbe nulla adesso»; the stack is unchanged and no countdown starts (HEAL-04; D-11)"
    expected: "Banner with the fixed copy, stack unchanged, no countdown"
    why_human: "ITEM_NO_EFFECT from the real BE and banner timing"
  - test: "14. In travel. With the recovery end cleared, HP below the maximum and a travel in course (started by the orchestrator's seed or by the user from the Map): from the Journal the herb can be drunk exactly as in step 9 (HEAL-04; D-11)"
    expected: "Herb drinkable in travel"
    why_human: "needs a real travel state on the BE"
  - test: "15. (optional) Awaiting aid. With the character awaiting aid (seeded): the heal parchments are not tappable and show no countdown (HEAL-04; D-11)"
    expected: "Parchments not tappable, no countdown"
    why_human: "needs an awaitingAid state seeded by the orchestrator"
---

# Phase 18: Heal Quests by City Size (frontend companion) - Verification Report

**Phase Goal:** Quest and result sheets consume `prizes.cure` and `injuriesHealed` (display filtering only, no game rule), and the heal potions are drunk from the Journal with the backend's global recovery (countdown, «Ricarica» rows, `useItem`), plus the per-viewer `noEffect` torn sheet; all content and rules owned by the backend (BE Phase 18).
**Branch:** feat/18-heal-quests-by-size @ 77e82cd (phase base f8d0929)
**Verified:** 2026-11-10T11:50:00Z
**Status:** human_needed
**Re-verification:** No, initial verification.
**Scope note:** plans 18-12 (schema gate on the merged BE SDL, fragment selections, 46/46 documents, gate full suite, VALIDATION approval) and 18-13 (device UAT, handoff, closure) are gated on the BE Phase 18 merge and have not run. Their must-haves are `deferred`, not gaps. The branch must never run against a BE without Phase 18: the fragments do not yet select the new fields, so until 18-12 the new UI is fed by parsers only and the live E2E cannot happen.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test test/models test/utils test/repository` | 1724 passed, All tests passed |
| `flutter test test/graphql test/tool test/shared` | 459 passed, All tests passed |
| `flutter test test/screens/mainScreen` | 1141 passed, All tests passed |
| `flutter test test/screens/auth` | 177 passed, All tests passed |
| `flutter analyze` | 47 issues, all info (0 error, 0 warning); baseline 47 held |
| `bash tool/hardening_check.sh` | hardening_check: OK |

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `QuestPrizes.cure` parsed leniently; sheet shows cure line (viewer's injuries only) and life row; no rows without a cure | VERIFIED (code and tests) | `lib/models/quest/quest_cure.dart`, `quest_prizes.dart`; `curableInjuriesLine` / `lifeShareLine` in `lib/utils/item_lines.dart` used by `quest_info_sheet.dart`; `characterInjuries` from `character_selectors.dart` fed by Board and Map; plan 18-01/03/04 tests green |
| 2 | Result sheet «Guarite: …» from `QuestResult.injuriesHealed`, lenient, after HP delta, before injuries added | VERIFIED (code and tests) | `healedLine` in `item_lines.dart` used by `quest_result_sheet.dart`; `quest_result.dart` lenient parse; tests green |
| 3 | Device UAT with player identity, one heal per size, schema gate on merged SDL | DEFERRED | plans 18-12/18-13 gated; human steps 1-5 |
| 4 | Journal heal parchment tappable, «Bevi <nome>?» confirmation, `useItem`, HP gain, «Guarite», lore line, refusals as notices, travel allowed, hidden while awaiting aid | VERIFIED in code and tests, device half deferred | `UseItem` document (`character_mutations.dart`, registry key `UseItem` in `schema_check_documents.dart`), `ItemUseRepository`, `ItemUseFailure` (`POTION_RECOVERING`, `ITEM_NO_EFFECT` from `extensions.code`), `PotionCubit`, `PotionSheet` («Bevi $name?»), `ItemsSection` opens it, `PotionOutcomeListener` + `potion_notice.dart` («Pozione non bevuta»), shared `lore_lines.dart`; wired in `authenticated_shell.dart` / `main_screen.dart` |
| 5 | Countdown «pronta fra …» on every heal parchment from the server date; «Ricarica: …» rows; lenient `LootRecovery` / `potionRecoveryUntil` | VERIFIED in code and tests, device half deferred | `loot_recovery.dart`, `character_status.dart`, `PotionRecoveryCubit` (server clock), `recoveryLine` / `potionReadyInLine` used by `item_row.dart`; tests green |
| 6 (HEAL-06, plan-added) | Per-viewer `noEffect` drawn as a torn inert sheet, silent reread on HP/injury change, `QUEST_NO_EFFECT` notice | VERIFIED in code and tests, device half deferred | `Quest.noEffect`, `questNoEffectLine`, `board.dart` `isEnabled: isIdle && !selected.noEffect`, `quest_acceptance_failure.dart` `QUEST_NO_EFFECT`, `quest_acceptance_notice.dart`, vitals reread in `quest_scope_listener.dart` / `quest_acceptance_outcome_listener.dart` |

**Score:** 5/5 ROADMAP criteria (plus HEAL-06) verified for the plans in scope; SC 3 and device halves are `deferred` / `human_verification`.

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| HEAL-01 | SATISFIED in code (device steps 1, 3, 4, 5 pending) | cure model, lines, sheet rows |
| HEAL-02 | SATISFIED in code (steps 2, 3, 4 pending) | `injuriesHealed`, `healedLine` |
| HEAL-03 | DEFERRED | device UAT and schema gate (18-12, 18-13); checkbox correctly still open |
| HEAL-04 | SATISFIED in code (steps 9, 11, 13, 14 pending) | useItem flow |
| HEAL-05 | SATISFIED in code (steps 8, 10, 12 pending) | recovery parsing, countdown, rows |
| HEAL-06 | SATISFIED in code (steps 6, 7 pending) | noEffect flow |

REQUIREMENTS.md still shows HEAL-01..06 as `[ ]` / Pending: correct, ticking is the job of 18-13. No orphaned requirements.

## Key Links

| From | To | Status |
|---|---|---|
| Board / Map | `QuestInfoSheet` cure rows via `characterInjuries` selector | WIRED |
| `QuestResultSheet` | `healedLine` | WIRED |
| `ItemsSection` | `PotionSheet` -> `PotionCubit` -> `ItemUseRepository` -> `UseItem` document | WIRED (document in registry, 46) |
| `ItemRow` | `recoveryLine` / `potionReadyInLine` | WIRED |
| shell / main screen | `PotionOutcomeListener`, `PotionRecoveryCubit` provider | WIRED |
| shared quest/character/loot fragments | new fields (`cure`, `noEffect`, `injuriesHealed`, `recovery`, `potionRecoveryUntil`) | NOT YET SELECTED, intentionally: plan 18-12 (deferred) |

## Anti-Patterns Found

None blocking. Code-quality remarks belong to the parallel code reviews, not to this report.

## Gaps Summary

No gaps: everything promised by plans 18-01..18-11 exists, is wired and is covered by green tests. The fragment selections and schema gate are an explicit, documented gate (18-12), not a missed promise. Until they run, the new UI is dormant against a live BE (parsers lenient, fields absent), so the phase is not closable; the human device UAT (15 steps, 18-13) decides HEAL-03 and the device halves of HEAL-01/02/04/05/06.

---

_Verified: 2026-11-10T11:50:00Z_
_Verifier: Claude (gsd-verifier)_
