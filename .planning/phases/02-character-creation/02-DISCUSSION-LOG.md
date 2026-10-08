# Phase 2: Character Creation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-08
**Phase:** 02-character-creation
**Areas discussed:** Ritratto (set curato, upload, NSFW), Struttura e stile del flusso, Regole dei campi. Area "Contratto backend mancante" risolta dalla direttiva dell'utente (lavorare anche sul BE).

---

## Selezione aree

| Option | Description | Selected |
|--------|-------------|----------|
| Contratto backend mancante | Il BE non espone createCharacter né NSFW server: proporre il contratto e sviluppare contro un fake, o bloccare? | (risolta dalla direttiva) |
| Ritratto: set curato, upload, NSFW | Obbligatorio/facoltativo, fonte del set curato, timing upload, severità NSFW | ✓ |
| Struttura e stile del flusso | Wizard vs pagina unica, riepilogo, tono, landscape | ✓ |
| Regole dei campi | Nome, età (intero nel BE), background, pronome, default | ✓ |

**User's choice:** le tre aree sopra più la direttiva libera: *"Lavora anche sul BE seguendo il piano presente anche là. Hai accesso alla directory. Crea anche una pagina subito dopo la login con un layout provvisorio. L'utente può inserire sesso, caricare un'immagine (deve andare in store su cloudinary), nome, pronomi, tipo classe, anni e avere la possibilità di scrivere una breve storia di background"*.
**Notes:** la direttiva chiude l'area "contratto backend": il BE viene implementato in questa fase, nel suo repo, con il suo GSD (fase decimale 2.1).

---

## Ritratto: set curato, upload, NSFW

### Il ritratto è obbligatorio o facoltativo?

| Option | Description | Selected |
|--------|-------------|----------|
| Facoltativo con default (pawn per sesso) | imagePath null → pawn già esistente (SexType.pawnPath) | |
| Obbligatorio | Niente creazione senza ritratto | |
| Other | — | ✓ |

**User's choice:** facoltativo, ma l'immagine di default è `assets/images/placeholders/silhouette.jpeg` (già nel progetto).

### Da dove arrivano i ritratti curati?

| Option | Description | Selected |
|--------|-------------|----------|
| Cartella Cloudinary | Cartella dedicata letta via REST già esistente | |
| Asset nel bundle | PNG/SVG in assets/images | |
| Solo upload, per ora | Solo galleria/camera; set curato rinviato | ✓ |

**User's choice:** Solo upload, per ora.

### Quando parte l'upload su Cloudinary?

| Option | Description | Selected |
|--------|-------------|----------|
| Subito alla scelta | Scelta → upload → anteprima dall'URL; mutation con solo URL | |
| Al submit | File locale fino a "Crea"; upload + mutation in sequenza | ✓ |

**User's choice:** Al submit.

### Controllo NSFW lato server (il BE non ne ha)?

| Option | Description | Selected |
|--------|-------------|----------|
| Solo on-device ora, BE dopo | Pre-screen nell'app; controllo server come debito BE | |
| Cloudinary AI moderation nel BE | Add-on AWS Rekognition sull'upload | |
| Nessun filtro per ora | Né on-device né server: CHAR-06 rinviato | ✓ |

**User's choice:** Nessun filtro per ora.
**Notes:** CHAR-06 va marcato come rinviato in REQUIREMENTS/ROADMAP dal primo plan.

---

## Struttura e stile del flusso

### Pagina unica o wizard a step?

| Option | Description | Selected |
|--------|-------------|----------|
| Pagina unica scrollabile | Tutti i campi in un form; landscape: ritratto a sinistra, campi a destra | ✓ |
| Wizard a step | 3 step con avanti/indietro | |

**User's choice:** Pagina unica scrollabile.

### Serve una conferma prima di inviare?

| Option | Description | Selected |
|--------|-------------|----------|
| Nessuna, bottone Crea in fondo | Il form è il riepilogo; bottone attivo solo se valido | ✓ |
| Dialog di conferma | "Dare vita a <nome>?" | |

**User's choice:** Nessuna, bottone Crea in fondo.

### Che stile per il layout provvisorio?

| Option | Description | Selected |
|--------|-------------|----------|
| Material semplice con tema KG | Scaffold + AppBar come SignIn, widget standard | |
| Scheda personaggio in stile pergamena | Sfondo pergamena, titoli Cinzel, righe da scheda | ✓ |

**User's choice:** Scheda personaggio in stile pergamena (pur restando "provvisorio").

### Si può uscire/cambiare account dalla pagina?

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, azione Esci nell'AppBar | Riusa AuthCubit.logout() + LogoutConfirmationDialog | ✓ |
| No, nessuna uscita | Logout solo con Settings (Phase 4) | |

**User's choice:** Sì, azione Esci nell'AppBar.

---

## Regole dei campi

### Includiamo la razza (RaceType) come da CHAR-03?

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, includila | RaceType esiste su entrambi i lati; race obbligatoria nel BE | ✓ |
| No, escludila per ora | Il BE dovrebbe accettare race assente | |

**User's choice:** Sì, includila.

### Regole per il nome?

| Option | Description | Selected |
|--------|-------------|----------|
| 2–20 caratteri, lettere/spazi/apostrofi/trattini, unico lato server | Validazione client + unicità BE con errore dedicato | ✓ |
| Solo lunghezza min/max | Nessun vincolo di caratteri né unicità | |
| Decidi tu | Claude sceglie in pianificazione | |

**User's choice:** 2–20 caratteri, lettere/spazi/apostrofi/trattini, unico lato server.

### Età: input e limiti?

| Option | Description | Selected |
|--------|-------------|----------|
| Campo numerico, 16–1000 | Limiti ampi per razze longeve | |
| Campo numerico, 16–120 | Limiti umani | |
| Decidi tu | — | |
| Other | — | ✓ |

**User's choice:** *"I limiti devono essere validi in base alla razza scelta. Per questo l'età può essere scelta solo successivamente."*

#### Follow-up: quali limiti per razza?

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, usa questa tabella | Umano 16–100 · Elfo 100–750 · Mezzelfo 20–180 · Nano 50–350 · Halfling 20–150 · Gnomo 40–500 · Draconide 15–80 · Tiefling 18–100 · Aarakocra 3–30 | ✓ |
| Stessa tabella ma minimo 16 ovunque | Massimi come sopra, minimo uniforme | |

**User's choice:** Sì, usa questa tabella.

#### Follow-up: dove vive la tabella età/razza?

| Option | Description | Selected |
|--------|-------------|----------|
| BE fonte di verità, esposta al FE via query | Il BE valida e espone (es. raceTraits); il FE la legge | ✓ |
| Costante speculare su FE e BE | Hardcoded nei due repo | |
| Decidi tu | — | |

**User's choice:** BE fonte di verità, esposta al FE via query.

### Background obbligatorio? lunghezza?

| Option | Description | Selected |
|--------|-------------|----------|
| Facoltativo, max 500 caratteri | Multilinea con contatore; vuoto → stringa vuota nel BE | ✓ |
| Obbligatorio, max 500 caratteri | Crea disattivo senza almeno una frase | |
| Facoltativo, max 1000 caratteri | Più spazio narrativo | |

**User's choice:** Facoltativo, max 500 caratteri.

---

## Chiusura

| Option | Description | Selected |
|--------|-------------|----------|
| Pronto per il context | Scrivere CONTEXT.md e DISCUSSION-LOG.md | ✓ |
| Esplora altre aree | Transizione post-creazione, bypass dev, copy errori | |

**User's choice:** Pronto per il context.

## Claude's Discretion

- Meccanismo di aggiornamento dello `User` in `AuthCubit` dopo la creazione.
- Package picker, downscale/compressione, dimensione massima upload, anteprima quadrata senza crop tool.
- BE: `background` nullable vs stringa vuota; default iniziali del personaggio; forma della query `raceTraits`.
- Comportamento al cambio razza con età fuori range (errore, mai clamp).
- Nomi di cartelle/classi secondo `docs/rules/naming.md`; eventuale `02-UI-SPEC.md` leggero.

## Deferred Ideas

- Set curato di ritratti (Cloudinary o bundle).
- Pre-screen NSFW on-device + controllo autoritativo server (CHAR-06).
- Wizard multi-step; layout definitivo non provvisorio; reset dev del personaggio; schermata di benvenuto post-creazione.
