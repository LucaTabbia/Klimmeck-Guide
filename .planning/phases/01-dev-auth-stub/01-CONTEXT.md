# Phase 1: Dev Auth Stub - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Fornire un `AuthTokenService` **stub** che espone lo stesso contratto pubblico del servizio finale (vedi Phase 11: Auth & Session Bootstrap) ma backed da un token e un utente di test hardcoded letti da `.env`. Obiettivo: sbloccare lo sviluppo e il test manuale di tutte le fasi gameplay (2–10) senza dipendere dal flusso OAuth Twitch reale, che viene rimandato a Phase 11 per ridurre l'attrito durante QA manuale.

Out of scope: OAuth PKCE, system browser flow, secure storage, refresh token rotation, refresh mutex, logout che revoca il token su Twitch, detection della revoca esterna, sign-in screen reale, account switching. Tutto questo vive in Phase 11 e la sostituisce end-to-end senza toccare i consumer.

In scope:
- `AuthTokenService` stub con **la stessa public surface** del target finale: `Stream<AuthState>`, `Future<String?> getAccessToken()`, `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()`.
- Valori letti da `.env`: `DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_REFRESH_TOKEN` (facoltativo, non usato), `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE` (uno di `guard | adventurer | innkeeper` per testare Admin Panel).
- Bootstrap: al cold start lo stub emette immediatamente `Authenticated` con il test user; niente splash prolungato.
- `login()` e `logout()` sono no-op (log di warning in debug builds solamente); non esiste sign-in screen in questa fase.
- Integrazione con `KlimmeckGraphQl` / `dio` interceptor: stessi punti di wiring del design originale (RepositoryProvider sopra il BlocProvider tree, interceptor che chiama `getAccessToken()`), così Phase 11 sostituisce solo l'implementazione.

</domain>

<decisions>
## Implementation Decisions

- **D-01:** Il contratto pubblico di `AuthTokenService` è quello definito nel context di Phase 11 (ora in `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md`, D-01..D-03). Phase 1 stub lo rispetta al 100%.
- **D-02:** La sostituzione Phase 1 → Phase 11 deve essere un cambio di **implementazione concreta** della classe `AuthTokenService`, non un cambio di interfaccia. Nessun consumer (GraphQL client, dio interceptor, AuthCubit downstream) deve essere toccato.
- **D-03:** Role switching via `.env`: il dev stub deve supportare `DEV_AUTH_ROLE` per abilitare il test della Phase 10 Admin Panel senza dover stubbare codice in più punti.
- **D-04:** Niente secure storage: il token "dev" è in `.env`, che è già fuori dal VCS (vedi regola invalicabile 5 in CLAUDE.md). `AuthTokenService` stub legge `.env` al cold start e tiene il token in memoria.
- **D-05:** Flag `DEV_AUTH_ENABLED`: Phase 1 stub si attiva solo quando `DEV_AUTH_ENABLED=true` in `.env`. In produzione (e quando Phase 11 atterrerà) il flag è `false` e il consumer riceve l'implementazione reale.

</decisions>

<requirements>
## Requirements

- **DEV-AUTH-01** — `AuthTokenService` stub espone la stessa interfaccia pubblica del servizio finale (vedi `11-CONTEXT.md`).
- **DEV-AUTH-02** — Lo stub legge identità e token da `.env` (`DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`).
- **DEV-AUTH-03** — Lo stub supporta role switching via `DEV_AUTH_ROLE` (`guard | adventurer | innkeeper`) per abilitare test di fasi role-gated.
- **DEV-AUTH-04** — `login()` e `logout()` sono no-op in questa fase (log di warning in debug only); nessun sign-in screen viene costruito.
- **DEV-AUTH-05** — `AuthTokenService` è esposto via `RepositoryProvider` sopra il `BlocProvider` tree, con la stessa collocazione prevista per l'implementazione finale.

</requirements>

<dependencies>
## Dependencies

- Nothing upstream (foundational per il resto della milestone).
- Downstream: tutte le Phase 2–10 consumano `AuthTokenService.getAccessToken()` indirettamente via GraphQL/dio.

</dependencies>

<replaces>
## Replacement by Phase 11

Quando Phase 11 (Auth & Session Bootstrap) atterra:
1. L'implementazione concreta di `AuthTokenService` viene sostituita con quella OAuth reale.
2. Il flag `DEV_AUTH_ENABLED` viene rimosso o forzato a `false` in tutti i build non-dev.
3. Un sign-in screen reale viene introdotto (già progettato in `11-UI-SPEC.md`).
4. Nessun consumer downstream deve cambiare: contratto invariante per costruzione.

</replaces>
