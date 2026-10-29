# Phase 10 — deferred items

- **10-01:** the repo-wide analyzer baseline is 52 issues = 51 `info` + 1 `warning` (`unnecessary_cast`, `test/repository/services/auth/auth_token_service_contract_test.dart:40`, untouched since Phase 1), not 52 `info`. The plans' gate command `! grep -qE '^ *(error|warning) •'` therefore exits 1 on the baseline itself. Out of scope for 10-01 (file not touched); fix in a later plan or quick task (remove the redundant cast) so the gate becomes meaningful.
  - **Resolved by the orchestrator before 10-02 (2026-10-29):** the redundant cast was removed (`fix(test): drop the redundant cast in the auth token contract test`); the repo-wide analyzer now reports 51 issues, all `info`, and the gate command exits 0. Later plans keep the `≤ 52` ceiling.
