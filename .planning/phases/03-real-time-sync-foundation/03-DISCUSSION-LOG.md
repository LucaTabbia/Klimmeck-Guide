# Phase 3: Real-Time Sync Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-14
**Phase:** 3-real-time-sync-foundation
**Areas discussed:** Contratto User stream e fase BE companion, Cambio/cancellazione personaggio in sessione, Riconnessione/resume/refetch, Dove emergono twitchPoints e role live

---

## Contratto User stream e fase BE companion

### In quale fase BE atterra la subscription sullo User (e il filtro per identità)?

| Option | Description | Selected |
|--------|-------------|----------|
| Companion decimale BE 2.2 in lockstep | Fase 2.2 "Real-Time Sync Contract" prima della BE Phase 3, stesso schema della 02.1 | |
| Dentro la BE Phase 3 Autorizzazione | Nessuna fase nuova: lo user stream entra nella BE Phase 3 (ownership, ruoli, audit) | ✓ |
| FE Phase 3 solo Character, User dopo | Solo la subscription Character ora; SYNC-01/07 restano aperti | |

**User's choice:** Dentro la BE Phase 3 Autorizzazione (contro la raccomandazione).
**Notes:** Il FE sviluppa con fake e chiude la fase solo dopo lo schema check e l'E2E contro il BE reale (vedi ultima area).

### Che forma proponiamo al BE per la subscription sullo User?

| Option | Description | Selected |
|--------|-------------|----------|
| Senza argomenti, identità dal bearer | `userUpdated: User!` emette lo User completo dell'utente autenticato | ✓ |
| Con argomento id come characterUpdated | `userUpdated(id: String!)`, filtro identità comunque lato BE | |

**User's choice:** Senza argomenti, identità dal bearer (raccomandata).

### Per `characterUpdated` manteniamo l'argomento `id` o passiamo a "il mio personaggio"?

| Option | Description | Selected |
|--------|-------------|----------|
| Mantenere id, filtro identità lato BE | Documento FE invariato; il BE aggiunge il filtro proprietario/innkeeper | ✓ |
| Senza argomenti, personaggio corrente del bearer | Nuovo resolver risolto via currentCharacter dell'identità | |

**User's choice:** Mantenere id, filtro identità lato BE (raccomandata).

### Chiediamo al BE di emettere subito lo stato corrente all'apertura di ogni subscription?

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, snapshot su subscribe + query di sicurezza | Ogni (ri)sottoscrizione riceve subito il documento; il FE tiene la query per il resume | ✓ |
| No, solo refetch via query lato FE | BE invariato; il FE ri-interroga a ogni reconnect e resume | |

**User's choice:** Sì, snapshot su subscribe + query di sicurezza (raccomandata).

---

## Cambio/cancellazione personaggio in sessione

### Quando l'admin assegna al giocatore un personaggio diverso mentre è nella shell, cosa succede?

| Option | Description | Selected |
|--------|-------------|----------|
| Ricreare tutto il sotto-albero gameplay, senza splash | Shell e Cubit ricreati con chiave sul characterId | |
| Tenere i Cubit, ripuntare solo CharacterCubit | Shell montata, solo la stream cambia | |
| Reset duro come un cambio sessione | Splash e ricaricamento completo | |

**User's choice:** Nessuna delle opzioni — chiarimento: "L'admin non può assegnare ad uno user un personaggio diverso. Può cambiare dettagli del personaggio e basta."
**Notes:** Lo scenario admin-swap di SYNC-05 non esiste; resta la chiave sul characterId come assicurazione strutturale (D-08).

### Se il personaggio viene cancellato (currentCharacter torna null) mentre il giocatore è in gioco, cosa vede?

| Option | Description | Selected |
|--------|-------------|----------|
| Pagina di creazione subito, con avviso inline | Riga di avviso sulla scheda di creazione | |
| Pagina di creazione subito, in silenzio | Nessun avviso | |
| Dialog di avviso, poi creazione | Dialog modale poi creazione | |

**User's choice:** Chiarimento: la cancellazione avviene solo su richiesta esplicita dalle Impostazioni (→ creazione) o per morte in combattimento; in quel caso l'utente vede prima il risultato del combattimento e poi torna alla creazione.
**Notes:** In Phase 3 il routing è silenzioso (D-09); l'hold per il Combat Result è della Phase 9.

### Dialog e sheet aperti sul Navigator radice al momento dello swap o della cancellazione?

| Option | Description | Selected |
|--------|-------------|----------|
| Chiuderli tutti, come al logout | popUntil alla prima route, come AuthGate a fine sessione | ✓ |
| Lasciarli aperti | Il giocatore chiude da sé | |

**User's choice:** Chiuderli tutti, come al logout (raccomandata).

### Dove vive lo User live in sessione?

| Option | Description | Selected |
|--------|-------------|----------|
| Dentro AuthAuthenticated via adoptUser | AuthAuthenticated.user unica fonte di verità; AuthGate/SessionHome instradano già | ✓ |
| Cubit dedicato nel sotto-albero autenticato | UserCubit separato, routing da cablare a parte | |
| Decidi tu | Discrezione di Claude | |

**User's choice:** Dentro AuthAuthenticated via adoptUser (raccomandata).

---

## Riconnessione, resume e refetch

### Quando l'app torna in foreground dal background, quando ri-interroghiamo `me` e `character`?

| Option | Description | Selected |
|--------|-------------|----------|
| A ogni resume | Sempre due query al rientro | ✓ |
| Solo se il socket risulta caduto | Refetch solo dopo notConnected | |
| Solo dopo N secondi di background | Soglia per evitare raffiche | |

**User's choice:** A ogni resume (raccomandata).

### Se il refetch al resume o al reconnect fallisce (rete ancora assente), cosa succede in UI?

| Option | Description | Selected |
|--------|-------------|----------|
| Ultimo stato noto, retry silenzioso | Nessuno stato di errore in sessione | |
| Schermata errore come al primo caricamento | KGError con RefreshIndicator | |

**User's choice:** Altro — "retry silenzioso, se non ci si riesce a ricollegare allora schermata di errore e riporti l'utente alla login".

### Un errore sullo stream della subscription a sessione già caricata?

| Option | Description | Selected |
|--------|-------------|----------|
| Log e ultimo stato noto, mai CharacterError | Evento scartato, Loaded resta | |
| Emettere stato errore come oggi | CharacterError da cablare in UI | |

**User's choice:** Altro — "Come tutti gli altri errori: se la retry fallisce allora si mostra schermata/popup di errore e si riporta alla login".

### Senza indicatori in UI, come verifichiamo a mano riconnessione e refetch durante il QA?

| Option | Description | Selected |
|--------|-------------|----------|
| Solo log in debug | Righe kDebugMode | |
| Badge overlay solo in debug build | Pallino di stato WS in debug | |
| Niente di dedicato | Test automatici e log del BE | ✓ |

**User's choice:** Niente di dedicato.

### Dopo quanto tempo di tentativi falliti dichiariamo persa la sincronizzazione? (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| Circa 3 minuti | Copre cambi rete e pause brevi | ✓ |
| Circa 1 minuto | Resa rapida | |
| Circa 5 minuti | Molto tollerante | |

**User's choice:** Circa 3 minuti (raccomandata).

### Come si presenta il "ritorno alla login" quando la soglia scade? (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| Sign-in con sessione cancellata e avviso | Teardown come handleRevocation, notice "Connessione persa, accedi di nuovo" | ✓ |
| Schermata di errore con Riprova ed Esci | KGError-style, sessione conservata finché l'utente sceglie | |
| Sign-in ma sessione conservata | SignIn con notice, refresh token conservato | |

**User's choice:** Sign-in con sessione cancellata e avviso (raccomandata).
**Notes:** Deviazione deliberata dalla D-09 di Phase 11, limitata al watchdog di sync.

---

## Dove emergono twitchPoints e role live

### Mostriamo twitchPoints (e role) in qualche schermata già in questa fase?

| Option | Description | Selected |
|--------|-------------|----------|
| Solo fondazione, nessuna UI nuova | User live in AuthAuthenticated + test; UI nelle Phase 6/10 | ✓ |
| Riga immersiva nel tab Profilo | Riga pergamena con i punti canale | |
| Decidi tu | Discrezione di Claude | |

**User's choice:** Solo fondazione, nessuna UI nuova (raccomandata).

### Lo user stream arriva con la BE Phase 3: come chiudiamo la FE Phase 3 rispetto alla verifica contro il BE reale?

| Option | Description | Selected |
|--------|-------------|----------|
| Fase aperta fino al BE, E2E prima della PR | Come Phase 2 (D-33): schema check + E2E, PR FE dopo PR BE | ✓ |
| PR FE subito, UAT pendente | Come Phase 11 (D-28): item UAT pendente | |

**User's choice:** Fase aperta fino al BE, E2E prima della PR (raccomandata).

---

## Claude's Discretion

- Componente proprietario della subscription `userUpdated` e sua collocazione.
- Osservazione dello stato socket e del lifecycle dell'app.
- Refetch via query anche al reconnect (oltre allo snapshot).
- Meccanismo di chiave del sotto-albero gameplay per characterId.
- Forma del watchdog dei 3 minuti e punto d'ingresso del teardown.
- Strategia dei fake per `userUpdated` finché il BE non pubblica.
- Ottimizzazioni di rebuild (BlocSelector/buildWhen).

## Deferred Ideas

- Phase 9: hold del routing verso la creazione finché il Combat Result Sheet non è chiuso.
- Phase 4: cancellazione esplicita dalle Impostazioni → creazione via `userUpdated`.
- REQUIREMENTS SYNC-05: rimuovere "admin-swap".
- Riga twitchPoints nel Profilo (rinviata).
- Badge debug di connessione (rifiutato).
- Replay/resume token lato BE (non necessario con lo snapshot).
