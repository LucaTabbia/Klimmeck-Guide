# BACKEND-NOTES — Phase 2 Character Creation (handoff FE → BE)

- **Fase FE:** 02-character-creation (requisiti CHAR-01..09; CHAR-06 rinviato; decisioni D-01..D-25 in `02-CONTEXT.md`)
- **Data:** 2026-10-08
- **Stato:** contratto implementato da BE 02.1 — vedi `Klimmeck-Guide-BE/.planning/phases/02.1-character-creation-contract/BACKEND-NOTES.md` (fonte per il FE). Lo schema `src/schema.gql` vince su questo documento; nessun nome diverge (vedi §5).
- **Consumatori:** FE Phase 2 (pagina di creazione), indirettamente FE Phase 3 (il nuovo character entra nella subscription `characterUpdated`).

---

## 0. TL;DR per il BE

1. **Mutation `createCharacter(input: CreateCharacterInput!): User!`** sull'identità autenticata (niente `userId` in input). Crea il `Character`, imposta `User.currentCharacter`, restituisce lo `User` aggiornato (con `currentCharacter { id … }`). Un utente che ha già `currentCharacter` riceve `CHARACTER_ALREADY_EXISTS`.
2. **Query `raceTraits`** (nome indicativo): per ogni `RaceType` restituisce `minAge` e `maxAge`. Il FE la legge per abilitare e limitare il campo età; il BE la usa per validare. **Nessuna copia della tabella nel FE.**
3. **Validazione autoritativa lato BE** (il client la replica solo come UX): nome 2–20 caratteri dopo trim, solo lettere Unicode/spazi/apostrofi/trattini, **unico case-insensitive**; età intera nel range della razza; background facoltativo ≤ 500 caratteri; enum validi.
4. **Codici d'errore stabili** in `errors[0].extensions.code` (proposta): `CHARACTER_NAME_INVALID`, `CHARACTER_NAME_TAKEN`, `CHARACTER_AGE_OUT_OF_RANGE`, `CHARACTER_ALREADY_EXISTS`, `STARTING_LOCATION_UNAVAILABLE`, più il generico di validazione. Il FE mappa i codici, mai i messaggi. Fissati nel CONTEXT BE 2.1 (D-04).
5. **Upload immagine:** si riusa il REST esistente `POST /cloudinary/uploadImage` (bearer, campo multipart `file`, cartella `characters_profile`, risposta `{ url }`). L'upload avviene **al submit**, prima della mutation; `imagePath` nell'input è l'URL restituito oppure assente.
6. **Nessun controllo NSFW** in questa fase, né on-device né server (decisione utente 2026-10-08). Debito tracciato per l'hardening BE (Phase 10): candidata la moderazione AI di Cloudinary.

---

## 1. Flusso lato app

1. Cold start / login → `AuthAuthenticated(user)`. Se `user.currentCharacter == null` l'app mostra la pagina di creazione (FE D-01).
2. La pagina chiama `raceTraits` una volta (tollerante all'errore: il campo età resta disabilitato finché la tabella non arriva).
3. L'utente compila sesso, nome, pronome, razza, classe, età, background (facoltativo) e sceglie eventualmente un'immagine dalla galleria/camera (resta locale).
4. **Submit:** (a) se c'è un file → `POST /cloudinary/uploadImage` → `url`; (b) `createCharacter(input)` con `imagePath = url` oppure omesso.
5. Risposta `User` con `currentCharacter` popolato → l'app entra nella shell principale; `CharacterCubit.loadCharacter(currentCharacter.id)` e la subscription partono come oggi.

Errori: upload fallito → nessuna mutation, dati conservati; mutation fallita → errore inline per codice, dati conservati, URL già caricato riusato al retry (orfani su Cloudinary accettati per ora).

---

## 2. Contratto proposto

```graphql
input CreateCharacterInput {
  name: String!
  sex: SexType!          # male | female (oggi CharacterInfos.sex è String: valutare enum GraphQL)
  pronoun: PronounType!  # he | she | them
  race: RaceType!        # dragonborn, elf, gnome, halfling, halfelf, human, dwarf, tiefling, aarakocra
  classType: ClassType!  # enum già esistente nel BE
  age: Int!
  background: String     # facoltativo, ≤ 500; assente/vuoto → "" oppure null (scelta BE)
  imagePath: String      # URL Cloudinary restituito da /cloudinary/uploadImage
}

type RaceTraits {
  race: RaceType!
  minAge: Int!
  maxAge: Int!
}

type Query {
  raceTraits: [RaceTraits!]!
}

type Mutation {
  createCharacter(input: CreateCharacterInput!): User!
}
```

Note:
- I campi `sex`, `pronoun`, `race` oggi sono `String!` su `CharacterInfos`: il BE decide se introdurre enum GraphQL (il FE già usa `values.byName`, quindi entrambe le forme sono compatibili purché i nomi coincidano con gli enum Dart).
- Lo stato iniziale del personaggio (location di partenza, livello/titolo `rookie`, coins, HP, assets vuoti, `quests` vuote) è **responsabilità del BE** e si decide nel discuss della fase 2.1 riusando default e fixture esistenti.

### Tabella età per razza (allineata al lore, accettata dall'utente il 2026-10-09 — sostituisce la tabella D&D)

| race | minAge | maxAge | lore |
|---|---|---|---|
| human | 16 | 200 | 60–70 normali, maghi oltre 200 |
| elf | 100 | 9999 | vita infinita |
| halfelf | 16 | 130 | 120–130 |
| dwarf | 40 | 140 | 130–140 |
| gnome | 16 | 60 | ~60 |
| halfling | 16 | 70 | ~70 |
| dragonborn | 16 | 180 | 150–180 |
| tiefling | 16 | 120 | 100–120 |
| aarakocra | 3 | 40 | 30–40 |

### Stato iniziale del personaggio (deciso nel discuss BE 2.1, 2026-10-09)

- `status`: `level 1`, `title rookie`, `xp 0`, `currentLifePoints 100`, `maxLifePoints 100`, `coins { gold 0, silver 5, copper 0 }`, `injuries []`, `spells []`; `quests` vuote; `assets` vuoti (nessun equipaggiamento iniziale).
- `status.location` = `markerLocation` della City "patria" della razza: elf → `elfCapital`; gnome, dwarf, tiefling → `motherCapital`; halfling → `liberiaCapital`; aarakocra → `aarakocraVillage`; dragonborn → `mountainVillage`; human e halfelf → a caso tra `drusteaCapital`, `valanCapital`, `mirwaCapital`, `liberiaCapital`. Nessuna City per quel tipo → `STARTING_LOCATION_UNAVAILABLE`, niente creato.

---

## 3. Autorizzazione e concorrenza (da coordinare con BE Phase 3/4)

- La mutation usa **solo l'identità del bearer**: nessun client può creare un personaggio per un altro utente.
- **Una sola creazione per utente:** l'assegnazione di `currentCharacter` deve essere atomica (es. `findOneAndUpdate` condizionato su `currentCharacter: null`) per evitare doppioni con due submit concorrenti; il perdente riceve `CHARACTER_ALREADY_EXISTS`.
- **Unicità del nome:** indice unico case-insensitive (collation o campo normalizzato) su `infos.name`; la violazione mappa su `CHARACTER_NAME_TAKEN`.
- Dev bypass: il dev user del BE nasce con `currentCharacter: null`, quindi in dev la pagina compare al primo avvio finché il personaggio non esiste. Per ri-testare si cancella il character/`currentCharacter` a mano in Mongo (un reset comodo è un'idea rinviata).

---

## 4. Domande aperte — risolte nel discuss BE 2.1 (2026-10-09)

1. `background` vuoto → **stringa vuota**, schema invariato (BE D-07).
2. `sex`/`pronoun`/`race`/`classType` → **enum GraphQL registrati** nell'input (BE D-02); i nomi coincidono con gli enum Dart.
3. Query **`raceTraits { race minAge maxAge }`** (BE D-11); le patrie non sono esposte.
4. Default iniziali: vedi §2 "Stato iniziale" (BE D-09/D-10).
5. Limite dimensione upload: nessuna modifica all'endpoint in questa fase (BE D-08); downscale client-side a discrezione del FE.

---

## 5. Verifica schema (2026-10-09)

Confronto nome per nome tra i documenti GraphQL dell'app e `Klimmeck-Guide-BE/src/schema.gql` rigenerato dal BE 02.1 (D-33). Esito: **nessuna divergenza, nessuna modifica al contratto del §2.**

- `createCharacter(input: CreateCharacterInput!): User!` e `raceTraits: [RaceTraits!]!` presenti e identici.
- `CreateCharacterInput`: `name`, `sex`, `pronoun`, `race`, `classType`, `age`, `background?`, `imagePath?` uguali alle chiavi di `CreateCharacterRequest.toJson`.
- `RaceTraits { race minAge maxAge }` identico; enum `SexType`, `PronounType`, `RaceType`, `ClassType` con gli stessi valori degli enum Dart.
- Codici d'errore del BE (`character-creation-error-code.enum.ts`) uguali alle costanti di `character_creation_failure.dart`.
- Precisazioni del BE gia recepite dal FE: upload riuscito solo se il body contiene `url`; selezione sullo `User` limitata a `currentCharacter { id }`; `BAD_USER_INPUT` mai mostrato.
