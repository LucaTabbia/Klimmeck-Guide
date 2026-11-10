---
phase: 18
slug: heal-quests-by-size
audited: 2026-11-10T12:30:00Z
status: secured
asvs_level: 1
block_on: high
threats_total: 50
threats_mitigated: 33
threats_accepted: 7
threats_transferred: 2
threats_open: 0
threats_open_blocking: 0
threats_deferred: 8
open_ids: []
deferred_ids: [T-18-41, T-18-42, T-18-43, T-18-44, T-18-45, T-18-46, T-18-47, T-18-48]
updated: 2026-11-10T12:30:00Z
---

# Phase 18 - Security (Heal Quests by City Size, FE)

Audit of the threat registers of plans 18-01..18-13 (50 rows, T-18-01..T-18-50) against HEAD `fc8c7e8` of `feat/18-heal-quests-by-size` (base `f8d0929`, review fixes of `18-REVIEW-FIX.md` included). Evidence is the final code (read-only) and the tests named in the plans; test runs are taken from `18-VERIFICATION.md`, not re-run. Plans 18-12 (schema gate, fragment selections) and 18-13 (device UAT, traceability) are gated on the BE Phase 18 merge: their process threats are DEFERRED, not open. BE-side rules (cure, refusal order of `useItem`, recovery, `Quest.noEffect`, per-viewer lore) are TRANSFERRED (backend is the source of truth, REPO-RULES §Product rules, CONTEXT D-10). The BE repo was not read. No command read `.env`, `google-services.json`, `key.properties` or environment variables. `pubspec.lock` local modification is not ours and was ignored.

Dispositions: mitigated / accepted / transferred / deferred.

## Threat Register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-18-01 | DoS | `QuestCure.tryFromJson` in `Quest.tryFromJson` | mitigated | `lib/models/quest/quest_cure.dart:15` (type checks, no casts); `lib/models/quest/quest_prizes.dart:42`; `test/models/quest/quest_cure_test.dart`, `quest_test.dart` | malformed cure -> null, quest stays |
| T-18-02 | DoS | `QuestResult.injuriesHealed` | mitigated | `lib/models/quest_result/quest_result.dart:137` -> `injuryTypesFrom` (`lib/models/enums/injury_type.dart:197`, non-list = empty) | |
| T-18-03 | Tampering | share outside [0,1] | mitigated | `quest_cure.dart:20` (`!isFinite`, `<0`, `>1` -> null) | BE reads the same value as 0 (BE D-23) |
| T-18-04 | DoS | `potionRecoveryUntil` parse | mitigated | `lib/models/character/character_status.dart:81,97-98` (`is String` + `DateTime.tryParse`) | bad date = null, status stays |
| T-18-05 | DoS | `LootItem.recovery` | mitigated | `lib/models/loot_item.dart:53`; `lib/models/loot_recovery.dart:17-24`; `test/models/loot_recovery_test.dart` | |
| T-18-06 | Tampering | `CharacterStatus.copyWith` | mitigated | `character_status.dart:145` carries `potionRecoveryUntil` by hand | |
| T-18-07 | Tampering | half-read `useItem` answer | mitigated | `lib/models/use_item_result.dart` (`as num`, `DateTime.parse(... as String)` throw); `lib/repository/item_use_repository.dart:28` (`on Object` -> `unknown`); `test/models/use_item_result_test.dart`, `test/repository/item_use_repository_test.dart` | |
| T-18-08 | Tampering | rule slipping into display helpers | mitigated | no severity/tier hit in `lib/utils/item_lines.dart` (check E); recovery only from `LootRecovery` | |
| T-18-09 | Info disclosure | other injuries on the sheet | mitigated | `curableInjuriesLine` in `lib/utils/item_lines.dart` iterates the viewer's own injuries; `test/utils/item_lines_test.dart` | |
| T-18-10 | Tampering | client-side cure rule | mitigated | `QuestType.heal` only in label/asset maps (check E); no HP numbers | display filtering only (D-03) |
| T-18-11 | Info disclosure | full cure list on sheet | mitigated | input is the current character's `status.injuries` only | |
| T-18-12 | DoS | selector rebuild storm | accepted | plan 18-04 register: sparse stream events | |
| T-18-13 | Tampering | `ItemRow` deciding drinkable | mitigated | `isDisabled`/`statusLine` come from the caller (`items_section.dart:187-196`) | |
| T-18-14 | Tampering | combat consumables gaining potion behaviour | mitigated | no call-site change in result rows (D-14); only `items_section.dart` passes `onSelect` for potions (`:32`, `:180`) | |
| T-18-15 | Info disclosure | `turns` shown | mitigated | no `turns` in `item_row.dart` / `item_lines.dart` (check E); `loot_recovery.dart` doc: turns never shown | |
| T-18-16 | EoP | `useItem` on another character | transferred | document `UseItem($itemId: ID!)` sends the item id only (`lib/graphql/mutations/character_mutations.dart:73-88`); ownership by bearer is BE (BE Phase 18, CONTEXT D-11) | FE half verified |
| T-18-17 | Info disclosure | server text to player | mitigated | `lib/repository/item_use_failure.dart:49-66` (`extensions.code` only), `:46` `toString` = failure name; no `.message` in the item/potion/acceptance files (check B) | |
| T-18-18 | Tampering | forged `recoveryUntil` | mitigated | `item_use_failure.dart:73-80` (only for `potionRecovering`, `is String` + `tryParse`); feeds notice text only | |
| T-18-19 | DoS | hanging mutation | mitigated | `item_use_repository.dart:13-26` (15 s timeout -> `timedOut`), no retry | |
| T-18-20 | Info disclosure | logging | mitigated | 0 new `print`/`debugPrint` (check B); `hardening_check: OK` | |
| T-18-21 | DoS | document ahead of BE | accepted | plan 18-06: `useItem` is not reachable before `recovery` is selected (gated 18-12) | schema gate deferred to 18-12 |
| T-18-22 | Tampering/DoS | double tap | mitigated | `lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart:20` (`state is PotionDrinking` return); sheet button disabled while drinking `potion_sheet.dart:107`; `potion_cubit_test.dart` | |
| T-18-23 | Tampering | device clock forward | accepted | plan 18-07 / CONTEXT D-12: countdown display only, BE refuses with `POTION_RECOVERING` | |
| T-18-24 | Tampering | optimistic state | mitigated | `potion_cubit.dart` holds mutation state only, no `CharacterCubit` | |
| T-18-25 | DoS | timer leak | mitigated | `potionRecoveryCubit/potion_recovery_cubit.dart:49` lazy periodic, `:52-61` cancelled on stop and `close()`; `potion_recovery_cubit_test.dart` | |
| T-18-26 | Info disclosure | server text in banners | mitigated | `potionCubit/potion_notice.dart:15-31`, `questAcceptanceCubit/quest_acceptance_notice.dart:39`: fixed copy by enum | |
| T-18-27 | Tampering | local estimate of remaining time | mitigated | `components/potion_outcome_listener.dart:36-40` (server date minus `ServerClockService.now()`); `potion_notice.dart` null/<=0 -> generic | |
| T-18-28 | DoS | banner flood/swallowed refusal | mitigated | listener `dedupKey` with `sequence` (`potion_outcome_listener.dart:43-45`); `potion_cubit.dart` `++_refusals` | |
| T-18-29 | Spoofing | unauthenticated refusal announced | mitigated | `potion_notice.dart:16` (`unauthenticated` -> null) | |
| T-18-30 | Tampering | accidental drink | mitigated | single `.drink(` call site: `potion_sheet.dart:108` (confirmation button); row tap only opens the sheet (`items_section.dart:180`) | |
| T-18-31 | Tampering | client «drinkable» rule | mitigated | `items_section.dart:32,165-181`: gate only on `recovery`, countdown, `awaitingAid`; no severity/HP | |
| T-18-32 | Tampering | local stack/HP divergence | mitigated | rows read `CharacterCubit` (`items_section.dart:76`); result feeds the outcome face only | |
| T-18-33 | DoS | blocked Journal / leaked timer | mitigated | `PopScope`/disabled buttons only while drinking (`potion_sheet.dart:96-108`); countdown cubit closed (`potion_recovery_cubit.dart:58-61`) | |
| T-18-34 | Tampering | device clock re-enabling parchments | accepted | CONTEXT D-12: BE refuses with `POTION_RECOVERING` + its date | |
| T-18-35 | EoP | drink while awaiting aid | mitigated | `items_section.dart:165-169` (no `onSelect` when `awaitingAid`); BE `AWAITING_AID` also mapped (`item_use_failure.dart:60`) | |
| T-18-36 | Tampering | client «useless heal» rule | transferred | FE reads the flag only: no `lifePointsShare`/`canHeal` in `quest_availability.dart`, board or scope listener (check E); BE refuses `QUEST_NO_EFFECT` (BE Phase 18, CONTEXT D-20) | |
| T-18-37 | DoS | malformed `noEffect` | mitigated | `lib/models/quest/quest.dart:40` (`json['noEffect'] == true`) | |
| T-18-38 | DoS | reread storm | mitigated | `components/quest_scope_listener.dart` vitals as values in a city only; `refreshQuests` last-call-only | |
| T-18-39 | Info disclosure | server text of the refusal | mitigated | `quest_acceptance_failure.dart:83` (code map), `quest_acceptance_notice.dart:39` fixed line | |
| T-18-40 | Tampering | stale sheet lets swipe through | accepted | BE refuses `QUEST_NO_EFFECT`; sheet recomposes (plan 18-10) | |
| T-18-41 | Tampering | BE working tree | deferred | plan 18-12 (gate not executed) | |
| T-18-42 | Info disclosure | `.env`, identity values in handoff | deferred | plan 18-12 | |
| T-18-43 | DoS | documents ahead of BE | deferred | plan 18-12; fragments select none of the new fields yet (check D) | |
| T-18-44 | Tampering | rule/chrome/loader slipping in | deferred | plan 18-12 product-rule greps; interim: checks E | |
| T-18-45 | Tampering | contract rename by executor | deferred | plan 18-12 SDL proof | |
| T-18-46 | Info disclosure | UAT/handoff docs | deferred | plan 18-13 (docs not written yet) | |
| T-18-47 | Repudiation | requirement traceability | deferred | plan 18-13 | |
| T-18-48 | Spoofing | probe bearer in record | deferred | plan 18-13 | |
| T-18-49 | Tampering | BE repo and DB seeds | accepted | plan 18-13: read-only refs, orchestrator-side | |
| T-18-50 | DoS | reread loop after refusal | accepted | plan 18-11: one `refreshQuests` per refusal, last call only | |

## Cross-cutting checks

| Check | Command | Result |
|-------|---------|--------|
| A | `bash tool/hardening_check.sh` | `hardening_check: OK` |
| B | `git diff f8d0929..HEAD -- lib \| grep -cE '^\+.*(debugPrint\|print)\('` | `0`; `grep -n "\.message"` over `item_use*.dart`, journal dir, `questAcceptanceCubit`, `potion_outcome_listener.dart` -> no hits; notices built from enum + fixed copy |
| C | `recoveryUntil` handling | read in `item_use_failure.dart:75-78` only for `potionRecovering`, `is String` + `DateTime.tryParse`; used as `Duration` in the listener, never printed raw |
| D | `grep -rnE "cure\|injuriesHealed\|noEffect\|recovery\|potionRecoveryUntil\|relatedLore" lib/graphql` | no new field in `lib/graphql/fragments` (existing `relatedLore`/`recoveryTime` are pre-phase: quest/spell fragments); only the `UseItem` mutation document selects `injuriesHealed`/`recoveryUntil`, and it selects `loreUnlocked { id name type }`, not `relatedLore` |
| E | `grep -rn "QuestType.heal" lib`; `grep -niE "severity\|tier" lib/utils/item_lines.dart`; `lifePointsShare\|canHeal` in availability/board/scope listener | heal only in `quest_type.dart:31`, `quest_paper_asset.dart:34`, `quest_state_label.dart:15` (labels/asset); no other hit |
| F | lenient parsers | `QuestCure.tryFromJson`, `LootRecovery.tryFromJson`, `injuryTypesFrom`, `Lore.lenientRefsFrom`, `Quest.noEffect == true`, `_instantOrNull` all type-check without throwing; strict `UseItemResult.fromJson` caught by `on Object` in `item_use_repository.dart:28` |
| G | `git diff f8d0929..HEAD -- pubspec.yaml \| wc -l` | `0` |
| H | `git diff f8d0929..HEAD --name-only \| grep -E '(^\|/)\.env\|key\.properties\|\.jks$\|google-services\.json' \| wc -l` | `0` |
| I | `git log f8d0929..HEAD --format=%B \| grep -ciE "co-authored-by\|generated with\|claude-session"` | `0` |

Unregistered flags: none (no `## Threat Flags` raised new surface).

## Open

None.

## Deferred

- T-18-41, T-18-42, T-18-43, T-18-44, T-18-45: plan 18-12 (schema gate on the merged BE SDL, fragment selections, product-rule greps), gated by the BE Phase 18 merge.
- T-18-46, T-18-47, T-18-48: plan 18-13 (device UAT record, traceability, probe hygiene), gated by 18-12.
