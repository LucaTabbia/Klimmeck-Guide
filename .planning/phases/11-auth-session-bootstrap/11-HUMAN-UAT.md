---
status: partial
phase: 11-auth-session-bootstrap
source: [11-VERIFICATION.md]
started: 2026-10-06T00:00:00Z
updated: 2026-10-06T00:00:00Z
---

## Current Test

[awaiting human testing]

> Quasi tutti i punti dipendono dalle chiavi Twitch, che non sono ancora disponibili (11-CONTEXT.md D-28).
> Checklist operativa dettagliata: `BACKEND-NOTES.md` §7 di questa fase e `BACKEND-NOTES.md` §8 della Phase 2 del backend.

## Tests

### 1. Login Twitch reale su device fisico (Android e iOS)

expected: Con il backend configurato con le chiavi Twitch e `DEV_AUTH_ENABLED=false` su entrambi i lati, "Login con Twitch" apre il browser di sistema, dopo il consenso il deep link `klimmeck://auth` riporta nell'app e l'utente entra nel main shell con il proprio utente reale (da `me`).
why_pending: Richiede le chiavi Twitch e un device fisico.
result: [pending]

### 2. Annullamento e consenso negato

expected: Chiudendo il browser di sistema, oppure negando il consenso su Twitch (`access_denied`), la schermata di sign-in resta invariata: nessun banner, nessuno snackbar, pulsante di nuovo utilizzabile.
why_pending: Richiede le chiavi Twitch.
result: [pending]

### 3. Cambio account

expected: Dopo logout e nuovo login, Twitch chiede di nuovo la verifica (`force_verify`) e si può entrare con un account diverso senza residui del precedente. Se il browser di sistema riusa in silenzio l'account precedente, passare `preferEphemeral: true` al wrapper del browser.
why_pending: Richiede le chiavi Twitch e due account.
result: [pending]

### 4. Ripresa della sessione e refresh invisibile

expected: Dopo kill e riavvio dell'app la sessione riprende senza chiedere credenziali. Lasciando l'app aperta oltre 15 minuti con una subscription attiva, il socket viene chiuso dal backend (4401) e riaperto in silenzio con il token nuovo: nessuno spinner, nessun banner.
why_pending: Richiede una sessione reale contro il backend.
result: [pending]

### 5. Revoca lato server

expected: Revocando la sessione sul backend, alla successiva scadenza del token l'app torna al sign-in con l'avviso inline "La sessione è scaduta, accedi di nuovo.".
why_pending: Richiede una sessione reale contro il backend.
result: [pending]

### 6. Reinstallazione e ripristino backup

expected: Dopo una reinstallazione su iOS (Keychain che sopravvive) l'app parte dal sign-in, non con una sessione fantasma. Dopo un ripristino di backup su Android l'app non va in crash e parte dal sign-in.
why_pending: Richiede device fisici.
result: [pending]

### 7. Conformità visiva alla UI-SPEC

expected: SignInScreen, Splash (incluso l'avviso dopo 10 secondi con "Accedi manualmente") e dialog di conferma logout corrispondono a `11-UI-SPEC.md` su schermo reale in landscape.
why_pending: Verifica visiva. Il dialog di logout sarà raggiungibile dalla UI solo con la schermata Settings (Phase 4).
result: [pending]

### 8. Backend senza chiavi Twitch e backend di sviluppo in `http://`

expected: Con `DEV_AUTH_ENABLED=false` sull'app e backend senza chiavi Twitch, "Login con Twitch" mostra l'errore inline "Login con Twitch non ancora disponibile.". Con un backend di sviluppo in `http://` (rete locale, oppure emulatore Android con `adb reverse`) il browser di sistema apre regolarmente l'URL di start.
why_pending: Verificabile già oggi a mano, ma non automatizzabile (browser di sistema).
result: [pending]

## Summary

total: 8
passed: 0
issues: 0
pending: 8
skipped: 0
blocked: 0

## Gaps
