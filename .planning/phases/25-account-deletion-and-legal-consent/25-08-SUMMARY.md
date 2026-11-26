---
phase: 25-account-deletion-and-legal-consent
plan: 08
subsystem: planning
tags: [account-deletion, legal-consent, device-uat, closing, handoff]
requires:
  - 25-07 (the gate: documents registered, deletions live, switch on)
  - BE Phase 26 on the BE branch feat/26-eliminazione-account-e-consenso 9321434a (BE PR #53, not merged)
provides:
  - 25-HUMAN-UAT.md, the device E2E record (status complete)
  - BACKEND-NOTES.md §3, the UAT outcome for the BE agent
  - CONSENT-01..03 and ACCOUNT-01..05 complete; Phase 25 closed 8/8
affects: []
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/25-account-deletion-and-legal-consent/25-HUMAN-UAT.md
    - .planning/phases/25-account-deletion-and-legal-consent/25-08-SUMMARY.md
  modified:
    - .planning/phases/25-account-deletion-and-legal-consent/BACKEND-NOTES.md
    - .planning/phases/25-account-deletion-and-legal-consent/25-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "D-02 amended by the user in the UAT: the Settings sheet is three closed app dropdowns with «Esci» last; «Elimina personaggio» and «Elimina account» live under «Azioni irreversibili»"
  - "The body of the push of a cancelled started quest was dictated by the user (BE copy): «Un membro del party ha lasciato il mondo: Missione annullata, ciò che hai consumato è stato rimborsato.»"
  - "Gate and schema check re-run on the BE branch (BE PR #53 not merged): to re-run on BE develop after the merge"
metrics:
  duration: ~25 min (documents only; the device session was run by the orchestrator)
  completed: 2026-11-25
  tasks: 3
  files: 7
---

# Phase 25 Plan 08: Device E2E, UAT outcome and closing Summary

The device E2E of account deletion and legal consent passed on a Samsung phone against the BE branch `feat/26-eliminazione-account-e-consenso`: all eleven steps passed in the user's words, steps 7 and 10 as variants and step 9 after a fix. The eight requirements are complete and Phase 25 is closed 8/8. The schema check still has to be rerun on BE `develop` once BE PR #53 is merged.

This plan changed documents only: no file under `lib/` or `test/`.

## Tasks

| Task | What | Commit |
|------|------|--------|
| 1 Gate re-check and the UAT record | `GATE_OK` on the BE branch; `25-HUMAN-UAT.md` with the eleven steps verbatim | in the closing commit (the session was already over, so the script was written with its results in one pass) |
| 2 Device E2E (human checkpoint) | run by the orchestrator with the user, one step per message; its facts are the only source of the results | the eight UAT commits `816b6fea`..`2f0defd2` (orchestrator) |
| 3 Record, requirements, planning documents, BE notes | this summary and the six documents | `docs(phase-25): record the device E2E and close the phase` |

## Gates

Gate re-check, on `origin/feat/26-eliminazione-account-e-consenso` after one `git fetch origin` in the BE repo (ordered by the orchestrator; BE `git status --short` empty afterwards):

```
GATE_OK
9321434a docs(phase-26): record the push text dictated in the device UAT
```

Five checks, as in 25-07: `CharacterStatus.innkeeperInjuries`, `deleteMyAccount: Boolean!`, `deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!`, `DeletedAccount.twitchId: String!`, `exchangeLoginTicket`.

Schema check on the same SDL (25-07 command):

```
dumped 57 documents
validate exit 0
OK lines: 57
other lines: 0
OK DeleteAccountByTwitchLogin.graphql
OK DeleteMyAccount.graphql
```

Analyzer gate:

```
47 issues found. (ran in 6.0s)
ANALYZE_GATE_OK
```

Not rerun here, as told by the orchestrator, who ran them after the UAT fixes: full suite `+5706: All tests passed!`, `hardening_check: OK`. BE (orchestrator): unit 326 suites / 4880 tests, `account-deletion.resolver.int-spec` 32 tests, `tsc` clean.

## Device E2E outcome

Record: `25-HUMAN-UAT.md` (`status: complete`, `be_ref` the BE branch at `9321434a`).

| Step | Result |
|------|--------|
| 1 Login screen, 2 Links | pass |
| 3 Consent recorded | pass (run with an existing user and with a new Twitch account) |
| 4 Memory | pass |
| 5 Settings | pass; the layout was then changed by the user (D-02 amended) |
| 6 Dialog | pass |
| 7 Started quest cancelled | pass as a variant: the innkeeper deleted the companion by username; the own deletion was run separately |
| 8 From zero | pass |
| 9 Innkeeper's refusals | pass after a fix (dialog redesigned) |
| 10 Online player deleted by the innkeeper | pass, with the innkeeper's side played by the orchestrator (one phone) |
| 11 Not-started quest | pass |

Not run or not judged, open and non blocking: a second physical device, TalkBack on the consent row (IN-06), the checkbox border (IN-05).

Changes made during the session (orchestrator, each test-first): `816b6fea` / `af18857d` (innkeeper's dialog above the landscape keyboard), `31cd392a` / `c88f537a` (destructive confirmation scrolls above the keyboard), `8766a865` / `de141943` / `c446b7e2` (Settings in closed app dropdowns, «Esci» last), `2f0defd2` (D-02 amended). BE: `056995f8`, `8d753909`, `9321434a` (push body dictated by the user).

D-22 privacy lines: done by the orchestrator, legal repo commit `0659dc4`.

An orchestrator's seeding mistake is recorded in the UAT file (a seed with a due date in the past, restored from the backup): not a product defect.

## Requirements

All eight marked complete with `gsd-tools requirements mark-complete`; boxes and traceability rows checked by reading the file (8 boxes `[x]`, 8 rows `| <ID> | Phase 25 | Complete |`, no manual fix needed).

- CONSENT-01 (steps 1, 2), CONSENT-02 (4, 7), CONSENT-03 (3)
- ACCOUNT-01 (5, 6) — as amended by D-02
- ACCOUNT-02 (7, 8, 10), ACCOUNT-03 (9, 10), ACCOUNT-04 (7, 11)
- ACCOUNT-05 (gate of 25-07, 57 × OK, full suite, steps 1–11, D-22 lines committed)

## Deviations from Plan

1. **[Orchestrator's order] One pass, one commit.** The session was over when this executor started, so `25-HUMAN-UAT.md` was written directly with its results; the separate commit `docs(phase-25): write the device UAT script` was not made.
2. **[Orchestrator's order] BE ref and fetch.** The gate and the schema check ran on `origin/feat/26-eliminazione-account-e-consenso` (`9321434a`) instead of `origin/develop`, after one read-only `git fetch origin` in the BE repo. The schema check must be rerun on BE `develop` after the merge of BE PR #53.
3. **[Orchestrator's order] Full suite not rerun.** The orchestrator's run after the UAT fixes is recorded (`+5706`).
4. **Five gate checks instead of three.** The fuller block of 25-07 was used (it adds `innkeeperInjuries` and `exchangeLoginTicket`).
5. **STATE and ROADMAP edited with python, not with `gsd-tools state …`** (REPO-RULES: STATE only with Edit or python). The `progress` counters of the STATE frontmatter (79/79 plans, 6 phases) were already stale before this plan and were left as they are.
6. **No phase line in the roadmap milestone list.** The list stops at Phase 24, so only the Progress row and the plan box were closed.

## Open points

- The text of ACCOUNT-01 in `REQUIREMENTS.md` and success criterion 3 of the roadmap still describe the first Settings layout («Elimina account» under «Esci»); the layout as built follows D-02 as amended. The texts were not rewritten here.
- Roadmap success criterion 6 names the merged BE SDL: the check holds on the BE branch, the rerun on BE `develop` is pending.
- Next step: after BE PR #53 is merged the user takes FE PR #59 out of draft; the schema check is then rerun on BE `develop`.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: T-25-70 (no usernames, ids or secrets: the secrets grep prints nothing on the written files), T-25-71 (requirements marked only per the map and the user's words), T-25-72 (no device, BE process, DB or legal repo touched by the executor), T-25-73 (gate re-checked on the ref under test).

## Self-Check: PASSED
