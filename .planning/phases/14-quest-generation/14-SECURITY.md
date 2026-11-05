---
phase: 14
slug: quest-generation
audited: 2026-11-04
status: secured
asvs_level: 1
block_on: high
threats_total: 29
threats_mitigated: 25
threats_accepted: 3
threats_transferred: 1
threats_open: 0
threats_open_blocking: 0
threats_deferred: 0
open_ids: []
deferred_ids: []
updated: 2026-11-05
---

# Phase 14 - Security (Quest Generation, FE)

Audit of the threat registers of plans 14-01..14-11 (29 rows, T-14-01..T-14-29) against HEAD `d452632` of `feat/14-quest-generation` (base `develop` `9993a3c`, review fixes of `14-REVIEW-FIX.md` included). Evidence is the final code and the tests named in the plans. Plans 14-10 (schema gate vs merged BE Phase 13 SDL) and 14-11 (device E2E, handoff, traceability) are gated on the BE Phase 13 merge (CONTEXT D-13): their process threats are DEFERRED, not open. BE-side mitigations are TRANSFERRED with BE decision IDs (BE 13-CONTEXT D-16) as evidence; the BE repo was not read or touched. No command read `.env`, `google-services.json` or environment variables. Implementation files read only.

Dispositions: mitigated / accepted / transferred / deferred.

## Threat Register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-14-01 | DoS | `QuestEnemy.fromJson` / `QuestInfos.fromJson` | mitigated | `lib/models/quest/quest_enemy.dart:17,20,40,54` (strict `listFrom` throws `FormatException`), `lib/models/quest/quest.dart:38` (`tryFromJson`); test «tryFromJson skips a quest with a malformed enemies entry (D-01)» | only the malformed quest is skipped |
| T-14-02 | DoS | `Enemy.fromJson` `locations` crash | mitigated | `QuestEnemy` is a separate model (`quest_enemy.dart`) with id/name/imagePath/xp only; `quest_fragment.dart:23-28` selects the same four fields; test «parses enemy and quantity with only id, name, imagePath and xp (D-01)» | |
| T-14-03 | Tampering | `prizes.pet` without id | mitigated | `lib/models/pet.dart:58` (`Pet.tryFromJson`, post-review), used by `quest_prizes.dart:36`; `pet_test.dart` group «Pet.tryFromJson» | the quest is kept |
| T-14-04 | DoS | `QuestResult.fromJson` enemies | mitigated | `lib/models/quest_result/quest_result.dart:119` (`lenientListFrom`), `quest_enemy.dart:45-59`; test «drops a malformed enemies entry and keeps the result (D-01)» | |
| T-14-05 | DoS | stage counters / `rewards.pet` | mitigated | `quest_result.dart:159` (`_countFrom` -> null for non-numbers), `quest_rewards.dart:22` (`Pet.tryFromJson`); tests «a non-numeric stage counter is null…», «a pet without id is ignored…» | |
| T-14-06 | DoS | documents ahead of the BE (Pitfall 4) | mitigated | plan 14-10 executed 2026-11-05: 44/44 OK on the merged SDL `origin/develop` `162c1f5`, no name differed, device run only after (`14-10-SUMMARY.md`) | closed 2026-11-05 (was deferred) |
| T-14-07 | DoS | enemy `relatedLore` / `locations` selection (BE populate depth 1) | mitigated | check C: `enemy {` only at `quest_fragment.dart:23` and `quest_result_fragment.dart:88`; `relatedLore` at `quest_fragment.dart:30` is a sibling of `enemies`, not under `enemy`; tests «never selects lore or locations under an enemy (D-01)», «never selects enemy locations» | BE populate depth is BE D-28 |
| T-14-08 | Tampering | `enemyPortraitUrl` | mitigated | `lib/utils/enemy_portrait_url.dart:12-19` (https with host, or `^v\d+/\S+$` via Cloudinary; everything else null); `test/utils/enemy_portrait_url_test.dart` «http, file and data URLs stay hidden (D-03)» | check D: no `http://`/`file:`/`data:` literal |
| T-14-09 | DoS | broken or huge remote image | mitigated | `lib/shared/components/enemy_portrait.dart:46-47` (placeholder/errorWidget `SizedBox.shrink`), `:30` `canShow` gates the layout (`quest_info_sheet.dart:205`, `quest_result_sheet.dart:240`); `enemy_portrait_test.dart` | |
| T-14-10 | DoS | long announcement / many enemy lines | mitigated | `SingleChildScrollView` at `quest_info_sheet.dart:148,184,213,240`; tests «a long announcement scrolls without overflow (D-05)», «many enemies and Consigliati do not overflow in landscape (D-02, D-04)» | |
| T-14-11 | Tampering | portrait URL (info sheet) | mitigated | portrait only via `EnemyPortrait` (`quest_info_sheet.dart:207`); `Image.asset` count 0 (check D) | |
| T-14-12 | DoS | many enemy lines in the result | accepted | plan 14-06 accept: result sheet content already scrollable | no further bound needed |
| T-14-13 | Tampering | portrait URL (result sheet) | mitigated | `quest_result_sheet.dart:243` via `EnemyPortrait`; `Image.asset` count 0 (check D) | |
| T-14-14 | EoP | `generateQuests` | transferred | BE `@Roles(innkeeper)` + audit (BE 13-CONTEXT D-16); FE maps `FORBIDDEN` -> `InnkeeperFailure.forbidden` (`lib/repository/innkeeper_failure.dart:51`), never decides the role | single call site via repository (check F) |
| T-14-15 | DoS | repeated taps | mitigated | `quest_generation_cubit.dart:22` (`if (state is QuestGenerationSubmitting) return;`), `generate_quests_button.dart:23` (`isSubmitting ? null`); test «ignores generate while submitting (D-09)» | BE caps the run at its target |
| T-14-16 | Info disclosure | server error text | mitigated | `innkeeper_failure.dart:44` (`graphQlErrorCode` only), `:40` `toString` prints `failure.name`; check B = no `.message` | tests on codes |
| T-14-17 | Tampering / DoS | accidental or repeated «Genera missioni» | mitigated | `innkeeper_panel_screen.dart:137-139` (`showDestructiveConfirmation`, whose dialog is `barrierDismissible: false`, `destructive_confirmation_dialog.dart:63`); button disabled while submitting | tests ««Annulla» sends nothing (D-09)», «the button is disabled while generating (D-09)» |
| T-14-18 | EoP | role lost mid-session | mitigated | `innkeeper_panel_screen.dart:122-123` (`forbidden` -> `_closeUnavailable`), `:69` AuthCubit listener closes the panel | |
| T-14-19 | Info disclosure | error SnackBar | mitigated | fixed Italian copy per failure class in `innkeeper_panel_screen.dart`; check B = no `.message` in `lib/screens/innkeeper` | |
| T-14-20 | DoS | `EquipmentItem.fromJson` unknown use name | mitigated | `lib/models/equipment_item.dart:106-111` (`asNameMap` + `whereType`, unknown names dropped); test «drops unknown use names instead of throwing (D-12)» | |
| T-14-21 | Tampering | equip rules | accepted | no FE equip constraint (D-12); BE engine owns semantics (BE D-24) | documented in plan 14-09 |
| T-14-22 | Tampering | BE working tree | mitigated | plan 14-10 used only `fetch`/`show`/`log`/`ls-tree` on `origin/develop` (`14-10-SUMMARY.md`); the BE tree was never checked out or edited | closed 2026-11-05 (was deferred) |
| T-14-23 | Info disclosure | `.env` during the gate | mitigated | plan 14-10 read no `.env*`; `NODE_PATH` pointed to the BE `node_modules` only; scratch outside the repo (`14-10-SUMMARY.md`) | closed 2026-11-05 (was deferred) |
| T-14-24 | DoS | documents ahead of the BE | mitigated | gate passed (44/44 on `162c1f5`) before any device run; 14-11 re-checked `QuestEnemy` = 3 on `origin/develop` | closed 2026-11-05 (was deferred) |
| T-14-25 | Info disclosure | error routing sanity greps | mitigated | the six sanity greps of plan 14-10 printed nothing (`14-10-SUMMARY.md`): cubit Flutter-free, only `extensions.code` read | closed 2026-11-05 (was deferred) |
| T-14-26 | Info disclosure | `14-HUMAN-UAT.md`, `BACKEND-NOTES.md` | mitigated | both files written 2026-11-05: grep `mongodb://|token=|password` = 0, no user ids, DB seeds recorded as field names only | closed 2026-11-05 (was deferred) |
| T-14-27 | Repudiation | requirement traceability | mitigated | QGEN-01..06 marked complete on 2026-11-05 only after the user's verbatim verdict per step (`14-HUMAN-UAT.md`); step 8 Cloudinary half skipped by the user's explicit decision and recorded as such | closed 2026-11-05 (was deferred) |
| T-14-28 | Tampering | BE repo | mitigated | 14-11 used read-only refs only; the BE process was never restarted from the FE session (it already served the merged code from `dist/`) | closed 2026-11-05 (was deferred) |
| T-14-29 | EoP | innkeeper account in the UAT | accepted | dev account promoted by the user (Phase 10 setup); BE `RolesGuard` unchanged | |

## Cross-cutting checks (all from `/Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide`)

| Check | Command | Result |
|-------|---------|--------|
| A. no `print(` | `grep -rn "print(" lib/models/quest lib/models/quest_result lib/screens/innkeeper lib/shared/components/enemy_portrait.dart lib/utils/enemy_portrait_url.dart` | no output |
| B. codes only | `grep -rn "\.message" lib/repository/innkeeper_failure.dart lib/repository/innkeeper_repository.dart lib/screens/innkeeper` | no output |
| C. enemy selection | `grep -rn "^ *enemy {" lib/graphql` | `quest_fragment.dart:23`, `quest_result_fragment.dart:88` (the two nested blocks). `relatedLore` at `quest_fragment.dart:30` is under quest infos; `quest_result_fragment.dart:7` is a comment forbidding it |
| D. portrait | `grep -c "Image.asset"` on `quest_info_sheet.dart`, `quest_result_sheet.dart`; `grep -n "http://\|file:\|data:" lib/utils/enemy_portrait_url.dart` | 0 and 0; no output (allow-list only, see `enemy_portrait_url.dart:12-19`) |
| E. registry 44 | `grep -c "'" tool/schema_check/schema_check_documents.dart`; `grep -n "44" test/tool/schema_check_documents_test.dart test/graphql/travel_documents_test.dart test/graphql/shop_documents_test.dart` | 69 (lines with quotes, informational); `expect(schemaCheckDocuments.length, 44)` in all three tests |
| F. generateQuests | `grep -rn "generateQuests" lib/ \| grep -v "^lib/graphql"` | only `innkeeper_repository.dart:60`, `services/graphql/graphql.dart:241-248`, `quest_generation_cubit.dart:26`, and a widget `Key` string in `generate_quests_button.dart:13`; no widget calls GraphQL |
| G. trailers | `git log 9993a3c..HEAD --format=%B \| grep -ciE "co-authored-by\|generated with"` | 0 |
| H. secrets / deps | `grep -rn "\.env\|google-services" lib`; `git diff 9993a3c..HEAD --stat -- pubspec.yaml` | only pre-existing Phase 1/5 references (`main.dart`, `env_config.dart`, dev auth service), none in Phase 14 files; pubspec diff empty |

## Open

None.

## Deferred (closed 2026-11-05)

- ~~T-14-06 / T-14-24~~: closed — 44/44 documents OK on the merged BE SDL `162c1f5` (plan 14-10, no alignment needed).
- ~~T-14-22 / T-14-23 / T-14-25~~: closed — plan 14-10 ran with read-only BE access, no `.env`, six sanity greps empty.
- ~~T-14-26 / T-14-27 / T-14-28~~: closed — plan 14-11 wrote `14-HUMAN-UAT.md` and `BACKEND-NOTES.md` without secrets or user ids, marked QGEN-01..06 only on the user's verbatim words, touched the BE through read-only refs only.

Dispositions after the gated plans: `mitigated` 25, `accepted` 3, `transferred` 1, `deferred` 0, `open` 0 (at audit time 17 / 3 / 1 / 8 / 0).

## Accepted risks

T-14-12 (scrollable sheet is the bound), T-14-21 (equip semantics are BE-owned), T-14-29 (dev account promoted by the user for the UAT).

## Unregistered flags

The `## Threat Flags` sections of 14-01, 14-02, 14-08 and 14-09 all state "None" beyond the register; no unregistered flag.
