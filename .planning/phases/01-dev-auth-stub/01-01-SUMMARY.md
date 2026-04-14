---
phase: "01"
plan: "01"
subsystem: auth
tags: [flutter_dotenv, tdd, scaffolding, dev-stub, wave-0]
dependency_graph:
  requires: []
  provides:
    - flutter_dotenv ^6.0.0 runtime dependency
    - bloc_test ^10.0.0 dev dependency
    - mocktail ^1.0.5 dev dependency
    - .env asset registrato in pubspec.yaml
    - .env.example committato in VCS
    - test/helpers/auth_fixtures.dart (fixtures condivise)
    - test/helpers/fixtures/dev_auth_env.dart (loadTestEnv helper)
    - 7 test RED stub per DEV-AUTH-01..05
  affects:
    - Plan 01-02 (implementa contratto AuthTokenService → GREEN)
    - Plan 01-03 (implementa wiring RepositoryProvider + interceptors → GREEN)
tech_stack:
  added:
    - flutter_dotenv 6.0.0 (lettura .env file da asset Flutter)
    - bloc_test 10.0.0 (helper TDD per Cubit/BLoC)
    - mocktail 1.0.5 (mock library preferita dal progetto)
  patterns:
    - TDD Red-Green-Refactor (Wave 0 = RED scaffolding)
    - dotenv.loadFromString(envString:) per test in-memory senza file reale
key_files:
  created:
    - pubspec.yaml (modificato: +3 deps, +.env asset)
    - .env.example
    - .gitignore (modificato: +.env esclusione)
    - test/helpers/auth_fixtures.dart
    - test/helpers/fixtures/dev_auth_env.dart
    - test/repository/services/auth/auth_token_service_contract_test.dart
    - test/repository/services/auth/dev_auth_token_service_test.dart
    - test/repository/services/auth/dev_auth_token_service_role_test.dart
    - test/repository/services/auth/dev_auth_token_service_noop_test.dart
    - test/app/app_wiring_test.dart
    - test/network/auth_interceptor_test.dart
    - test/network/graphql_auth_link_test.dart
  modified: []
decisions:
  - "dotenv.loadFromString usa named param envString: (non testLoad/fileInput — API reale flutter_dotenv 6.0.0 verificata dal source)"
  - "loadTestEnv() è sincrono-in-memory: i test non toccano mai il file .env su disco (mitigazione T-01-01-04)"
metrics:
  duration_minutes: 20
  completed_date: "2026-04-14"
  tasks_completed: 3
  tasks_total: 3
  files_created: 12
---

# Phase 01 Plan 01: Dev Auth Stub — Wave 0 Setup Summary

**One-liner:** Ambiente TDD pronto con flutter_dotenv 6.0.0, test helper env in-memory, e 7 test stub RED per il contratto AuthTokenService (DEV-AUTH-01..05).

## Tasks completati

| # | Nome | Commit | File chiave |
|---|------|--------|-------------|
| 1 | Install deps + configure .env assets + gitignore | `422bcd7` | pubspec.yaml, .env.example, .gitignore |
| 2 | Scaffold test fixtures + helpers | `276819e` | test/helpers/auth_fixtures.dart, test/helpers/fixtures/dev_auth_env.dart |
| 3 | Scaffold RED test stubs DEV-AUTH-01..05 | `fe9a447` | 7 file test (vedi key_files) |

## Dipendenze aggiunte

| Package | Versione | Tipo |
|---------|----------|------|
| flutter_dotenv | ^6.0.0 | runtime |
| bloc_test | ^10.0.0 | dev |
| mocktail | ^1.0.5 | dev |

## Test RED scaffolding (stato atteso: falliscono per import mancanti)

| File | Requirement | Stato |
|------|------------|-------|
| test/repository/services/auth/auth_token_service_contract_test.dart | DEV-AUTH-01 | RED |
| test/repository/services/auth/dev_auth_token_service_test.dart | DEV-AUTH-02 | RED |
| test/repository/services/auth/dev_auth_token_service_role_test.dart | DEV-AUTH-03 | RED |
| test/repository/services/auth/dev_auth_token_service_noop_test.dart | DEV-AUTH-04 | RED |
| test/app/app_wiring_test.dart | DEV-AUTH-05 | RED |
| test/network/auth_interceptor_test.dart | DEV-AUTH-05 | RED |
| test/network/graphql_auth_link_test.dart | DEV-AUTH-05 | RED |

Tutti falliscono con errori `Target of URI doesn't exist` su:
- `lib/repository/services/auth/auth_token_service.dart`
- `lib/repository/services/auth/dev_auth_token_service.dart`
- `lib/repository/services/rest/auth_interceptor.dart`
- `lib/repository/services/graphql/auth_link.dart`

Questi file verranno creati in Plan 02 (contratto + stub) e Plan 03 (wiring + interceptors).

## Sicurezza (.env)

- `.env` ignorato da git: `git check-ignore .env` exit 0
- `.env.example` committato con placeholder sicuri (no secret reali)
- `loadTestEnv()` usa `dotenv.loadFromString(envString:)` in-memory: i test non leggono mai il file `.env` reale su disco (mitigazione T-01-01-04)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] API flutter_dotenv: testLoad → loadFromString(envString:)**
- **Found during:** Task 2 (`dart analyze test/helpers/`)
- **Issue:** Il RESEARCH.md documentava `dotenv.testLoad(fileInput:)` ma flutter_dotenv 6.0.0 non ha tale metodo. L'API corretta è `dotenv.loadFromString(envString:)` (parametro named).
- **Fix:** Aggiornato `dev_auth_env.dart` con il nome metodo e parametro corretti verificati dal source package.
- **Files modified:** `test/helpers/fixtures/dev_auth_env.dart`
- **Commit:** `276819e`

## Nota per Plan 02/03

I test sono in stato RED per design. Plan 02 crea `AuthTokenService` abstract + sealed `AuthState` + `DevAuthTokenService` → porta a GREEN i test `auth_token_service_contract_test`, `dev_auth_token_service_test`, `dev_auth_token_service_role_test`, `dev_auth_token_service_noop_test`. Plan 03 crea `AuthInterceptor` (dio) + `AuthAuthLink` (graphql) + wiring `RepositoryProvider` → porta a GREEN i test `auth_interceptor_test`, `graphql_auth_link_test`, `app_wiring_test`.

## Self-Check: PASSED

- [x] pubspec.yaml contiene flutter_dotenv ^6.0.0, bloc_test ^10.0.0, mocktail ^1.0.5
- [x] pubspec.yaml contiene `- .env` sotto flutter.assets
- [x] .env.example esiste
- [x] .env gitignored (git check-ignore exit 0)
- [x] test/helpers/auth_fixtures.dart esiste
- [x] test/helpers/fixtures/dev_auth_env.dart esiste
- [x] 7 test stub esistono ai percorsi indicati
- [x] flutter test fallisce per errori di import (stato RED confermato)
- [x] Commit 422bcd7, 276819e, fe9a447 presenti in git log
