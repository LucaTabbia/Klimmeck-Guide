---
status: in-progress
phase: 08-spells-section-journal-tab
plan: 12
device: Android (USB, adb reverse tcp:3000)
be_ref: 10e5f43
be_pr: 14
fe_ref: 76d30a1
started: 2026-10-27
---

# Phase 8 — Device UAT (Spells Section, Journal Tab)

Manual E2E of plan 08-12 (blocking checkpoint). The app runs on the Android phone (`flutter run`, `adb reverse tcp:3000 tcp:3000`) against the local BE from `develop` (`10e5f43`, Phase 9.1 merged with PR #14) on `/api/graphql`, with the UAT data of the BE 9.1 handoff §7.

## Preconditions

- BE `develop` (with 9.1) running locally (Mongo + Redis), sweep interval at its default (60 s).
- UAT data from the BE 9.1 handoff §7 script (scratchpad, never in a repo): a `mage` character (xp 20000, 1 slot) with two known spells — `a` active with `maxUsages − 2` usages and instants at ~2 min and ~30 min, `b` inactive with `maxUsages − 1` and an instant at ~10 min; an `adventurer` with one known spell at full usages and no slot; a character with no known spells.
- A GraphQL client session of your choice for the step 9 race (no tokens in the transcript).
- Notes carry no ids of real users and no secrets.

## Steps

| Step | Expected | Result | Note |
|------|----------|--------|------|
| 1. **List and slots** (SPELL-01/02/07, D-10, D-13, D-14) | mage character → Diario → open «Magie imparate». The slot row has exactly `maxActiveSpells` boxes; each known spell row shows the card (no number on the row card), the description and «Usi: 3 · Recupero: 2 h · Danno: Fuoco 12»-style line; active spells carry the red bookmark and stay in their list position; slot cards show only the pencil usages number. | pending | |
| 2. **Countdown** (SPELL-05, D-04, D-05) | the active spell with ~2 min and ~30 min instants reads «Usi: 1/3 · prossimo tra 2 min» (numbers per data); it decreases each minute; under one minute «meno di 1 min»; at the instant «in arrivo…»; within ≤ 60 s (BE sweep) the use returns (usages +1, slot pencil number animates) and the row moves to the ~30 min countdown. | pending | |
| 3. **Recovery never stops** (D-01 user rule) | tap the recovering active row → it leaves the slot with the attenuated look, then full; its row keeps counting down; wait past an instant: the use returns while unequipped; tap again to equip → usages unchanged (no reset to max). | pending | |
| 4. **Optimistic toggle** (SPELL-03/04/06, D-06, D-08, D-16) | tap an inactive row → light haptic, card appears in a free slot at once attenuated, then full when `characterUpdated` arrives; tap the slot card → it leaves at once; tapping a spell while it is still attenuated does nothing. | pending | |
| 5. **Full slots** (D-07) | fill every slot, tap another inactive row → selection-click haptic, the row shakes, banner «Magia non equipaggiata — Slot pieni: disequipaggia una magia»; nothing changes on the BE (optional: BE log shows no equipSpell call). | pending | |
| 6. **Zero slots** (D-11) | character below `mage` → no slot row, the line «Nessuno slot per le magie: cresci di rango», known spell visible with its line; tap → shake + banner «Nessuno slot disponibile». | pending | |
| 7. **No spells** (D-12) | character with no known spells and no slots → the «Magie imparate» section is not there at all. | pending | |
| 8. **Rollback** (SPELL-06, D-17, D-18) | enable airplane mode, tap an inactive row → attenuated card in the slot; within 15 s it springs back (shake) with a banner («Connessione assente, riprova» or «Il server non ha risposto in tempo: controlla le magie prima di riprovare»); disable airplane mode, the view realigns without any loading. | pending | |
| 9. **Race / stale view** (D-17 F1) | from your GraphQL client equip spell X for the same character while the app is in background; reopen and immediately tap X's row before the update lands (or with the app offline-then-online): either the row already shows X active (subscription won) or the tap gets `SPELL_ALREADY_ACTIVE` → no banner and the row realigns by itself. Record which happened. | pending | |
| 10. **Long-press sheet** (SPELL-04, D-09) | long-press a row and a slot card → the parchment sheet rises from the bottom on the right with name, description, damage, use type, max usages, recovery time, learn requirements, current usages and next recovery; tapping its bookmark toggles the spell (same feedback as the row); tap outside closes it. | pending | |
| 11. **Server time** (D-04) | change the phone clock by ±2 h in Android settings, return to the app → the countdown is unchanged (within a minute). | pending | |
| 12. **Slot unlock and tab change** (SPELL-07, F3) | as GM raise the sub-mage character's xp/title to `mage` → a new slot box appears live without leaving the Diario; then tap a row and switch immediately to the Map tab with airplane mode on → the failure banner still appears on the Map within 15 s. | pending | |

## Outcome

Pending: verdicts from the device session (Task 3 of 08-12 records them, ticks the requirements that passed and closes the phase).
