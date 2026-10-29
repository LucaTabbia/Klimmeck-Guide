# Phase 10 — deferred items

- **10-01:** the repo-wide analyzer baseline is 52 issues = 51 `info` + 1 `warning` (`unnecessary_cast`, `test/repository/services/auth/auth_token_service_contract_test.dart:40`, untouched since Phase 1), not 52 `info`. The plans' gate command `! grep -qE '^ *(error|warning) •'` therefore exits 1 on the baseline itself. Out of scope for 10-01 (file not touched); fix in a later plan or quick task (remove the redundant cast) so the gate becomes meaningful.
