# Phase 10: Admin Panel (innkeeper) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-29
**Phase:** 10-admin-panel-innkeeper
**Areas discussed:** Accesso e struttura del pannello, Coda delle richieste, Completamento e racconto del combattimento, Teletrasporto (all four selected by the user)

Facts stated before the questions: the BE Phase 9 (user decision D-03) removed the reject and the grade/monster/reward selection; the panel completes requests with overrides of HP, injuries, consumables and spells.

---

## Accesso e struttura del pannello

| Option | Description | Selected |
|--------|-------------|----------|
| Da Impostazioni, pagina a schermo intero (Consigliato) | Section «Locanda» in Settings, innkeeper only, full-screen route on the root Navigator; satchel untouched | ✓ |
| Ottava voce della borsa | New satchel cell: grid rework, new icon | |
| Sezioni dentro Impostazioni | Queue, characters and teleport as sections of Settings | |

**User's choice:** Da Impostazioni, pagina a schermo intero.

| Option | Description | Selected |
|--------|-------------|----------|
| Il locandiere ha sempre un personaggio (Consigliato) | Creation mandatory, panel inside the shell | ✓ |
| Accesso anche dalla pagina di creazione | «Entra nella Locanda» on the creation page, shell without character | |
| Pannello prima della shell | Panel first, «Gioca» button to the shell | |

**User's choice:** Il locandiere ha sempre un personaggio.

| Option | Description | Selected |
|--------|-------------|----------|
| Due sezioni: Richieste e Personaggi (Consigliato) | Queue tab + all-characters tab with search and teleport | |
| Solo la coda | One list; teleport only from a queue row; no panel teleport for characters without pending requests | ✓ |
| Tre sezioni: Richieste, Personaggi, Teletrasporto | Standalone teleport tool with two pickers | |

**User's choice:** Solo la coda (recommended option overruled).

---

## Coda delle richieste

| Option | Description | Selected |
|--------|-------------|----------|
| Una carta per quest con i partecipanti (Consigliato) | Group by `quest.id`, one «Completa» per card | ✓ |
| Una voce per personaggio | Flat list as the BE sends it | |

**User's choice:** Una carta per quest con i partecipanti.

| Option | Description | Selected |
|--------|-------------|----------|
| Carta visibile, chi viaggia è grigio, Completa solo quando tutti sono arrivati (Consigliato) | Travelling participants greyed with ETA, button disabled until arrival | ✓ |
| Nascondi la carta finché c'è qualcuno in viaggio | Literal ADMIN-02 | |
| Nascondi solo i singoli in viaggio | Card completable while someone travels | |

**User's choice:** Carta visibile, chi viaggia è grigio, Completa solo quando tutti sono arrivati.

| Option | Description | Selected |
|--------|-------------|----------|
| Essenziali più stato (Consigliato) | Title/type, name/title, twitchId, location name, state, points, seats | |
| Minime | Quest title, character name, state; the rest in the completion form | ✓ |
| Complete con scheda personaggio | Tap opens the character sheet loaded with `character(id)` | |

**User's choice:** Minime (recommended option overruled).

| Option | Description | Selected |
|--------|-------------|----------|
| Ordine del BE, stato vuoto in pergamena (Consigliato) | `startDate` ascending, travellers last; «Nessuna richiesta in attesa» | ✓ |
| Raggruppa per tipo | Stories first, then worldMissions | |
| Più recenti in cima | Newest first | |

**User's choice:** Ordine del BE, stato vuoto in pergamena.

---

## Completamento e racconto del combattimento

| Option | Description | Selected |
|--------|-------------|----------|
| Due azioni: «Completa» e «Racconta il combattimento» (Consigliato) | Quick completion without overrides + form path | |
| Sempre il form | One button opening the form with «no change» defaults, confirm from there | ✓ |
| Solo completamento rapido | No overrides in this phase | |

**User's choice:** Sempre il form (recommended option overruled).

| Option | Description | Selected |
|--------|-------------|----------|
| HP a cursore, ferite a chip, consumi e magie da liste con quantità (Consigliato) | Slider 1..max, 28 injury chips, owned loot and active spells with steppers; `character(id)` on open | ✓ |
| Solo HP e ferite | Consumables and spells deferred | |
| Campi essenziali senza liste | Numeric HP, dropdown injuries | |

**User's choice:** HP a cursore, ferite a chip, consumi e magie da liste con quantità.

| Option | Description | Selected |
|--------|-------------|----------|
| Dialog di conferma riusato e riepilogo dei risultati (Consigliato) | Shared confirmation dialog with recap, then the returned results per character | ✓ |
| Dialog di conferma e solo un avviso | «Richiesta completata» only | |
| Conferma solo con override | No dialog for the plain completion | |

**User's choice:** Dialog di conferma riusato e riepilogo dei risultati.

| Option | Description | Selected |
|--------|-------------|----------|
| Per codice, inline nel pannello (Consigliato) | `NOT_FOUND` card removed, override codes under the participant, `FORBIDDEN` pops, network «Riprova» | ✓ |
| Banner in-app generico | Map banner for every error | |

**User's choice:** Per codice, inline nel pannello.

---

## Teletrasporto

| Option | Description | Selected |
|--------|-------------|----------|
| Lista dei POI raggruppata per città (Consigliato) | Sheet with cities and their POIs, search | |
| Solo i marker delle città | City markers only, as a list | |
| Tocco sulla mappa | Map in pick mode | |

**User's choice (free text, verbatim):** «Aprirei la mappa, con la pedina che invece di indicare il mio personaggio, indica il personaggio che ho selezionato. A quel punto posso spostare la pedina a mano».

| Option | Description | Selected |
|--------|-------------|----------|
| Dialog di conferma con nome e destinazione (Consigliato) | «Teletrasportare X a Y?» | |
| Nessuna conferma | Drop executes at once | ✓ |

**User's choice:** Nessuna conferma (recommended option overruled).

| Option | Description | Selected |
|--------|-------------|----------|
| Il BE giudica, il pannello mostra il codice (Consigliato) | Button always active, codes inline | |
| Disabilita in anticipo | FE hides the action when the standard lane is busy | ✓ |

**User's choice:** Disabilita in anticipo (satisfied by the hiding rule below: busy characters are not listed at all).

| Option | Description | Selected |
|--------|-------------|----------|
| Ammesso, è il caso d'uso principale (Consigliato) | Teleport of a participant travelling to the quest | |
| Nascosto mentre viaggia | Action only for arrived participants | |

**User's choice (free text, verbatim):** «Nessun personaggio che ha accetato una quest, che sia in viaggio o in combattimento, non deve comparire nella lista dei pending che l'admin può gestire. Se sei in viaggio da una città all'altra invece questa regola non vale».

### Follow-up block

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, corsia standard occupata = nascosto (Consigliato) | Hidden while `quests.pendingQuest` is set; free travel and travel to the story/worldMission greyed | ✓ (with a clarification) |
| Nascosto anche durante il viaggio verso la story/worldMission | Any automatic quest travel hides the entry | |

**User's choice (verbatim):** «Un chiarimento: story e worldMission non richiedono alcun viaggio. Per il resto la prima risposta va bene» — confirmed against the BE: automatic travel exists only for the standard lane.

| Option | Description | Selected |
|--------|-------------|----------|
| Sì: campo additivo e rifiuto QUEST_IN_PROGRESS (Consigliato) | Additive field on the queue entry + BE refusal of the completion; goes into the BE Phase 10 | ✓ |
| Solo il campo additivo, il BE non blocca | UX-only filter | |

**User's choice:** Sì: campo additivo e rifiuto QUEST_IN_PROGRESS.

| Option | Description | Selected |
|--------|-------------|----------|
| Sui marker delle città, poi torna al pannello (Consigliato) | Phase 7 drop zones, immediate teleport, panel pushed again, «Annulla» chip | ✓ |
| Sui marker delle città, poi resta sulla mappa | Stay on the Map after the teleport | |
| Anche sui POI interni delle città | Inner POIs as drop targets | |

**User's choice:** Sui marker delle città, poi torna al pannello.

| Option | Description | Selected |
|--------|-------------|----------|
| Sparisce: c'è solo la pedina del personaggio scelto (Consigliato) | Own pawn hidden, selected pawn with name label | ✓ |
| Resta visibile ma non trascinabile | Two pawns | |

**User's choice:** Sparisce: c'è solo la pedina del personaggio scelto.

---

## Claude's Discretion

Copy and layout (provisional), neutral style of the confirmation dialog, optimistic removal of a completed card, loaders on explicit actions, refetch triggers beyond D-18, the modelling of the teleport mode, the resolution of the selected character's coordinates, the handling of a busy participant inside a worldMission card (hidden participant, disabled button with caption — default derived from the user rule, to veto).

## Deferred Ideas

«Personaggi» list of all characters; inner POIs as drop targets; BE emission of the queue on location/travel changes; reject with refund; audit viewer.
