# Phase 13: City Shops - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-02
**Phase:** 13-city-shops
**Areas discussed:** none selected by the user for the FE («Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma»); the FE scope was then confirmed in one question and extended by the pet decisions taken in the BE Phase 12 part of the same discuss (companions in the shop, «Compagno» slot in the Journal).
**Mode:** interactive (AskUserQuestion, recommended option first), joint discuss with the BE Phase 12 from the FE repo. The BE part is logged in `../Klimmeck-Guide-BE/.planning/phases/12-negozi-per-citta/12-DISCUSSION-LOG.md`.

Facts stated before the questions: the FE shop loads the global catalogue (`equipmentAssetsQuantity(sellable: true)` + `lootAssetsQuantity`) and is already closed off a city marker, during a travel and while awaiting aid; refusals go to the shopkeeper bubble except `SHOP_NOT_IN_CITY` (banner, Phase 9 D-16); Phase 11 D-36 removed every content file and CLI from the BE.

---

## Aree FE 13 (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| Insegna del negozio | Dove e come compare il nome della città, con o senza taglia | |
| Scaffale vuoto | Città senza negozio o pool vuoto: pagina chiusa o aperta solo per vendere? | |
| Rifiuto fuori pool | `ITEM_NOT_IN_SHOP`: fumetto del negoziante o banner? | |

**User's choice (verbatim):** «Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma».

---

## Conferma della lettura della FE 13

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, tutto così (Recommended) | Nuova query del pool al posto delle due globali; `ITEM_NOT_IN_SHOP` nel fumetto; nome della città nel titolo del foglio di acquisto; Necrorian / pool vuoto = pagina chiusa come fuori città | |
| Sì, ma senza il nome della città | Nessuna modifica visiva: solo la chiamata e il rifiuto (e la pagina chiusa dove non c'è negozio) | ✓ |
| Sì, ma pool vuoto = solo vendita | Negozio aperto solo per vendere dove il pool è vuoto | |

**User's choice:** Sì, ma senza il nome della città.

---

## Compagni nel foglio del negozio (dalla decisione BE sui pet)

| Option | Description | Selected |
|--------|-------------|----------|
| Terza lista nello stesso foglio (Recommended) | Sezione sotto equipaggiamenti e loot; nel foglio di vendita i pet posseduti; stesso flusso di selezione e conferma | ✓ |
| Foglio separato «Stalla» | Terzo tocco sulla pagina del negozio | |

**User's choice:** Terza lista nello stesso foglio.

## Slot nel Diario e titolo

| Option | Description | Selected |
|--------|-------------|----------|
| Slot «Cavalcatura» nel Diario (Recommended) | BE `mountPet`/`unmountPet`; FE slot nella sezione equipaggiamento, tap per montare come le magie della Phase 8 | ✓ (title corrected) |
| Solo BE ora, UI più avanti | UI del cambio in una fase successiva | |
| Dal foglio di vendita del negozio | Tocco «monta» accanto al pet posseduto | |

**User's choice (verbatim):** «Come risposta 1, ma il pet non essendo necessariamente un animale da sella (può essere un gatto o un cane) deve avere un titolo diverso, cavalcatura non va bene».

| Option | Description | Selected |
|--------|-------------|----------|
| «Compagno» / «Compagni» (Recommended) | Slot «Compagno» nel Diario, lista «Compagni» nel negozio; velocità solo se da sella | ✓ |
| «Animale» / «Animali» | | |
| «Bestia» / «Bestie» | | |

**User's choice:** «Compagno» / «Compagni».

---

## Claude's Discretion

- Refetch of the pool on every open / city change; how the city id reaches `ShopCubit`; failure classifiers and bubble copy; layout of the «Compagni» section and of the «Compagno» slot; test harness for the gated documents.

## Deferred Ideas

- Pet rewards from quests; companion on the Profile; pool curation from the Locanda; dropping `CityType.cityClass` for `City.size`.
