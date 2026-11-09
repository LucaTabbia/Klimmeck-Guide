# Phase 12: Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-09
**Phase:** 12-hardening (joint with the BE Phase 17 «Autorizzazione e sessioni», inserted during this discuss)
**Areas discussed:** Dev bypass, `.env` and release · Harnesses: memory, dual-device, CI · Multi-device policy · Bug-fix pass from the UATs · BE 17 companion

---

## Phase choice (before the discuss)

| Option | Description | Selected |
|--------|-------------|----------|
| Heal pair: BE 17 + FE 18 | New phases for the `canHeal` mechanics deferred by quick tasks 261109-inj/inj2 | |
| FE 12 Hardening | The only open FE phase («executes last»); the BE had no open phase | ✓ |
| Another pair | Free text | |

**User's choice:** FE 12 Hardening.

## Area selection

All four proposed areas selected: dev bypass / `.env` / release; harnesses (memory, dual-device, CI); multi-device policy; bug-fix pass from the UATs.

## Dev bypass, `.env` and release

| Option | Description | Selected |
|--------|-------------|----------|
| Entry point separato | `lib/main_dev.dart` composes the bypass; `lib/main.dart` production-pure; UAT with `flutter run -t lib/main_dev.dart` | ✓ |
| Guardia kReleaseMode | Bypass stays in `lib/`, compiled out in release; `.env` stays an asset | |
| Rimozione totale | No bypass at all; UATs only with real Twitch logins | |

| Option | Description | Selected |
|--------|-------------|----------|
| Niente .env in release | URLs via `--dart-define-from-file=env/<ambiente>.json`; `.env` only in the dev entry point; gate = bundle grep | ✓ |
| .env resta, ripulito | File stays an asset, `DEV_AUTH_*` forbidden in it by CI | |

| Option | Description | Selected |
|--------|-------------|----------|
| Tutto in scope | Keystore from `android/key.properties`, cleartext refused in release, logs off in release | ✓ |
| Solo wss e log | TLS and logs only; signing at publication time | |
| Niente di tutto ciò | Hardening = HARDEN-01..06 and criterion 6 only | |

## Harnesses: memory, dual-device, CI

| Option | Description | Selected |
|--------|-------------|----------|
| Test automatico + DevTools in UAT | Leak-tracking `testWidgets` shell → logout + DevTools snapshot step in the device UAT | ✓ |
| Solo test automatico | | |
| Solo DevTools manuale | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Telefono + emulatore Android | Same real Twitch account on the Samsung and an emulator; in-process two-session test for revocation cases | ✓ |
| Due telefoni fisici | | |
| Solo test in-process | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Completa con build release | GitHub Actions: analyze 0/0, test, guard greps, `flutter build apk --release` + bundle grep | ✓ |
| Minima: analyze, test, grep | | |
| Nessuna CI, script locale | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Quick task BE table-driven | One BE int-spec over the enumerated innkeeper handlers | |
| Mini-fase BE 17 | Full GSD phase in the BE: authorization matrix (handler × role, ownership included) + handoff | ✓ |
| Solo verifica, niente codice BE | | |

**Notes:** the user chose the full BE phase over the quick task; the phase then absorbed the multi-device rules below.

## Multi-device policy

| Option | Description | Selected |
|--------|-------------|----------|
| Entrambi validi | Independent sessions as today; the client only stays coherent | |
| L'ultimo login caccia l'altro | The BE revokes the other sessions at login; the old device returns to sign-in | ✓ |
| Un solo device con avviso | Same, with an explicit message (needs a reason from the BE) | |

| Option | Description | Selected |
|--------|-------------|----------|
| Solo quel device | Logout closes only the current session (as today) | ✓ |
| Esci da tutti i dispositivi (voce in più) | | |
| Il logout chiude tutto | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Reset totale della shell | Every gameplay cubit rebuilt when `User.id` or `currentCharacter.id` changes (already the design: keyed subtrees) | ✓ |
| Solo refetch | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Neutro come oggi | Phase 11 D-10 notice for every revocation | |
| Specifico quando il BE lo dice | `SESSION_REVOKED` + reason → dedicated notices (`newLogin`, `roleChanged`) | ✓ |

**Notes:** the two non-default picks («l'ultimo login caccia l'altro», specific message) became BE Phase 17 D-02..D-06 and FE D-09/D-12.

## Bug-fix pass from the UATs

| Option | Description | Selected |
|--------|-------------|----------|
| BAD_USER_INPUT nei classifier | Map the BE Phase 10 code in every existing classifier | ✓ |
| IMAGE_REJECTED / MODERATION_UNAVAILABLE | Dedicated messages in character creation | ✓ |
| CityType.cityClass → City.size | One source of truth for marker sizes | ✓ |
| Badge diagnostico connessione | Dev-only WS/sync indicator | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, review per aree + fix | Three parallel reviewers by area, ruling, fixer in TDD | ✓ |
| Solo i follow-up noti | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Tunnel TLS verso il BE locale | cloudflared/ngrok; release APK with dart-define file pointed at the tunnel; real Twitch login | ✓ |
| Profile build con cleartext | | |
| Staging BE pubblico | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Tu lo generi, build con fallback | User generates keystore + `key.properties`; debug-key fallback with warning | ✓ |
| Tu lo generi, build che fallisce | | |
| Lo genera Claude | | |

## BE 17 companion (asked from this repo, recorded in the BE `17-CONTEXT.md`)

| Question | Selected |
|----------|----------|
| Authorization matrix width | Innkeeper + ownership handlers, table-driven from the enumerated lists |
| How the replaced device learns the revocation | WS closed at once, JWT valid until expiry (15 min), refresh refused with the reason |
| Stale JWT role (T-10-19) | A role change revokes the user's sessions (`roleChanged`) |
| Revocation reason on the wire | `SESSION_REVOKED` + `extensions.reason` (same string in the WS close reason) |

## Closing gate

«Pronto per il CONTEXT» selected (no further areas).

## Claude's Discretion

Notice copy and fail-fast shape; `.env` exclusion mechanism; logger seam; grep patterns and CI layout; gradle wiring details; emulator image; test structure of the leak-tracking and dual-session harnesses; plan split around the BE gate.

## Deferred Ideas

«Esci da tutti i dispositivi»; diagnostics badge; per-request session validation on the BE; heal mechanics (`canHeal`); iOS/store/accessibility; «Failed host lookup» explained by the device setup.
