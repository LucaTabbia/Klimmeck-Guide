# Phase 18 (FE) — Backend notes

Frontend companion of the BE Phase 18 (quest heal per taglia) and of the BE quick tasks 261110-cgd (crime arrest, guard encounter, prison), 261110-mag (quest type `magic`) and 261110-prp (prison release push). Branch `feat/18-heal-quests-by-size`; contract proved on BE `origin/develop` `66df2ef2` (merge of BE PR #31) by plan 18-12 and on the Android device by plan 18-13 (`18-HUMAN-UAT.md`). English text, user quotes verbatim in Italian. No ids of real users or characters, no tokens, no URIs, no environment values in this file.

## 1. Contract consumed by the FE

```graphql
# QuestFragment.fields (quests, OnQuestUpdated) — noEffect before prizes, cure after pet
noEffect
prizes { … pet { … } cure { lifePointsShare canHeal } }

# QuestResultFragment.fields, right after injuriesAdded
injuriesHealed arrested coinsLost { gold silver copper } guardEncounter

# LootFragment.fields and LootFragment.definition only, after sellPrice
recovery { time turns }

# CharacterFragment.statusFields, right after awaitingAid
potionRecoveryUntil imprisonedUntil

# Mutation UseItem
useItem(itemId: $itemId) {
  hpBefore hpAfter injuriesHealed quantityLeft recoveryUntil
  loreUnlocked { id name type }
}
```

- `QuestPrizes.cure { lifePointsShare canHeal }` and the top-level `Quest.noEffect` are in the shared quest fragment, so they reach both `quests` and `OnQuestUpdated`.
- `QuestResult.injuriesHealed` feeds the «Guarite: …» line of the result sheet.
- `recovery { time turns }` is selected in `LootFragment.fields` and `definition` only — never on the simple loot selection of quests and results (`simpleFields` untouched).
- `CharacterStatus.potionRecoveryUntil` drives the countdown; `CharacterStatus.imprisonedUntil` drives the prison marker (quick 261110-cgd).
- Refusal codes are read from `extensions.code`; `extensions.recoveryUntil` is read for `POTION_RECOVERING`, `extensions.imprisonedUntil` for `CHARACTER_IMPRISONED`; `ITEM_NO_EFFECT` and the other `useItem` codes map to in-world notices (others generic); `QUEST_NO_EFFECT` on `acceptQuest` shows its own notice and rereads the list.
- `LootItem.relatedLore` is not selected (the lore arrives through `UseItemResult.loreUnlocked`).
- `PushEventType.prisonRelease` is mapped to the notification category «Uscita di prigione» (opens the character on the Map).
- Registry: 46 documents, 46/46 OK against `66df2ef2` (plan 18-12, unchanged after the UAT fixes).

## 2. FE behaviours proved

- Lenient parsers: a malformed cure or a `lifePointsShare` outside [0, 1] → no cure rows; unknown injuries dropped from `canHeal` / `injuriesHealed`; `recovery.time` ≤ 0 → the item is not drinkable; an unreadable `potionRecoveryUntil` → `null`; a missing `noEffect` → `false`.
- The two sheet rows are keyed by the cure: «Cura le tue ferite: …» lists only the viewer's own injuries that are in `canHeal` (character order, lowercase), hidden when none matches; «Vita: almeno il N%» (share 1 → «al massimo», share 0 → hidden). No game rule on the FE.
- «Guarite: …» on the result sheet between the HP delta and the injuries added, hidden when empty.
- The torn no-effect sheet is read from the `noEffect` flag only; the FE rereads `quests` silently when the character's HP or injuries change in a city, so the sheet becomes whole again with no spinner (proved live in UAT step 7).
- The potion flow is not optimistic: the state comes from `characterUpdated` only; the countdown «pronta fra …» runs on the server date with a local tick, display only, never a call; a `POTION_RECOVERING` without a readable `recoveryUntil` → generic notice.
- Potions are drinkable in travel and in prison, hidden while awaiting aid.
- The branch must never run against a BE without Phase 18 and quick 261110-cgd: every quest, result, item and character query would be rejected.
- Changes made during the device UAT (FE only, no contract change): a Library book never opened marks every entry «Nuovo» (user rule, Phase 17 D-07 amended); every pawn label on one line in a smaller font (prison marker unit was clipped); the revised magic sheet flattened to one embedded image (the previous SVG used masks on `feColorMatrix` filters, unsupported by the renderer).

## 3. UAT outcome (FE Phase 18, 2026-11-11)

BE `develop` `66df2ef2` on the orchestrator's machine, restarted from `develop`, player identity through the BE process environment (`DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`; values never written). Content at DB written and re-read by the orchestrator before the UAT (166 heals by size, `recovery` on the 28 heal potions, lore «Il limite del corpo», crime/guard ranks and prizes, the `magic` quest at Valantar). Verdict: **complete**, steps 1–14 pass, optional 15 skipped.

- Cure per size: village (share 0.5) 300 → 500 / 1000, the listed injury healed, the unlisted one left; city (0.8) 300 → 800, the city-list injury healed, the capital-only one left; capital (1) 200 → 1000, all three injuries healed. `injuriesHealed` matched the DB each time.
- `noEffect`: healthy character → torn, inert temple sheet; an injury of the temple's list seeded with the Board open → the sheet whole again with no spinner (via the FE reread, see §4).
- `useItem` success: field herb drunk from the Journal — HP gain, «Guarite», «Conoscenza appresa: Il limite del corpo» (the lore of the first potion), countdown about 30 min.
- `POTION_RECOVERING` probe (orchestrator, player bearer): second `useItem` during the recovery → the code with `extensions.recoveryUntil` equal to `status.potionRecoveryUntil`; HP and inventory unchanged.
- `ITEM_NO_EFFECT`: full HP and no curable injury → «Pozione non bevuta», stack unchanged, no countdown.
- Drinking in travel: herb drunk during a travel, as in the city.
- Prison (quick 261110-cgd / 261110-prp): marker and countdown, Board/Shop closed and travel blocked, Journal and potions open, release at the instant with the push «Di nuovo libero» received.
- Crime arrest at the 5th attempt: no prize, `coinsLost` = 25 % of the purse, `imprisonedUntil` +10 h. Guard encounter won: coins doubled, xp of the encounter, HP loss and one injury, enemy lore unlocked. Guard encounter lost: no prize, 1 HP in the city, no `awaitingAid`, no prison.
- Quest `magic` at Valantar (character seeded to mage): with too little xp for any spell, success without a spell; with enough xp, success and one spell learned.
- Board families (crime, guard, hunt, job, heal, magic, study): not explicitly confirmed by the user (the user went on to accept the crime without remarks); the magic sheet asset finding was FE/asset only.

## 4. Questions and notes for the BE

- Does `OnQuestUpdated` carry a per-viewer `noEffect` for each subscriber, or should the FE ignore the flag on subscription payloads?
- The FE rereads `quests` on every change of HP or injuries in a city to refresh `noEffect` — is a `questUpdated` re-emission planned instead?
- Is `characterUpdated` always emitted after `useItem` with the new `potionRecoveryUntil` (research assumption A4)? It was on the device.
- `extensions.recoveryUntil` in production (A1): confirmed by the BE handoff; seen on the dev BE in the probe.
- A cure share outside [0, 1] hides the rows on the FE while the BE reads it as 0 — accepted?
- Any injury name of the new content unknown to this client is dropped from the lines.
- Auto-realignment after a network loss (UAT step 3): after the USB tunnel came back the app had not realigned by itself within about 40 s and was restarted; not reproduced in a controlled way. FE side to investigate (WS reconnection and refetch); the BE is only asked whether the subscriptions need anything on reconnect.
- Spell draw of `magic` / `study` with `spellDraw`: there is no chance roll — a successful quest always teaches one learnable unknown spell, uniform among the candidates. The user asked what the probability is and has not asked for a change; recorded for awareness.
- Placeholder combat: the resolver computes the win chance from party power vs enemy life only, current HP not involved (a guard at 1 HP with gear won twice; user: «Ha vinto di nuovo, se non mi sbaglio conta solo la fortuna per vincere al momento»). Known placeholder, recorded for the future combat engine.
- Board families with the quest types of quick 261110-cgd / 261110-mag were confirmed by the user after the UAT record was closed (E5: «E5 pass», 2026-11-11).

Da riportare nella UAT della BE Phase 18 a cura del lato BE (questo repo non modifica il BE).
