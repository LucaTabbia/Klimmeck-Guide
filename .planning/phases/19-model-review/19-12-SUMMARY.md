---
phase: 19-model-review
plan: 12
subsystem: validation
tags: [gate, schema-check, full-suite, analyzer, format, product-rules, validation]
requires: ["19-11"]
provides:
  - "Schema gate GATE_OK and 46/46 documents valid on the merged BE SDL (BE origin/develop 48b20701)"
  - "Full suite 4216 green, analyzer 47 info / 0 warning / 0 error, added files format-clean, no forbidden trailer in the 87 commits of the phase"
  - "19-VALIDATION.md approved: rows 19-01-01..19-12-02 green, Wave 0 ticked; only the device rows 19-13-01..03 pending"
affects: [19-13]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - .planning/phases/19-model-review/19-VALIDATION.md
    - test/shared/components/cards/companion_card_test.dart
    - test/shared/components/companion_row_test.dart
decisions:
  - "The one hit of the «spells section untouched» grep (spell_recovery_cubit.dart, review fix IN-02) is accepted: a cubit, not a widget; a type tightening ruled by the orchestrator, no behaviour change"
metrics:
  duration: "~15 min"
  completed: 2026-11-11
  tasks: 2
  files: 3
---

# Phase 19 Plan 12: Gate — schema check, full suite, analyzer, format, product greps, validation — Summary

Every automated gate of the phase is green against the merged BE (`48b20701`): the 46 documents validate, the full suite passes with 4216 tests, the analyzer is at the baseline, and no removed wire name, window reader or product-rule violation is left; `19-VALIDATION.md` is approved except the device rows of 19-13.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `e4a3f2a4` | test(shared): retitle the lenient companion line cases |
| 2 | `6cf97167` | docs(phase-19): validate the model review documents and gates |

Trailer check after every commit: `0`. No production code changed (no RED/GREEN pair: gate plan; commit 1 only changes two test titles).

## Task 1 — gate re-check, schema check, greps

Gate re-check (BE ref read with `git -C <BE> show`, never fetched; SDL and dumped documents in the session scratchpad, outside both repos):

```
GATE_OK
48b20701 Merge pull request #33 from LucaTabbia/feat/19-revisione-dei-modelli
```

Schema check on the merged SDL:

```
dumped 46 documents
grep -c OK   -> 46
grep -vc OK  -> 0
```

Leftover names — `grep -rnE "activeSpells|wearedEquipment|foots|energyWeaknesses|baseWeaknesses" lib test tool` prints nothing; the `<verify>` command prints `LEFTOVER_OK`.

Product-rule greps (plan step 4, in order):

| # | Grep | Output |
|---|------|--------|
| 1 | `package:flutter/` in `lib/models` | nothing |
| 2 | `legacy\|finestra` in the character / owned pet / spell state / spellbook models | nothing |
| 3 | `weaknesses` / `locations` selected in `lib/graphql` | nothing |
| 4 | `quest` / `type` in `location_fragment.dart` | nothing |
| 5 | `relatedLore` in `pet_fragment.dart` | nothing |
| 6 | chrome / dialogs / bars on the three companion widgets | nothing |
| 7 | the new copy outside the helpers (`lib/screens`, `lib/shared`) | nothing |
| 8 | `currentLifePoints` on the five companion widgets (D-18) | nothing |
| 9 | `petXpShare\|pet_xp_share` in `lib` | nothing |
| 10 | diff `88443fa..HEAD` on the spells section and the shop components | **one file**, see below |
| 11 | diff on `cloudinary_assets.dart`, `pubspec.yaml` | nothing |

Exact counts: `Pet.tryFromJson(json)` in `owned_pet.dart` → `0`; `ls active_spell.dart legacy_spell_states.dart | wc -l` → `0`; `'feet',` in `equipment_fragment.dart` → `1`.

**Grep 10 — one hit, accepted, not a gap:**

```
lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart
```

Only commit on the path: `eb07ccfd refactor(journal): make the spellbook entry usages non-nullable` — review fix IN-02, ruled FIX by the orchestrator (`19-REVIEW-FIX.md`). Diff: 1 insertion, 2 deletions (`usages: entry.usages ?? entry.spell.maxUsages ?? 0` → `usages: entry.usages`, one stale doc comment removed). It is a cubit, not a widget: the intent of the grep («no widget of the spells section nor of the shop edited») holds — the four widget files and `shop/components` have no diff. The plan's path list was written before the review.

Decision coverage (step 4b): D-07 (`City.shop` is Mongoose-only, `CityShop` unchanged on the wire), D-10 (execution order after Phase 18) and D-11 (out of scope as listed) needed no work in any plan; D-02 needed no FE change beyond the enemy fixture case of 19-01.

One-line leftover fixed (step 5, orchestrator note): two test titles still said «as the BE of today serves it (D-15)» — retitled «shows neither line when the wire carries no attack, defense, maxXp or rarity (lenient)» in `companion_card_test.dart` and `companion_row_test.dart` (`e4a3f2a4`); bodies untouched, `flutter test` on the two files → `+25: All tests passed!`. After it `grep -rn "BE of today" lib test` prints nothing.

BE repo `git status --short`: empty before and after (T-19-48). No `.env*` read.

## Task 2 — full suite, analyzer, format, trailers, validation

| Gate | Command | Result |
|------|---------|--------|
| Full suite (alone, foreground, timeout 600000 ms, at `e4a3f2a4`) | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` | `01:37 +4216: All tests passed!` |
| Analyzer | `flutter analyze --no-fatal-infos` | `47 issues found.` — 47 info, 0 warning, 0 error, `ANALYZE_GATE_OK` |
| Format of the files added by the phase | per-file `dart format --output=none --set-exit-if-changed` over `git diff --name-only --diff-filter=A 88443fa..HEAD -- lib test tool` | 13 added Dart files, no `UNFORMATTED` line |
| Trailers | `git log 88443fa..HEAD --format=%B \| grep -ciE "co-authored-by\|generated with\|claude-session"` | `0` (86 commits at the time of the gate, review fixes and their docs included) |
| Hardening (extra) | `sh tool/hardening_check.sh` | `hardening_check: OK` |

Suite total: 4031 before the phase → 4207 after the review fixes → **4216** now (plans 10–11 deleted the legacy reader file and the window group and added the fragment, rename and recorded-payload pins). The run happened before the docs commit; nothing under `lib`, `test` or `tool` changed after it.

`19-VALIDATION.md` (`6cf97167`): rows `19-12-01`, `19-12-02` → `✅ green`; every row `19-01-01`..`19-11-03` was already green; the four open Wave 0 lines ticked after checking the files (`character_test.dart`, `equip_item_request_test.dart`, the single-list fixtures and the `active` parameter of `spellStateJson` exist; `legacy_spell_states_test.dart` was created in 19-07 and deleted in 19-11 as planned); frontmatter `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`; sign-off ticked with the line «Gate passed on BE `48b20701`: 46/46 OK, full suite 4216 green, analyzer 47 info (0 warning, 0 error).»

Acceptance:

- `grep -c "wave_0_complete: true"` → `1`
- `grep -c "nyquist_compliant: true"` → **`2`**, not 1: the frontmatter line plus the pre-existing checklist item «`nyquist_compliant: true` set in frontmatter» (template text, present since planning); anchored `^nyquist_compliant: true` → `1`
- `grep -cE "^\| 19-(0[1-9]|1[0-2])-0[1-3] .*✅ green"` → `27` (real rows counted: 2+2+3+2+3+2+2+1+2+3+3+2)
- rows still `⬜ pending`: 3 (`19-13-01..03`); unticked boxes: 0
- `git status --short` → ` M pubspec.lock` only

## Deviations from Plan

None under Rules 1–4. Inside the plan's latitude:

- **Grep 10 prints one path** (review fix IN-02 on a cubit) — explained above, accepted, not fixed.
- **`nyquist_compliant: true` counts 2** — the checklist line of the template; the frontmatter flag is set once.
- **Scratch in the session scratchpad** instead of `mktemp -d` (same «outside the repo» rule, as in 19-10 / 19-11).
- **Two test titles retitled** on the orchestrator's note (`test(shared)` commit, no behaviour change).
- **Review IN-07** (`CharacterAssets.toJson` asymmetric): left as it is, ruled «closed».
- **Bookkeeping in a commit separate from the SUMMARY commit**; STATE frontmatter and the «Current focus» / «Status» / «Next step» lines rewritten on the orchestrator's instruction.

## Notes for the next plans

- **19-13 (device E2E):** every automated gate is green on BE `48b20701`; the branch selects names that exist only on a BE with Phase 19 (the BE on this machine already runs it, with migrated data and the pet content). Device checklist items carried from the review: legibility of long attack lines on the companion card (IN-08) and the ink of a common pet name.
- **19-13:** `requirements mark-complete` belongs to that plan only; MODEL-01..04 are still unticked.
- **Security audit / verifier:** the phase range is `88443fa..HEAD`; suite total to quote is 4216.

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-45 (gate + 46 × OK), T-19-46 (leftover grep empty, counts 0 / 0 / 1), T-19-47 (product-rule greps, one explained hit), T-19-48 (BE read-only, status empty, no `.env*` read, scratch outside the repo), T-19-49 (trailer count 0) are covered above.

## Self-Check: PASSED

- `.planning/phases/19-model-review/19-VALIDATION.md` and the two retitled test files exist.
- Commits `e4a3f2a4`, `6cf97167` are in `git log`.
