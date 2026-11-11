# Phase 19: Model Review (frontend companion) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-09
**Phase:** 19-model-review (FE), discussed together with the BE Phase 19 from this repo, in the same session as the Phase 18 (stacked branches)
**Areas discussed:** Catalogo; Personaggio; Mondo e pulizia; Collocazione; Stato dei pet; XP al pet; Tetto xp (all BE-driven; the FE follows the shapes). The tables are in `../Klimmeck-Guide-BE/.planning/phases/19-revisione-dei-modelli/19-DISCUSSION-LOG.md`.
**Mode:** interactive, 2 `AskUserQuestion` calls (4 multi-select + 3 single); facts read before: every BE model file, usage counts in BE and FE, SDL type list, two read-only DB inventories, the 44 pets.

---

## Outcome for the FE

- Shapes to consume after the BE merge: `Enemy.weaknesses { base, energy }`; `CharacterAssets.ownedPets: [OwnedPet { pet, xp, currentLifePoints }]`; `QuestResult.petXpGained`; `wornEquipment` / `feet`; `SpellState.active` with `CharacterStatus.spells` and `CharacterAssets.activeSpells` removed; `PointOfInterest.quest` removed; `Lore.imagePath`.
- Added after the discuss, in chat: `Pet.attack` / `Pet.defense` (flat `Damages`) replace `Pet.damages` (user: «la cosa migliore è avere attack: Damages e defense: Damages»).
- Unchanged on the wire: `Enemy.spells`, `maxActiveSpells` (computed by the BE), `CityShop`.
- FE-only: fragile parsers (`PointOfInterest.type`/`location`) fixed with tests.
- Rejected / deferred by the user: single inventory list; spell `damages` and `requiredLearnTime` (separate session); pet state removal (kept, moved to the character).
