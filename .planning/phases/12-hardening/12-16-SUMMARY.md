---
phase: 12-hardening
plan: 16
subsystem: auth/session gate
tags: [hardening, gate, be-phase-17, session, 4409, validation]
requires: ["12-15"]
provides:
  - "session contract names proven on the merged BE Phase 17 (BE develop 8bfd1b3): no FE alignment needed"
  - "schema check 45/45 OK against BE origin/develop src/schema.gql"
  - "every automated gate of the phase green; 12-VALIDATION.md approved (12-17 device rows pending)"
affects: [12-17]
tech-stack:
  added: []
  patterns:
    - "Gate computed on the tree, never pinned to a commit hash"
key-files:
  created:
    - .planning/phases/12-hardening/12-16-SUMMARY.md
  modified:
    - .planning/phases/12-hardening/12-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "Names confirmed: no test(...)/fix(...) alignment commit; the FE reads an empty or unknown reason as neutral, which matches the BE handoff (reason '' on the 4409 close of a reasonless revocation, no reason on legacy refusals)"
metrics:
  duration: "~15 min"
  completed: 2026-11-09
---

# Phase 12 Plan 16: Gate against the merged BE Phase 17 Summary

The FE session contract (`newLogin`/`roleChanged` reasons on `SESSION_REVOKED` `extensions.reason`, WS close `4409`) matches the merged BE Phase 17 byte for byte; schema check 45/45, full suite 3704 green, analyzer 47 info / 0 / 0, fresh release APK passes the bundle guard; `12-VALIDATION.md` approved.

## Commits

- `747d421` docs(phase-12): validate the hardening gates
- (this SUMMARY + bookkeeping) docs(phase-12): record plan 16 progress

No code commit: Task 1 found no differing name.

## Task 1 — BE gate and contract proof

- Gate: `git -C <BE> show origin/develop:src/auth/session/session-revoke-reason.enum.ts | grep -c newLogin` → `1`
- BE ref (`git log --oneline -3 origin/develop`): `8bfd1b3 Merge pull request #27 from LucaTabbia/feat/17-autorizzazione-e-sessioni`, `2c26e17 docs(state): record the phase 17 PR number`, `236b159 docs(phase-17): complete phase execution`
- Enum values: `newLogin = 'newLogin'`, `roleChanged = 'roleChanged'`, `reuseDetected = 'reuseDetected'`, `userLogout = 'userLogout'`
- Close code (`src/auth/ws/ws-close-codes.ts`): `5:export const WS_SESSION_REVOKED_CLOSE_CODE = 4409;`
- `reason` lines of `src/auth/auth.exception.ts`: `7: reason?: SessionRevokeReason;`, `17: reason: SessionRevokeReason | null = null,`, `22: this.extensions = reason ? { code, reason } : { code };`, `40: reason: SessionRevokeReason | null = null,` (in `static sessionRevoked(...)` → `AuthErrorCode.SESSION_REVOKED`), `45: reason,`. `sessionExpired()` passes no reason.
- HARDEN-02 matrix spec exists: `test/authz/authorization-matrix.int-spec.ts` (header «evidenza di HARDEN-02 (FE Phase 12)»). Handoff §2: «`test/authz/authorization-matrix.int-spec.ts` gira sul boot reale di `AppModule` … 89 casi» (FORBIDDEN / UNAUTHENTICATED / close `4403` / positive controls).
- Handoff `<BE>/.planning/phases/17-autorizzazione-e-sessioni/BACKEND-NOTES.md` section titles: 0. TL;DR per il FE; 1. Contratto (1.1 Motivo della revoca, 1.2 Close code WS, 1.3 Rifiuto del refresh, 1.4 Quando il BE chiude con `4409` e quando no, 1.5 Finestra HTTP del JWT (D-04)); 2. Comportamenti provati (Evidenza HARDEN-02); 3. Note per le UAT della FE Phase 12 (3.1 UAT dual-device, 3.2 UAT della release via tunnel TLS); 4. Deploy; 5. Domande aperte e deviazioni («Nessuna domanda aperta per la FE»).
- §3 UAT prerequisites (names only): phone + emulator with the SAME real Twitch account; ONE BE process only (the socket registry is per process — the extra «sweep» BE must be off); dev bypass has no sessions and does not take part; if the dev token stays active, `DEV_AUTH_TWITCH_ID` must be distinct from the real user's twitchId (else `DEV_AUTH_ROLE` ≠ DB role revokes the real sessions with `roleChanged`); `roleChanged` proof = `updateOne` `$set` on `role` only, then restore (second revocation, log in again); tunnel (cloudflared or ngrok) with no BE change, `TWITCH_REDIRECT_URI` = tunnel host + `/auth/twitch/callback` in the user's `.env` and registered byte for byte in the Twitch console, `APP_AUTH_REDIRECT_URL` unchanged, `wss://` over the tunnel to verify at the first step, throttler sees one IP (fine for two devices).
- FE names compared: `sessionRevokedReasonNewLogin = 'newLogin'`, `sessionRevokedReasonRoleChanged = 'roleChanged'` (auth_api_exception.dart), `const int wsSessionRevokedCloseCode = 4409;` (ws_reconnect_policy.dart), reason read from `extensions['reason']` of the `SESSION_REVOKED` error only → **names confirmed**.
- Acceptance greps: `4409` in ws_reconnect_policy.dart ≥ 1; `'newLogin'` = 1; `'roleChanged'` = 1.
- Schema check: `dumped 45 documents`; `validate_documents.js` exit 0, 45 OK, `grep -vc OK` = `0`.
- `flutter test test/repository/services test/screens/auth test/screens/signIn` → `+703: All tests passed!`

## Task 2 — Full gates

- `bash tool/hardening_check.sh` → `hardening_check: OK`, `guard=0`
- Full `flutter test -r expanded` → `01:23 +3704: All tests passed!`
- `flutter analyze --no-fatal-infos` → `analyze=0`; `flutter analyze` → `47 issues found.` + `ANALYZE_GATE_OK` (0 error, 0 warning)
- `flutter build apk --release --dart-define-from-file=env/prod.json` → `build=0`, `✓ Built build/app/outputs/flutter-apk/app-prod-release.apk (118.7MB)`, the key.properties WARNING printed once (debug keys, expected locally)
- `bash tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk` → `hardening_check: OK`, `bundle=0`
- Format: 26 Dart files added on the branch under lib/test/tool, no `UNFORMATTED` line
- Trailers on `develop..HEAD`: `0`
- Sanity greps (all eight printed nothing): `cityClass`; dev markers in the four production entry files; `flutter_dotenv` in env_config.dart; direct log calls outside app_log.dart; `Future.delayed` in the five harness tests; `test/flutter_test_config.dart`; `git diff develop --stat -- lib/graphql tool/schema_check` (empty: no document changed, registry 45); `DEV_AUTH_` in env/*.json.
- VALIDATION: rows 12-01-01 … 12-16-02 `✅ green` (37), 12-17-* pending (3), Wave 0 all ticked, `wave_0_complete: true`, `nyquist_compliant: true`, `status: approved`, sign-off ticked, gate line added.

## Deviations from Plan

**1. [Rule 3 - Blocking] Sign-off checklist line reworded so the frontmatter grep counts 1**
- **Found during:** Task 2
- **Issue:** the template checklist line «`nyquist_compliant: true` set in frontmatter» made `grep -c "nyquist_compliant: true"` print 2 (gate wants 1).
- **Fix:** reworded to «`nyquist_compliant` set to true in frontmatter» (the literal stays only in the frontmatter).
- **Commit:** 747d421

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: .planning/phases/12-hardening/12-16-SUMMARY.md
- FOUND: 747d421
