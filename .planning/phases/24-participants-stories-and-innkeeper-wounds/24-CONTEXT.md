# Phase 24: Participants' Stories and Innkeeper Wounds - Context

**Gathered:** 2026-11-21 (interactive discuss, joint with the BE Phase 25 «Storie dei partecipanti e ferite dell'oste»; this file is authoritative for both, same numbering D-01..D-17)
**Status:** Ready for planning — branch `feat/24-participants-stories-and-innkeeper-wounds` off `develop`; BE branch `feat/25-storie-dei-partecipanti-e-ferite-dell-oste` off `develop`. The layout review branch `fix/ui-layout-review` stays local and open (user decision), untouched by this phase.

<domain>
## Phase Boundary

Two additions to the guided completion of `story` and `worldMission` quests (FE Phase 21 / BE Phase 22), and one rule on injuries:

1. a first page where the innkeeper reads the background of every participant before taking any decision;
2. a last page where the innkeeper may add a new entry to the background of each participant, rereading that participant's story;
3. the wounds the innkeeper inflicts by hand are his alone to remove: heal quests, potions and prizes never touch them.

Out of scope: editing or deleting existing background entries, a background editor for the player, any change to the injury maluses, the real combat engine, iOS.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- The backend is the source of truth (rule 4); the innkeeper flow is a utility screen (chrome allowed); no blocking loading in an active player session (rule 2).
- `CharacterInfos.background` is a list of entries since BE PR #47 (2026-11-18); the Profile already draws one block per entry and seals a new one with `newEntrySigil` (device-only «seen» store, `NewEntriesCubit`).
- Non-additive SDL changes are declared in the BE handoff; FE plans that select new fields are gated on the BE merge (schema check on the merged SDL).
- One-off migrators leave the repo after the real boot; no content file in either repo.

### Reading the stories (first step)
- **D-01 (user, verbatim):** «Come primo step serve una schermata dove ogni partecipante ha una propria dropdown, al cui interno si trova il suo background, in modo che io possa leggere la storia di tutti prima di prendere decisioni.»
- **D-02 (user, «Prima dell'avvio»):** the reading page is what the flow opens on, before the mission is started and with the players still free; «Inizia la missione» sits at the bottom of that page. Once the mission is started the page stays reachable by going back. Starting the mission keeps its explicit tap (Phase 21 D-28): opening the page never creates the draft.
- **D-02a (user, 2026-11-21, «Sì, niente popup allora»):** the page with the dropdowns stays as fixed in D-01/D-02; the alternative raised by the user (a popup with the background on the tap of a character's name in the request cards) is dropped: no popup.
- **D-03:** one dropdown per participant (name and rank on the header, the shared `Dropdown` component), closed at first; inside, every background entry in order, oldest first. A participant with no background shows one in-world line saying so.

### Adding to the stories (last step)
- **D-04 (user, verbatim):** «serve un ultimo step (alla fine di tutto), dove io possa fare un aggiunta al background di ogni partecipante, potendo anche rileggere la storia del singolo».
- **D-05 (user, «Dopo il riepilogo, prima di chiudere»):** the page comes after the recap and is the last of the flow; one «Concludi» closes the mission and writes the additions in the same BE transaction. The additions live in the draft: leaving and coming back finds them.
- **D-06 (user, verbatim):** «Le aggiunte sono per partecipante, non una sola per tutti»: one text field per participant, each optional; an empty field adds nothing to that participant.
- **D-07 (user, «1000 caratteri»):** one addition holds at most 1000 characters. The BE validates (same counting rule as the creation background, which stays at its 500 graphemes — «400» in the discuss was a slip of the orchestrator); the FE counter is UX only.
- **D-08:** an addition becomes a new entry appended at the end of the participant's `infos.background`. Existing entries are never edited or removed here. On the last page each participant has a dropdown with the story so far (as in D-03) and the field for the addition under it.

### What the player sees
- **D-09 (user, «Sigillo + riga nel foglio del risultato»):** the existing wax sigil marks Profile and the new entry; in addition the result sheet of the mission carries one line for a participant whose background got an addition. Proposed copy: «La tua storia ha una nuova pagina» (Claude's wording, to confirm at the UAT). No dedicated push. The BE says on the result whether an addition was written (field name fixed in the plan); the app never infers it.

### Scope of the two steps
- **D-09a (research, 2026-11-21):** the background entries at DB are already lists (the orchestrator migrated the seven characters on 2026-11-18 with PR #47, and new characters are born with a list): the addition is a plain append. The FE branch is stacked on `fix/ui-layout-review`, where the background list, the wax sigil and `NewEntriesCubit` live.
- **D-10:** the two pages exist only in the guided flow, that is for `story` and `worldMission`. Every other pending request keeps today's completion.

### Innkeeper wounds
- **D-11 (user, verbatim):** «Le ferite applicate dall'innkeeper sono rimuovibili solo dall'innkeeper, non sono influenzabili da quest heal, pozioni o premi».
- **D-12 (user, «Solo quelle aggiunte a mano»):** an innkeeper wound is one the innkeeper adds by his own hand in the corrections of a resolution, of any quest type (guided flow or plain pending request). A wound produced by the simulated fight and left as it is stays an ordinary, curable wound. In the guided flow: the wounds of the corrected outcome that the simulation did not produce.
- **D-13 (user, «Nelle correzioni di ogni risoluzione»; amended 2026-11-21, user verbatim: «Le correzioni possono rimuovere qualsiasi tipo di ferita, quelle dell'oste e non»):** the corrections of every resolution, in the guided flow and in the other pending requests, can remove any wound the participant carries, the innkeeper's and the ordinary ones alike; the innkeeper's are marked. Today the corrections can only add wounds: the removal is new on both sides.
- **D-14:** no cure reaches an innkeeper wound: the cure of a heal quest, a potion drunk from the Journal, the cure inside a prize (rank block, guided prize `cure`), and any other cure path found by the research. `injuriesHealed` never lists one. A cure whose only matching wounds are the innkeeper's has no effect, and the existing no-effect notices and refusals treat it so.
- **D-15 (user):** the player recognises an innkeeper wound: in the Journal it carries a mark and the line «Troppo grave per essere curata» (user's copy, replacing the proposed «Solo l'oste può guarirla»); heal quest sheets («Cura le tue ferite: …») and potions do not list it among the wounds they heal.
- **D-16 (technical default):** the character keeps the origin of its wounds; the shape is fixed in the plan, additive on the wire if possible (for example a second list holding the subset that belongs to the innkeeper, so every wound already at DB stays ordinary with no migration). The maluses of a wound do not depend on its origin. **Amended 2026-11-21 (user, verbatim: «l'oste per rendere non curabile una ferita curabile già presente deve prima rimuoverla e poi aggiungerla di nuovo»):** a wound the character already carries cannot be added again and never changes origin by itself; to turn an ordinary wound into an innkeeper wound the innkeeper removes it and adds it again, in the same correction.
- **D-17 (superseded 2026-11-21 by the user's amendment of D-13):** the assumption «the removal takes off innkeeper wounds only» is withdrawn: every wound is removable from the corrections.

### Claude's Discretion
- Field and type names on the wire, the draft shape for the additions, the query that serves the backgrounds to the innkeeper (the innkeeper reads other players' characters: admin-only, as the rest of the flow).
- Layout of the two pages inside the existing step scaffold (`MissionStepHeader`, back button), the mark of an innkeeper wound in the chips and in the Journal.

</decisions>

<canonical_refs>
## Canonical References

- FE: `lib/screens/innkeeper/missionCompletion/` (screen, steps, `missionDraftCubit`, `missionParticipantsCubit`), `lib/screens/innkeeper/components/injury_chips.dart`, `correction_section.dart`, `lib/shared/components/dropdown.dart`, `lib/screens/mainScreen/tabs/profile/components/background_entries.dart`, `lib/screens/mainScreen/newEntriesCubit/`.
- BE: `src/quests/guided/` (draft model, save service, `guided-outcome.ts`, `guided-completion.service.ts`), `src/quests/outcomes/gm-overrides.ts`, `src/quests/outcomes/injuries/` (`cure-injuries.ts`, `quest-cure.ts`, `heal-no-effect.ts`), `src/characters/items/item-use.plan.ts`, `src/quests/outcomes/outcome-plan.ts`, `src/models/character/character-status.model.ts`, `character-infos.model.ts`, `src/characters/creation/create-character-input.validator.ts` (counting rule of the background).
- Earlier contexts: FE `21-CONTEXT.md` / BE Phase 22 (guided flow), FE `18-CONTEXT.md` / BE Phase 18 (cures and potions).

</canonical_refs>

<deferred>
## Deferred Ideas

None raised in the discuss.

</deferred>
