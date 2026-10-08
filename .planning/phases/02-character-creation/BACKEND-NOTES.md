# BACKEND-NOTES — Phase 2 Character Creation (handoff FE → BE)

- **Fase FE:** 02-character-creation (requisiti CHAR-01..09; CHAR-06 rinviato; decisioni D-01..D-25 in `02-CONTEXT.md`)
- **Data:** 2026-10-08
- **Stato:** **proposta di contratto.** Il BE oggi non ha né una mutation di creazione personaggio né la tabella età/razza. Per direttiva dell'utente il lato BE viene costruito in questa stessa fase, nel repo BE, come fase GSD decimale **2.1 "Character Creation Contract"** (branch `feat/02.1-character-creation`, PR verso `develop`). Quando il BE 2.1 genera `src/schema.gql`, **vince lo schema** su tutto ciò che è scritto qui; il suo `BACKEND-NOTES.md` diventa la fonte per il FE.
- **Consumatori:** FE Phase 2 (pagina di creazione), indirettamente FE Phase 3 (il nuovo character entra nella subscription `characterUpdated`).

---

## 0. TL;DR per il BE

1. **Mutation `createCharacter(input: CreateCharacterInput!): User!`** sull'identità autenticata (niente `userId` in input). Crea il `Character`, imposta `User.currentCharacter`, restituisce lo `User` aggiornato (con `currentCharacter { id … }`). Un utente che ha già `currentCharacter` riceve `CHARACTER_ALREADY_EXISTS`.
2. **Query `raceTraits`** (nome indicativo): per ogni `RaceType` restituisce `minAge` e `maxAge`. Il FE la legge per abilitare e limitare il campo età; il BE la usa per validare. **Nessuna copia della tabella nel FE.**
3. **Validazione autoritativa lato BE** (il client la replica solo come UX): nome 2–20 caratteri dopo trim, solo lettere Unicode/spazi/apostrofi/trattini, **unico case-insensitive**; età intera nel range della razza; background facoltativo ≤ 500 caratteri; enum validi.
4. **Codici d'errore stabili** in `errors[0].extensions.code` (proposta): `CHARACTER_NAME_INVALID`, `CHARACTER_NAME_TAKEN`, `CHARACTER_AGE_OUT_OF_RANGE`, `CHARACTER_ALREADY_EXISTS`, più il generico di validazione. Il FE mappa i codici, mai i messaggi.
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

### Tabella età per razza (accettata dall'utente, ispirata a D&D 5e)

| race | minAge | maxAge |
|---|---|---|
| human | 16 | 100 |
| elf | 100 | 750 |
| halfelf | 20 | 180 |
| dwarf | 50 | 350 |
| halfling | 20 | 150 |
| gnome | 40 | 500 |
| dragonborn | 15 | 80 |
| tiefling | 18 | 100 |
| aarakocra | 3 | 30 |

---

## 3. Autorizzazione e concorrenza (da coordinare con BE Phase 3/4)

- La mutation usa **solo l'identità del bearer**: nessun client può creare un personaggio per un altro utente.
- **Una sola creazione per utente:** l'assegnazione di `currentCharacter` deve essere atomica (es. `findOneAndUpdate` condizionato su `currentCharacter: null`) per evitare doppioni con due submit concorrenti; il perdente riceve `CHARACTER_ALREADY_EXISTS`.
- **Unicità del nome:** indice unico case-insensitive (collation o campo normalizzato) su `infos.name`; la violazione mappa su `CHARACTER_NAME_TAKEN`.
- Dev bypass: il dev user del BE nasce con `currentCharacter: null`, quindi in dev la pagina compare al primo avvio finché il personaggio non esiste. Per ri-testare si cancella il character/`currentCharacter` a mano in Mongo (un reset comodo è un'idea rinviata).

---

## 4. Domande aperte per il BE 2.1

1. `background` vuoto: stringa vuota (schema invariato) o campo nullable?
2. Enum GraphQL per `sex`/`pronoun`/`race` oppure restano `String` validati a mano?
3. Nome esatto della query (`raceTraits` vs metadata sull'enum) e se includere altri tratti futuri.
4. Default iniziali del personaggio (POI di partenza, coins, HP, `maxActiveSpells`).
5. Limite dimensione file sull'upload (oggi nessuno esplicito): proposta ≤ 5 MB con downscale client-side.
