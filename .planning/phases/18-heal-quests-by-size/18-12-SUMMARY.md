---
phase: 18-heal-quests-by-size
plan: 12
subsystem: graphql
tags: [graphql, fragments, schema-gate, validation, tdd]
requires: ["18-09", "18-11", "quick 261110-cgd"]
provides:
  - "QuestFragment.fields selects noEffect (before prizes) and prizes.cure { lifePointsShare canHeal } (after pet)"
  - "QuestResultFragment.fields selects injuriesHealed arrested coinsLost { gold silver copper } guardEncounter right after injuriesAdded"
  - "LootFragment.fields and LootFragment.definition select recovery { time turns } after sellPrice; simpleFields untouched"
  - "CharacterFragment.statusFields selects potionRecoveryUntil imprisonedUntil right after awaitingAid"
affects: [18-13]
tech-stack:
  added: []
  patterns: ["gated fragment selection after the BE merge (13-10 / 14-10 / 15-08 / 16-07 / 17-09)"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/quest_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/graphql/fragments/loot_fragment.dart
    - lib/graphql/fragments/character_fragment.dart
    - test/graphql/board_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/graphql/character_fragment_test.dart
    - .planning/phases/18-heal-quests-by-size/18-VALIDATION.md
decisions:
  - "Names confirmed on the merged BE SDL (origin/develop 66df2ef2): no rename, no nullability difference"
  - "Commit scopes follow the user's rule `test(phase-18)` / `feat(phase-18)` instead of the plan's `test(graphql)` / `feat(graphql)`"
metrics:
  duration: "~20 min"
  completed: 2026-11-11
  tasks: 3
  files: 9
---

# Phase 18 Plan 12: Schema gate, fragment selections and validation Summary

The gate is open on BE `origin/develop` 66df2ef2 (merge of BE PR #31). All 11 contract names are present and match the REPO-RULES exactly. The four fragments now select the cure, `noEffect`, `injuriesHealed`, the potion `recovery`, `potionRecoveryUntil`, and the four prison/guard fields of quick 261110-cgd. 46/46 documents validate against the merged schema and the full suite has 4029 tests green.

**Pitfall 14:** from this plan on, the app selects fields that exist only on a BE with Phase 18 and quick 261110-cgd. This branch must never run against an older BE: every quest, result, item and character query would be rejected.

## Task 1: BE gate and contract proof

BE `git status --short` before and after: empty (unchanged). Only `show` / `log` / `ls-tree` were run on `origin/develop`. There was no fetch and no checkout.

Gate counts on `origin/develop:src/schema.gql`:

```
type QuestCure -> 1
injuriesHealed -> 2
noEffect -> 1
type LootRecovery -> 1
potionRecoveryUntil -> 1
useItem( -> 1
type UseItemResult -> 1
imprisonedUntil -> 1
arrested: Boolean! -> 1
coinsLost -> 1
guardEncounter -> 1
```

`git log --oneline -5 origin/develop`:

```
66df2ef2 Merge pull request #31 from LucaTabbia/feat/18-quest-heal-per-taglia
8d740307 Merge pull request #30 from LucaTabbia/docs/v1.1-milestone-start
b0f61c6b docs(state): list the magic, arrest and prison push quick tasks
5d6bd699 docs(quick-261110-prp): record the prison release push task
e50dba8c feat(characters): release prisoners on a sweep and push once per arrest
```

SDL extracts (the fields are in alphabetical order in the generated SDL):

```
type QuestCure { canHeal: [InjuryType!]!  lifePointsShare: Float! }
type QuestPrizes { cure: QuestCure  pet: Pet  prizeCoins: Coins  prizeItem: AssetQuantity  randomLoot: [AssetQuantity!]!  spell: Spell  xpPrize: Int }
type Quest { id: ID!  infos: QuestInfos!  noEffect: Boolean!  prizes: QuestPrizes!  registeredAdventurers: [QuestRegistration!]!  requirements: QuestRequirements! }
type QuestResult { … arrested: Boolean! … coinsLost: Coins … guardEncounter: Boolean! … injuriesAdded: [InjuryType!]!  injuriesHealed: [InjuryType!]! … }
type LootRecovery { time: Int!  turns: Int! }
type LootItem { buyPrice: Coins  canHeal: [InjuryType!]!  … recovery: LootRecovery  relatedLore: [Lore!]!  sellPrice: Coins  sellable: Boolean }
type CharacterStatus { … awaitingAid: AwaitingAid … imprisonedUntil: DateTime … potionRecoveryUntil: DateTime … }
type UseItemResult { hpAfter: Int!  hpBefore: Int!  injuriesHealed: [InjuryType!]!  loreUnlocked: [Lore!]!  quantityLeft: Int!  recoveryUntil: DateTime! }
useItem(itemId: ID!): UseItemResult!
```

**Names confirmed.** Every name, type, nullability and the `useItem` argument match the REPO-RULES contract.

### BE handoff for 18-13 (names only)

Source: BE `origin/develop:.planning/phases/18-quest-heal-per-taglia/BACKEND-NOTES.md`.

- **A1 confirmed:** `POTION_RECOVERING` carries `extensions.recoveryUntil` (ISO 8601 UTC with milliseconds), only with that code, in production as well. `QUEST_NO_EFFECT` refuses `acceptQuest` for a heal with no effect, before any write. Its `extensions` holds `{ code }` only.
- `CHARACTER_IMPRISONED` carries `extensions.imprisonedUntil` on `acceptQuest`, `travelPreview`/`startTravel` and `doTransaction`, also over graphql-ws.
- **Quick 261110-prp (BE):** when the prison ends, a sweep sets `imprisonedUntil` back to `null` within about one minute (`QUEST_SWEEP_INTERVAL_MS`) and sends a data-only push `type: prisonRelease` (`id` = the character). The FE already maps `NotificationCategory.prisonRelease` to `focusCharacterOnMap`.
- UAT section titles: «a) Tre heal d'esempio, una per taglia», «b) Identità di test», «c) Runbook dei tre script di contenuto dell'orchestratore», «d) Tabella dei tempi D-18», «e) Finestra operativa fra merge e contenuto».
- Player identity: dev bypass with a test twitch id that differs from the real one, and a single BE process. The handoff names no env variable for it (it writes the placeholder `<twitchId di test>`).
- DB field names for the tricks and the content runbook: `prizes.cure` (`lifePointsShare`, `canHeal`), `infos.timeToComplete`, `infos.description`, `recovery { time, turns }` on the 28 heal potions, `relatedLore` towards the lore «Il limite del corpo» (type `knowledge`), `status.potionRecoveryUntil`, `status.unlockedLore`, `status.imprisonedUntil`, `requirements.minTitle`.
- Example heals by city size: village (share 0.5, 2 h), city (share 0.8, 5 h), capital (share 1, 8 h).
- `useItem` is allowed in a city and **while travelling**. HP is never lowered: a potion with no curable injury on a character at full life answers `ITEM_NO_EFFECT`.

## Task 2: Fragment selections (TDD)

- RED `c202154`: 13 new assertions failed, and only those. Board: cure and noEffect. Loot: recovery in fields and definition, the `canHeal` count pin moved to 2, recovery in the 5 full-loot documents. Result: injuriesHealed and arrested/coinsLost/guardEncounter. Character: potionRecoveryUntil and imprisonedUntil. The two «untouched» pins (`quest_result_documents_test` LootItem literal, `character_fragment_test` unlockedLore literal) stayed green.
- GREEN `fa3aa54`: `flutter test test/graphql test/tool test/models test/repository` reported «+1837: All tests passed!».
- Acceptance greps: `lifePointsShare` 1, `noEffect` line 1, `injuriesHealed` line 1, `recovery {` 2, `potionRecoveryUntil` line 1, `imprisonedUntil` line 1, `arrested|guardEncounter` lines 2, `coinsLost {` 1. No `expect` line was removed from the two pinned files (count 0).
- Schema check: `dump_documents.dart` printed «dumped 46 documents»; `validate_documents.js` gave 46 × OK and `grep -vc OK` = **0**.

## Task 3: Gates

- Full suite `flutter test -r expanded`: **4029 tests, All tests passed** (4015 before, +14 new).
- `flutter analyze --no-fatal-infos`: «47 issues found.» (info only) → `ANALYZE_GATE_OK`.
- Format gate on the Dart files added by the phase: no `UNFORMATTED` line. All 8 touched files are format-clean.
- Trailer grep on `develop..HEAD`: **0**.
- Product-rule greps 1–11: all empty. `recovery {` count = **2**.
- Grep 12 (D-17 diffstat) shows only `lib/config/cloudinary_assets.dart | 56 +++---` (47+/9−). These commits belong to the user-requested sheet quick tasks (261110-shs, 261110-mag, 261110-cgd: quest sheet families per type, torn crime/guard/aid/boss sheets). No phase-18 plan added an asset id, and `game_duration_format` and `JournalCubit` are unchanged. This is an explained exception, not a violation.
- `18-VALIDATION.md`: 25 rows from 18-01-01 to 18-12-03 are `✅ green` and the 18-13 rows stay pending. Wave 0 and the sign-off are ticked, and the frontmatter is `approved` / `wave_0_complete: true` / `nyquist_compliant: true`. `grep -c "nyquist_compliant: true"` returns 2, not 1, because the sign-off checklist line quotes the same text.

## Deviations from Plan

1. Commit scopes are `test(phase-18)` / `feat(phase-18)` instead of the plan's `test(graphql)` / `feat(graphql)`, following the user's commit-scope rule. The feat subject was shortened to "select the cure, potion recovery and no-effect flag".
2. Doc comments of `QuestFragment` and `QuestResultFragment` were updated with the Phase 18 and quick 261110-cgd fields (the plan asked for it on the result fragment only).
3. D-17 grep 12 is not empty: see Task 3 (it comes from the quick tasks).

Otherwise the plan was executed exactly as written. No contract difference.

## Notes for device UAT 18-13

- The BE must run code from `develop` at or after 66df2ef2, otherwise every query fails (Pitfall 14).
- Prison: with the field now on the wire, `CharacterStatus.imprisonedUntil` drives the marker from the status stream (no refusal needed). The BE sweep then clears it within about 60 s after expiry and sends the `prisonRelease` push. The FE frees itself at the instant, before the push.
- The result-sheet lines «Sei stato arrestato.», «Monete confiscate» and «Scontro durante la guardia: …» are now fed by real fields.
- Potions are drinkable while travelling (BE §1.5), and `ITEM_NO_EFFECT` is returned at full life without curable injuries.

## Self-Check: PASSED

- Commits c202154, fa3aa54 and 1035044 are present in `git log`.
- The 4 fragments, the 4 tests and `18-VALIDATION.md` are modified as listed.
