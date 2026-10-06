# BACKEND-NOTES — Phase 11 Auth & Session Bootstrap (handoff per l'agent BE)

- **Fase FE:** 11-auth-session-bootstrap (AUTH-01..07)
- **Data:** 2026-10-06
- **Branch:** `feat/11-auth-session-bootstrap`
- **Fonte di verità del contratto:** `Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md` e `src/schema.gql`. Questo documento non lo duplica: descrive come l'app FE lo consuma. Confronto operazione per operazione eseguito in 11-11: nessuna divergenza.

## 1. Contesto

L'app è un client di sessione first-party. Non possiede alcuna chiave né token Twitch e non contatta mai `id.twitch.tv` (nessun `TWITCH_CLIENT_ID` / `client_secret` nel repo FE). Tutto passa dal BE: `GET auth/twitch/start`, deep link `klimmeck://auth`, `exchangeLoginTicket`, poi sessione `accessToken` (JWT 15 min) + `refreshToken` rotante.

## 2. Operazioni consumate dall'app

| Operazione | Trasporto | Auth | Quando la chiama l'app | Gestione errori |
|---|---|---|---|---|
| `GET {BASE_URL}auth/twitch/start?challenge=<S256>` | browser di sistema (`flutter_web_auth_2`, callback scheme `klimmeck`) | nessuna | tap su "Login con Twitch" (nuova coppia verifier/challenge a ogni tentativo) | `error=access_denied` o chiusura del browser = silenzioso; `twitch_not_configured` = "Login con Twitch non ancora disponibile."; ogni altro `error` / callback malformato = errore generico, riprovare. Il redirect del BE deve usare esattamente `klimmeck://auth?…`: l'app scarta ogni altro host (`klimmeck://altro?…` = errore generico) e su Android la `CallbackActivity` accetta solo scheme `klimmeck` + host `auth` |
| `ExchangeLoginTicket($ticket, $codeVerifier)` | GraphQL HTTP, client dedicato | nessun bearer | subito dopo il deep link `klimmeck://auth?ticket=` | `LOGIN_TICKET_INVALID` = errore generico in UI (si riparte con nuova coppia); rete/5xx = errore di connessione con retry manuale |
| `RefreshSession($refreshToken)` | GraphQL HTTP, client dedicato | nessun bearer (il refresh token e' l'argomento) | cold start (a ogni avvio con sessione salvata), proattivo, reattivo (vedi §3) | solo `SESSION_EXPIRED` / `SESSION_REVOKED` terminali; tutto il resto transitorio |
| `Logout` | GraphQL HTTP | bearer della sessione che esce; se scaduto, prima un `refreshSession` col suo refresh token (D-36), fuori dal single-flight | azione esplicita di logout (entry point UI: Phase 4, Settings) | timeout 4 s, best-effort: offline o in errore la sessione locale viene comunque chiusa e quella server muore per scadenza. `SESSION_EXPIRED`/`SESSION_REVOKED` su quel refresh = chiamata saltata, esito locale sempre "uscito" (mai "sessione scaduta"). Se il refresh finisce dopo il timeout la chiamata `logout` viene saltata: l'app non invia mai il bearer di una sessione nata dopo |
| `GetMe` | GraphQL HTTP | bearer | solo stub dev, per allineare l'utente dev | timeout 3 s, fallback ai valori `.env` |
| REST Cloudinary (`/cloudinary/*`) | dio | bearer | come prima di Phase 11 | su HTTP 401 un solo refresh single-flight e un retry |

Documenti GraphQL (`lib/graphql/`):

```graphql
fragment AuthSessionFields on AuthSession {
  accessToken
  accessTokenExpiresAt
  refreshToken
  user { id twitchId twitchPoints role currentCharacter { id } }
}
mutation ExchangeLoginTicket($ticket: String!, $codeVerifier: String!) { exchangeLoginTicket(ticket: $ticket, codeVerifier: $codeVerifier) { ...AuthSessionFields } }
mutation RefreshSession($refreshToken: String!) { refreshSession(refreshToken: $refreshToken) { ...AuthSessionFields } }
mutation Logout { logout }
query GetMe { me { id twitchId twitchPoints role currentCharacter { id } } }
```

L'app usa `accessTokenExpiresAt` (ISO 8601 UTC) per pianificare il refresh: non decodifica mai il JWT. `currentCharacter == null` e' il segnale che FE Phase 2 usera' per il routing verso la creazione personaggio.

## 3. Flusso di login e refresh come implementati

1. Genera `code_verifier` (32 byte random, base64url senza padding, 43 char) e `challenge = base64url(sha256(verifier))` (43 char).
2. Apre `auth/twitch/start?challenge=` (URL relativo a `BASE_URL`) nel browser di sistema; attende `klimmeck://auth?ticket=...|error=...`.
3. Riscatta il ticket con `exchangeLoginTicket`; persiste il refresh token in storage cifrato, tiene l'access token in memoria; emette lo stato autenticato.

Refresh:
- **Single-flight:** un solo `refreshSession` in volo; chiamanti concorrenti attendono lo stesso esito. Il nuovo refresh token e' persistito prima di scartare il vecchio.
- **Proattivo:** a `(exp - iat) - 60 s` dall'emissione, con floor 30 s; robusto a clock skew.
- **Reattivo, retry una sola volta:** su `UNAUTHENTICATED` (GraphQL) o HTTP 401 (REST) dopo aver rifiutato il token inviato; su WS 4401/4403 (vedi §4).
- **Terminale:** solo `SESSION_EXPIRED` e `SESSION_REVOKED` sul refresh -> storage svuotato, teardown dei client, sign-in con "La sessione e' scaduta, accedi di nuovo."
- **Transitorio (mai wipe ne' logout):** `UNAUTHENTICATED`, `BAD_REQUEST`, HTTP 401, 5xx, rete, timeout, codici sconosciuti -> retry con backoff (cold start cap 30 s, proattivo cap 60 s). Al cold start l'utente vede "Accedi manualmente" dopo 10 s.
- **Storage cifrato illeggibile al cold start** (es. iOS prima del primo sblocco, avvio in background): nessuna sessione per quell'avvio, sign-in, ma il refresh token NON viene cancellato; l'avvio successivo lo riprova. Il BE può quindi ricevere un `refreshSession` con un token rimasto inutilizzato a lungo (risposta attesa: sessione valida o `SESSION_EXPIRED`).

## 4. WebSocket

- `connection_init` con `{ "Authorization": "Bearer <token corrente>" }`, letto a ogni connect (mai catturato una volta).
- Su close **4401** (`Token expired`) e **4403** (`Forbidden`): refresh forzato single-flight, poi riconnessione dopo 500 ms (solo al primo tentativo dopo una connessione stabile >= 30 s).
- Altri close code e tentativi ripetuti: backoff esponenziale 1 -> 60 s, azzerato dopo una connessione stabile. Nessun hot loop con token morto.
- Il link WS non viene ricreato dopo un refresh (le subscription vive si preservano); viene disposto e ricreato solo al logout.
- **Nota Phase 3 (Real-Time Sync):** gli eventi pubblicati mentre il socket e' chiuso (gap di riconnessione ogni ~15 min alla scadenza del JWT) non vengono ripetuti dal BE. Serve refetch-on-reconnect lato app (Phase 3); non e' implementato in Phase 11.

## 5. Bypass dev (lato app)

Variabili `.env` FE lette dallo stub:

| Variabile | Uso |
|---|---|
| `DEV_AUTH_ENABLED` | attiva lo stub; con `false` l'app usa il servizio di sessione reale |
| `DEV_AUTH_ACCESS_TOKEN` | bearer inviato; deve coincidere byte per byte col BE (min 16 caratteri, senza spazi) |
| `DEV_AUTH_TWITCH_ID` | fallback per l'utente dev; il valore effettivo e' del BE, letto via `me` |
| `DEV_AUTH_ROLE` | fallback per il ruolo; effettivo = BE via `me` (cambiare il ruolo richiede riavvio del BE) |
| `DEV_AUTH_USER_ID` | solo fallback offline: il BE lo ignora, l'id reale arriva da `me` |
| `DEV_AUTH_START_SIGNED_OUT` | solo FE: l'app parte sul sign-in e "Login con Twitch" entra con l'identita' dev senza browser |

Comportamento: cold start autenticato; `logout` -> sign-in; "Login con Twitch" rientra subito. Lo stub chiama `GetMe` per riallinearsi (timeout 3 s, fallback `.env`). Non c'e' guardia `kReleaseMode` (D-30): il confine di sicurezza e' il BE fail-closed in produzione. Rimozione prevista in Phase 12.

## 6. Domande aperte per il BE

Risposte dal BACKEND-NOTES BE Phase 2 (chiuse):
- Refresh token malformato/sconosciuto -> `SESSION_EXPIRED` (non `BAD_REQUEST`/`UNAUTHENTICATED`): **confermato** (§2 BE). L'app e' allineata.
- `logout` con solo refresh token: **non supportato**, serve access token valido (§2 BE). L'app rinnova prima con un `refreshSession` dedicato al logout. Nota per la reuse detection: se in quel momento un refresh proattivo/reattivo è già in volo, il refresh del logout riusa lo stesso refresh token entro pochi secondi (dentro la finestra di grazia di 30 s); il token ruotato non viene persistito perché lo storage viene svuotato subito dopo.
- Contratto `connection_init` / close code: **chiuso** (§4 BE).
- Nomi e tipi delle operazioni, `preferEphemeral`, comportamento post-refresh: **chiusi** (§1, §2, §6 BE).

Ancora aperte / richieste:
1. **Phase 3:** strategia per gli eventi persi durante la riconnessione WS (refetch lato app e/o resume/snapshot lato BE).
2. **HTTP 200 + `extensions.code`:** confermare con un test d'integrazione BE che gli errori auth GraphQL restino stabili (HTTP 200, `data: null`, `extensions.code`); l'app mappa anche HTTP 401 per sicurezza.
3. **Logout best-effort:** se l'access token e' scaduto e il refresh fallisce in modo transitorio, l'app chiude comunque la sessione locale e la sessione server resta viva fino a scadenza (30 gg sliding). Accettabile? Eventuale futuro endpoint di logout col solo refresh token.
4. **FE Phase 2:** `MainScreen.initState` usa un id personaggio hard-coded (`68c191de541d89c481b8322b`, pre-esistente): verra' sostituito da `me.currentCharacter`.
5. Stub FE noti: i pulsanti TOS e Privacy nel footer di SignInScreen hanno `onPressed` vuoto (URL non ancora definiti); l'entry point del logout e' Phase 4 (Settings).

## 7. Checklist UAT pendente (da eseguire quando arrivano le chiavi Twitch, D-28)

- [ ] Console Twitch: registrati gli OAuth Redirect URL del BE (staging https e `http://localhost:3000/auth/twitch/callback`). Device in LAN: tunnel https come `BASE_URL`. Emulatore Android: `adb reverse tcp:3000 tcp:3000` e `BASE_URL=http://localhost:3000/`.
- [ ] `DEV_AUTH_ENABLED=false` su BE e app; riavvio BE senza i warning `DEV AUTH BYPASS` e `Twitch OAuth not configured`.
- [ ] Login reale iOS (ASWebAuthenticationSession) e Android (Custom Tabs / AuthTab, intent `klimmeck://auth`) -> shell autenticata, utente reale da `me`.
- [ ] Annullamento (back / chiusura del browser) -> sign-in invariato, nessun messaggio.
- [ ] Consenso negato su Twitch (`error=access_denied`) -> silenzioso.
- [ ] BE senza chiavi -> "Login con Twitch non ancora disponibile."
- [ ] Kill e riavvio app -> sessione ripresa senza prompt.
- [ ] Attesa > 15 min con una subscription attiva -> chiusura 4401 e riconnessione silenziosa col token nuovo.
- [ ] Logout offline -> sign-in immediato.
- [ ] Cambio account con SSO Twitch (`force_verify=true`, `preferEphemeral=false`): se Twitch riusa l'account A, passare `preferEphemeral: true` in `FlutterWebAuth2BrowserAuthenticator`.
- [ ] Revoca server-side della sessione -> sign-in con "La sessione e' scaduta, accedi di nuovo."
- [ ] Verificare che `scope=` vuoto sia accettato da Twitch (Assumption A1 BE).
- [ ] Reinstall iOS -> nessuna sessione residua; restore backup Android -> nessun crash.
- [ ] Backend `http://` in dev: cleartext consentito solo in debug; verificare con `adb reverse` di cui sopra.
