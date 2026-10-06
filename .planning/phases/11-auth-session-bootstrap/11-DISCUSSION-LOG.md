# Phase 11: Auth & Session Bootstrap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-13
**Phase:** 11-auth-session-bootstrap
**Areas discussed:** Token lifecycle, Logout teardown, Bootstrap & Splash UX, Sign-in UX + account switch

---

## Token lifecycle (refresh + revoke + AuthTokenService)

### Q1: Forma di AuthTokenService

| Option | Description | Selected |
|--------|-------------|----------|
| Singleton via RepositoryProvider sopra BlocProvider tree | Coerente con KlimmeckGraphQl pattern. Stream<AuthState> + getAccessToken() async. | ✓ |
| Static service via GetIt/service locator | Accesso globale; rompe pattern provider esistente. | |
| ChangeNotifier + Provider | Reattivo nativo Flutter ma introduce secondo paradigma vs BLoC. | |

**User's choice:** Singleton via RepositoryProvider sopra BlocProvider tree (Recommended).

### Q2: Strategia refresh access token

| Option | Description | Selected |
|--------|-------------|----------|
| Reattivo on-401 con mutex single-flight | Dio interceptor + Completer condiviso + retry. | |
| Proattivo con timer su expires_in | Refresh schedulato N min prima della scadenza. | |
| Ibrido: proattivo + reattivo fallback | Timer + interceptor 401 di backup. | ✓ (derivato) |

**User's choice:** Free-text — "Il refresh non dev'essere mai bloccante per l'utente durante la sessione attiva. L'obiettivo è di non mostrare mai una schermata di loading."
**Notes:** Interpretato come strategia ibrida: proattivo (timer) per evitare 401 sulla critical path + reattivo (mutex single-flight) come fallback silenzioso. Salvato come regola persistente in `feedback_no_blocking_loading_in_session.md`.

### Q3: Detection revoca esterna Twitch

| Option | Description | Selected |
|--------|-------------|----------|
| Refresh fails with 400/401 + invalid_grant → revoke | Basato su contract Twitch. | ✓ (in-session) |
| Validate endpoint Twitch periodico (es. ogni cold start) | https://id.twitch.tv/oauth2/validate al boot. | ✓ (cold start) |

**User's choice:** Validate endpoint Twitch periodico (ogni cold start). In-session si applica anche il check on-refresh-failure.
**Notes:** Decisioni combinate in D-08 e D-09.

---

## Logout teardown contract

### Q1: Gestione fallimento revoke su Twitch (offline)

| Option | Description | Selected |
|--------|-------------|----------|
| Best-effort: timeout corto, procedi sempre con teardown locale | Timeout 3-5s, log warning, prosegui. | ✓ |
| Bloccante: errore + rimani loggato | Più sicuro ma rompe UX su rete instabile. | |
| Best-effort + retry queue persistente | Over-engineered per v1. | |

**User's choice:** Best-effort con timeout corto (Recommended).

### Q2: Conferma esplicita prima del logout

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, dialog di conferma sempre | Logout è azione distruttiva. | ✓ |
| No, tap immediato | Più veloce ma rischio tap accidentale. | |

**User's choice:** Dialog di conferma (Recommended).

### Q3: Reset GraphQL cache

| Option | Description | Selected |
|--------|-------------|----------|
| Ricrea l'intero GraphQLClient + WebSocketLink | Garantisce zero bleed-through e nessun listener orfano. | ✓ |
| store.reset() + chiudi subs manualmente | Più leggero ma più facile dimenticare un listener. | |

**User's choice:** Ricrea l'intero GraphQLClient + WebSocketLink (Recommended).

---

## Bootstrap & Splash UX

### Q1: Cold start con token salvato

| Option | Description | Selected |
|--------|-------------|----------|
| Splash nativo OS finché auth risolve | Sfrutta splash di sistema, zero widget Flutter di loading. | |
| Routing ottimistico (vai a main, fallback) | Più veloce percepito, flicker su revoca. | |
| Splash widget custom con logo | Più controllo visivo. | |
| Riusa Splash Screen esistente con auth call come prima azione | (free-text) | ✓ |

**User's choice:** Free-text — "Utilizziamo lo Splash Screen già presente e la chiamata viene effettuata per prima."
**Notes:** Confermata l'esistenza di `lib/screens/splash/splash_screen.dart` e `SplashCubit`.

### Q2: Refresh al cold start fallisce (timeout/rete)

| Option | Description | Selected |
|--------|-------------|----------|
| Timeout breve (3-5s) → sign-in | | |
| Resta su splash con retry automatico | | |
| Vai direttamente a main shell | | |
| Retry indefinito + dopo 10s messaggio + bottone manuale | (free-text) | ✓ |

**User's choice:** Free-text — *"Riproviamo all'infinito, ma dopo 10 secondi compare un messaggio simile a 'Connessione a Twitch instabile, attendere o' e inserire un pulsante che riporta alla pagina di signin/signup"*.

### Q3: Cold start senza token salvato

| Option | Description | Selected |
|--------|-------------|----------|
| Sign-in screen direttamente | | ✓ |
| Onboarding breve prima di sign-in | Aggiunge friction. | |

**User's choice:** Sign-in screen direttamente (Recommended).

---

## Sign-in UX + account switch

### Q1: Layout sign-in screen

| Option | Description | Selected |
|--------|-------------|----------|
| Logo + tagline + bottone "Login con Twitch" | Minimale, focused. | |
| Solo bottone a tutto schermo | Estremamente minimale. | |
| Logo + tagline + bottone Twitch + link TOS/Privacy in footer | Più conforme a store guidelines. | ✓ |

**User's choice:** Logo + tagline + bottone Twitch + link TOS/Privacy in footer.

### Q2: AUTH-05 account switch — force_verify policy

| Option | Description | Selected |
|--------|-------------|----------|
| force_verify=true sempre nell'auth URL | Garantisce account swap pulito; +1 click su primo login. | ✓ |
| force_verify solo dopo logout esplicito | Logica condizionale, UX più fluida nel caso comune. | |
| Mai force_verify | Rischio re-login silenzioso stesso account dopo logout. | |

**User's choice:** force_verify=true sempre (Recommended).

### Q3: Cancellazione utente nel browser OAuth

| Option | Description | Selected |
|--------|-------------|----------|
| Torna a sign-in screen senza errore visibile | Cancellazione legittima, catch silenzioso. | ✓ |
| Mostra messaggio "Login annullato" (snackbar) | Conferma esplicita ma forse ridondante. | |

**User's choice:** Torna a sign-in screen senza errore visibile (Recommended).

---

## Claude's Discretion

- Dialog widget per logout confirmation (riuso widget esistente in lib/shared/ se presente).
- TOS/Privacy URLs (placeholder per v1).
- Twitch button styling (coerente con brand Twitch + theme app).
- Mutex primitive (Completer vs `synchronized` package; preferire Completer se sufficiente).
- WebSocket reauth dopo refresh: hot-update initialPayload vs ricreare WebSocketLink.
- Storage keys naming + eventuale wrapper SecureStorage per testabilità.

## Deferred Ideas

- Onboarding pre-sign-in.
- Retry queue persistente per revoke offline.
- Multi-device / multi-session policies (Phase 11).
- Biometric gate.
- Refresh-on-resume da AppLifecycleState.

---

# Amendment — 2026-10-06 (auto mode)

> Sessione di aggiornamento del contesto, senza domande interattive. Unico input diretto dell'utente: la direttiva sul bypass riportata sotto.

**Direttiva utente (testuale):** "Per quanto riguarda cosa come la login su Twitch (di cui non abbiamo ancora le chiavi) per adesso inizia l'implementazione, ma permetti di bypassare il tutto finché non si ha tutto il necessario."

## Perché il contesto è cambiato

| Fatto | Fonte | Effetto |
|-------|-------|---------|
| Twitch non supporta PKCE; l'authorization code grant richiede `client_secret` | `dev.twitch.tv/docs/authentication/getting-tokens-oauth/`, verificato 2026-10-06 | D-15 ("PKCE locked") non è realizzabile dall'app |
| Il BE ha scelto un JWT di sessione proprio | `Klimmeck-Guide-BE/.planning/PROJECT.md` Key Decisions, BE Phase 2 CONTEXT | L'app non parla più con Twitch: refresh, validate e revoke passano dal BE |
| Le chiavi Twitch non esistono ancora | Utente | Serve un bypass di prima classe |

## Flusso di login

| Option | Description | Selected |
|--------|-------------|----------|
| Login mediato dal BE + ticket monouso legato a challenge S256 generato dall'app | Il BE custodisce il secret; l'app apre `{BASE_URL}auth/twitch/start` nel browser di sistema e riscatta il ticket. | ✓ |
| Implicit grant dall'app + invio del token Twitch al BE | Nessun secret, ma dipende da un redirect custom-scheme che Twitch con ogni probabilità non accetta. | |
| PKCE dall'app (plan di aprile) | Non praticabile. | |

**User's choice:** [auto] Login mediato dal BE (recommended default, allineato a BE Phase 2 D-01..D-03).

## Bypass dev

| Option | Description | Selected |
|--------|-------------|----------|
| Mantenere `DevAuthTokenService` selezionato da `DEV_AUTH_ENABLED=true`; lo stub simula login/logout | Cold start diretto nel main shell; dopo un logout il pulsante di login rientra con l'identità dev. La UI di auth resta testabile senza chiavi. | ✓ |
| Pulsante "salta login" dedicato nella sign-in screen | Seconda via d'ingresso da mantenere e da rimuovere; lo stub esiste già. | |
| Rimuovere lo stub come previsto ad aprile | L'app diventerebbe inutilizzabile finché non arrivano le chiavi. | |

**User's choice:** [auto] Mantenere lo stub e fargli simulare le transizioni (recommended default).

## Verifica end-to-end

| Option | Description | Selected |
|--------|-------------|----------|
| Test automatici con fake ora; login reale su device come UAT pendente | Non bloccare la fase su qualcosa di non verificabile senza chiavi. | ✓ |
| Checkpoint umano bloccante (plan 05 di aprile) | La fase resterebbe aperta a tempo indeterminato. | |

**User's choice:** [auto] UAT pendente (recommended default).

## Decisioni emendate

D-05, D-07, D-08, D-09, D-12, D-13, D-15, D-16, D-18 (solo wording), D-21. Nuove: D-23..D-28. Requisiti emendati in `REQUIREMENTS.md`: AUTH-01, AUTH-02, AUTH-04, AUTH-07, DEV-AUTH-04.
