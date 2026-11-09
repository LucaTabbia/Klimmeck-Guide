# Phase 12 (FE) — Backend notes

Frontend companion of the BE Phase 17 (autorizzazione e sessioni). Branch `refactor/12-hardening`; contract proved on BE `origin/develop` `8bfd1b3` (merge of BE PR #27) by the gate plan 12-16 and on two Android devices by plan 12-17 (`12-HUMAN-UAT.md`). English text, user quotes verbatim in Italian. No ids of real users or characters, no tokens, no URIs, no tunnel host, no environment values in this file.

## 1. Contract consumed by the FE

- **`SESSION_REVOKED` + `extensions.reason`** on the refused refresh: `newLogin` → «Hai effettuato l'accesso da un altro dispositivo.»; `roleChanged` → «Il tuo ruolo è cambiato, accedi di nuovo.»; any other or missing reason (`reuseDetected`, `userLogout`, `null`) → the neutral «La sessione è scaduta, accedi di nuovo.». The reason is read only when `code == SESSION_REVOKED` (`SessionRejected(code, {reason})`, lenient: a non-string or empty reason is `null`); `SESSION_EXPIRED` never carries one.
- **WS close `4409`** (`wsSessionRevokedCloseCode`) handled like `4401`: refresh before reconnect (single flight, bounded); the refused refresh carries the reason, so the close reason itself is ignored. `4401` / `4403` unchanged.
- **Stateless JWT window** (900 s) accepted: the replaced device may keep serving HTTP calls with its residual access token until the next refresh or WS reconnect; the FE never infers a revocation from a 401 and never compares sessions or computes a role.
- **`BAD_USER_INPUT`** is now also read from GraphQL answers with HTTP status ≥ 300 (`ServerException.parsedResponse.errors`) and mapped to a dedicated `badUserInput` value in all eleven failure classifiers (generic copy «Qualcosa è andato storto, riprova»; never retried; push device registration non-retryable).
- **`IMAGE_REJECTED` (422) / `IMAGE_MODERATION_UNAVAILABLE` (503)** read from the REST body `code` of `POST /cloudinary/uploadImage`: «Immagine non ammessa, scegline un'altra.» (portrait cleared, draft kept) / «Controllo dell'immagine non disponibile: riprova o procedi senza immagine.» (everything kept).
- **`City.size`** drives the marker zoom visibility (`capital` always, `city` from 2.5, `village` from 3.2, `null` → hidden); the FE `CityType.cityClass` map is gone. UAT amendment (D-13c): the per-type FE flag `CityType.alwaysVisible` (true only for `talmvereVillage`) keeps Talmvere visible at every zoom whatever its size.
- No GraphQL document changed for the session contract; registry 45/45 OK against `8bfd1b3` (plan 12-16).

## 2. FE behaviours proved

- Logout end to end over a real loopback socket (`test/repository/services/auth/logout_flow_test.dart`): push unregister → backend logout → socket close sent → store cleared → signed out; the old `GraphQLClient` freed after a forced GC with a live subscription open.
- Single flight through both links (`concurrent_unauthorized_refresh_test.dart`): two concurrent 401 → one rotation.
- Leak test over the authenticated shell → logout (`test/screens/auth/authenticated_shell_leak_test.dart`, `LeakTrackingBlocObserver`) and identity transitions (`identity_transitions_test.dart`: account switch, character removed / recreated → whole shell rebuilt).
- Dual-session in-process harness (`dual_session_revocation_test.dart`) with the five cases on fakes: live socket closed `4409 newLogin`, revoked session at `connection_init`, refused refresh with reason, `roleChanged`, symmetry.
- **HARDEN-02 evidence:** the BE matrix `test/authz/authorization-matrix.int-spec.ts` (89 cases on the real `AppModule` boot; path from the BE handoff §2 «Evidenza HARDEN-02») on BE `origin/develop` `8bfd1b3`. The FE adds no test for it.

## 3. UAT outcome (FE Phase 12, 2026-11-09)

BE `develop` `8bfd1b3`, ONE BE process, Samsung over USB + Android emulator (API 36.1), the same real Twitch account; user verdict «approved» (2026-11-10).

1. **Real login through the TLS tunnel (signed release):** the BE redirected to Twitch with the tunnel callback; login, round trip and logout worked; `wss://` through the tunnel worked. At DB the three previously active sessions were revoked `newLogin` at the real login and the new session `userLogout` at Settings → Esci — exactly as the handoff described.
2. **Dual-device revocation (steps 6–7):** each new login revoked the other device's session `newLogin` at the same second the new session was created; the replaced device logged the socket close and teardown within the same second (`4409` + reason within milliseconds) and showed «Hai effettuato l'accesso da un altro dispositivo.»; user: «pass», «samsung dentro».
3. **Role change (step 10):** an `updateOne` setting only `role` → the watcher revoked the session with `roleChanged` 6 ms later; the device showed «Il tuo ruolo è cambiato, accedi di nuovo.»; role restored before any re-login.
4. **Archive while logged in (step 8):** the real `deleteCharacter` mutation → the logged-in device reached the creation page within 6 s without a restart; the new character got a fresh shell. The archived character was then restored by the orchestrator from a backup at the user's request (DB-side only).
5. **City sizes (DB-1, review C-IN-06):** `cities { type size }` served `city` for Ferrion and Necrorian and `village` for Talmvere. User: «Ad eccezione di Talmvere, il resto conta come capitale perché lo è».

## 4. Questions and notes for the BE

1. **BE PR #28** (quick task `261109-cap`, branch `fix/city-size-capitals`): Ferrion and Necrorian served as `capital` by `src/cities/city-size.ts`; open towards BE `develop`. The FE needs nothing more for them (`capital` → always visible); Talmvere stays `village`, kept visible FE-side by `CityType.alwaysVisible`. Note: `size` also drives the shop pool per size and the Phase 18 heal caps — confirm the change is intended there too.
2. **Throttler behind a tunnel:** both devices shared one IP (`THROTTLE_TRUST_PROXY` off); harmless with two devices — set it for a real deployment behind a proxy?
3. **Close reason `''`** when the revoke reason is null: confirm no other code path closes `4409` without a revoked session (the FE refreshes on any `4409`).
4. **HTTP status of a resolver-thrown `BAD_USER_INPUT`** (200 vs 400): the FE handles both now; which one does the BE intend?
5. **Production host:** `env/prod.json` holds `.invalid` placeholders until a production host exists — which host and URLs (https/wss)?
6. **Dev token identity and role** (BE Pitfall P6): in this UAT the dev-bypass identity is the user's real account and its `DEV_AUTH_ROLE` equals the role at DB, so no `roleChanged` happened; on shared accounts a different `DEV_AUTH_ROLE` would revoke the real sessions — worth a boot-time warning?
7. **Session observations (FE side, no BE action):** graphql_flutter 5.2.1 prints three socket-lifecycle lines in release (third-party, no credential); the splash warm-up downloads every lore image on a fresh install (~150 MB, minutes on a slow link) — the BE could consider smaller lore image variants; Twitch rejects old system Chrome builds on emulators («browser not supported»), fixed by clearing Chrome data.

Da riportare nella UAT della BE Phase 17 a cura del lato BE (questo repo non modifica il BE).
