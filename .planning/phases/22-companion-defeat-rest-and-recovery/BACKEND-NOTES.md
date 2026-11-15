# Phase 22 (FE) — Backend notes

Written by plan 22-17 (Task 1) after the BE Phase 23 merge; §3 is completed by plan 22-17 (Task 3) after the device E2E.

Frontend companion of the BE Phase 23 («Sconfitta, riposo e recupero dei compagni»). Branch `feat/22-companion-defeat-rest-and-recovery`. English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. BE ref: `develop` `5ff0bdb9` (BE PR #42 merged); the SDL of `origin/develop` has the same sha256 as the file read by the gate of 22-16 (`5de70ef2…4330`, verified by the orchestrator). The device E2E runs on BE branch `fix/23-dungeon-xp-and-innkeeper-corrections` (= `develop` + BE PR #43, SDL unchanged), which carries two rules decided by the user on 2026-11-15: (a) a companion fallen before the last fight of a sequence (dungeon, guided mission) gets the xp of the fights it fought only; (b) in an innkeeper correction an omitted or null field takes the simulated value, an explicit value wins.

## 1. Contract consumed by the FE

Names, types and nullability confirmed on the merged SDL by plan 22-16 (gate `GATE_OK`, no deviation from `22-REPO-RULES.md` §Final wire and D-37/D-38) and re-checked by plan 22-17 (`GATE_OK`, byte-identical SDL). Schema check (plan 22-16): registry of **55** documents (`tool/schema_check/schema_check_documents.dart`, `RenamePet` added in 22-11), 55 × OK. Key everywhere: the catalogue pet id (there is no `OwnedPet.id`).

Selection points:

- `CharacterFragment.assetsFields` (`lib/graphql/fragments/character_fragment.dart`): `ownedPets { xp currentLifePoints name defeated lifeAsOf fullLifeAt potionRecoveryUntil level maxLifePoints pet { … } }` — used by `character` and `characterUpdated` only; the innkeeper `characters` documents do not embed `CharacterFragment` (BE W-1/W-3: companions not populated there).
- `PetFragment.fields` (`lib/graphql/fragments/pet_fragment.dart`): `… maxLifePoints recoveryTime attack { … } defense { … } rarity` — shop pools, owned pets, quest prizes (`QuestFragment` embeds it since 22-08, so `quests` and `OnQuestUpdated` carry it), innkeeper catalogue.
- `QuestResultFragment` (`lib/graphql/fragments/quest_result_fragment.dart`): `petXpGained companion { name lifeBefore lifePoints maxLifePoints defeated fullLifeAt }` and `ambush { … reachedCity { … } onFoot }` — `GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived` and the completion results.
- `MissionDraftFragment` (`lib/graphql/fragments/mission_draft_fragment.dart`): outcomes `hpBefore companion { pet name lifeBefore maxLifePoints }`, `simulated` / `corrected` `{ hpAfter companionLifeAfter … }`.

| Operation (document) | Field | FE file |
|----------------------|-------|---------|
| mutation `UseItem` | `useItem(itemId: $itemId, petId: $petId)` → `UseItemResult!` (`$petId: ID` optional, sent only for a companion) | `lib/graphql/mutations/character_mutations.dart` |
| mutation `RenamePet` | `renamePet(request: RenamePetRequest!)` → `CommonResponse!` (`id` = character id, `petId`, `name`) | `lib/graphql/mutations/character_mutations.dart` |
| mutation (existing) `EquipPet` / `UnequipPet` | `equipPet` refusal `PET_DEFEATED` mapped | `lib/repository/pet_equip_failure.dart` |
| mutation (existing) `SaveMissionDraft` | `ParticipantOverrideInput.companionLifeAfter` in the corrections | `lib/models/request/mission_draft_inputs.dart` |

- Refusal codes (`extensions.code` only): `PET_DEFEATED` (`lib/repository/pet_defeated.dart`, the only literal; equip and potion), `PET_POTION_RECOVERING` with `extensions.recoveryUntil` (`lib/repository/item_use_failure.dart`), `ITEM_NO_EFFECT` (existing, companion at full life), `PET_NAME_INVALID` (`lib/repository/pet_rename_failure.dart`), `FORBIDDEN`, `OUTCOME_OVERRIDE_INVALID` (existing wizard refusal).
- Push types (`lib/models/notification_category.dart`): `ambush` (category «Imboscate», `storageKey` `ambush_defeat` kept so saved toggles survive, accepts the legacy `ambushDefeat` too), `petRecovered` (new category «Compagno in forze», tap lands on the Map, no popup). Dedup / banner key `ambush|<QuestResult id>` for both wire types.

## 2. FE behaviours proved by tests

- **Vitality rule (D-09, D-24, D-38):** `companionVitalityOf` (`lib/models/companion/companion_vitality.dart`) interpolates linearly from (`currentLifePoints`, `lifeAsOf`) to (the companion's own max, `fullLifeAt`), rounds to the nearest point, never below the anchor and capped at max − 1 until `fullLifeAt`; equipped, no dates or no max → steady; now ≥ `fullLifeAt` → full and steady even if served `defeated`; dates in the wrong order → no crash. Never computed from `recoveryTime`. One getter for the companion's max (`OwnedPet.effectiveMaxLifePoints`: owned max, else species max) read by every surface.
- **Local re-enable at `fullLifeAt`:** `CompanionVitalityCubit` (Journal-scoped, server clock offset) ticks only while some companion rests, is defeated or waits for a potion; at `fullLifeAt` the parchment becomes tappable again without waiting for the sweeper (the BE judges `equipPet` on the same date). A served entry newer than the computed vitality wins (review A-03: a defeated parchment is never tappable for a stale frame).
- **Potion eligibility (D-32):** `companionPotionTargetsOf` lists equipped and resting companions below their max, not defeated, not in their own wait, in the served order; the potion row is tappable when the character or a companion can drink; «Bevi» disabled during the character's own wait.
- **Refusals per code:** potion `petDefeated` / `petPotionRecovering` (with the served date) / `noEffect` with the companion name under the title «Pozione non data»; equip `PetEquipFailure.defeated` «È ancora sconfitto: aspetta che torni in forze»; rename refusals shown inline in the name sheet (`companionNameRefusalLine`), `CHARACTER_NAME_INVALID` also read as `nameInvalid`, `MISSION_IN_PROGRESS` never expected on a rename.
- **Single-flight:** `PotionCubit.drink` / `give` share one guard (one call while `PotionDrinking`); `CompanionNameCubit.rename` ignored while submitting; one sequence counter for saved / refused.
- **Name form rules (D-31):** `lib/utils/name_rules.dart` extracted from the character draft (normalise whitespace, 2–20, letters, spaces, apostrophes and hyphens, at least one letter); the confirm stays disabled on an invalid name (e.g. «R2D2»); display name = name, else species (`companionDisplayNameOf`), used by every wording.
- **Result lines (D-10, D-27):** defeat line duration = `fullLifeAt − resolvedAt` (never from now, no ticker on a dated record); life line only when the companion lost life and was not defeated; xp line with the served name; «Prosegui a piedi» printed from `AmbushReport.onFoot`.
- **Banner suppression (D-30, Pitfall 5):** when an ambush result opens live on the Map, the push banner `ambush|<result id>` is suppressed; both wire types dedup on the same key.
- **Companion slider bounds (D-17, D-33):** «Compagno: <nome>» slider `1..maxLifePoints` (served), «Sconfitto» at the floor; it starts at the simulated value; every correction resends the simulated `companionLifeAfter` (pinned in `fight_step_test`), compatible with the BE «omitted = simulated» rule of `fix/23`.
- **The one switch (Pitfall 3):** `companionCareEnabled` (`lib/config/companion_care.dart`) gates companion potions and every rename entry point (shop purchase prompt, prize prompt after «Continua», «Cambia nome» in the Journal details); flipped to `true` by the gate plan 22-16 together with the `UseItem` `$petId` variable.

## 3. UAT outcome (FE Phase 22, 2026-11-15)

Filled by plan 22-17.

## 4. Questions and notes for the BE

1. `characterUpdated` must be emitted by the sweeper claim when a defeated companion returns «in forze» (same moment as the `petRecovered` push) and at every companion write (equip/unequip, potion, outcome, rename): the FE has no other trigger to refresh the served state. No emission is expected when a resting companion reaches full life (the FE interpolates).
2. Push texts and ids: `ambush` id = the ambush `QuestResult` id (one per ambush, won or lost); `petRecovered` id = the catalogue pet id. The texts («Imboscata!», «Di nuovo in forze» and their bodies) are provisional and are reviewed with the user at the UAT.
3. Travels in flight at the deploy: travels without `status.activeTravel.mount` are not recomputed and their held ambush reports are delivered at arrival / teleport; the FE handles both paths (carousel mid-travel or at arrival).
4. Pawn jump-back (BE B-09, deferred): a late sweep resolution moves `startTime` back to the ambush instant; watched at step 5.
5. Rules of BE PR #43 (`fix/23-dungeon-xp-and-innkeeper-corrections`, not merged at the time of writing): companion xp from the fights fought only in a sequence; correction fields omitted or null = simulated. The FE reads the served xp and always resends the simulated companion life, so no FE change is needed. PR #43 should be merged before the FE PR.
6. Copy the user changed at the UAT: recorded in §3.
