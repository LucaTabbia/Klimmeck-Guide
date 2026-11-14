---
phase: 22
slug: companion-defeat-rest-and-recovery
fixed_at: 2026-11-14
review_path: .planning/phases/22-companion-defeat-rest-and-recovery/22-REVIEW.md
iteration: 1
findings_in_scope: 20
fixed: 13
not_needed: 5
deferred: 2
status: all_fixed
---

# Phase 22 — Code Review Fix Report

Every finding of `22-REVIEW.md` was handled under the orchestrator's rulings. Every fix was done in TDD: first a RED commit `test(...)` that fails for the reason of the finding, then a GREEN commit `fix(...)` / `refactor(...)`. HEAD at start: `d147d9f6`.

`status: all_fixed` means that all nine mandatory findings are fixed. Of the remaining findings, five are closed `not_needed` and two are `deferred`, each with its reason below.

- Full suite: **5010 green** (baseline 4994; +16 new tests).
- Analyzer: **47 info / 0 warning / 0 error** (gate unchanged).
- `companionCareEnabled` stays `false`. No GraphQL selection changed.

| ID | Sev | Verdict | Commits (RED → GREEN) | Note |
|----|-----|---------|-----------------------|------|
| A-01 | HIGH | fixed | `9ada2ca8` → `773403ae` | Confirmed at runtime by a widget test: the title `RichText` of the route had `TextDecoration.underline` (the debug style of `MaterialApp`) and no `Material` ancestor. The `pageBuilder` now wraps the sheet in `Material(type: transparency)`. |
| A-02 | MEDIUM | fixed | `47fbad45` → `7f960065` | A `BlocListener<CharacterCubit>` reverses the panel when the selected companion leaves `ownedPets`. The test checks that the `Positioned` goes back to the screen height. |
| A-03 | MEDIUM | fixed | `91f48802` → `b3f6e77c` | `CompanionVitalityState` now keeps the `sources` entry of each vitality. `vitalityFor(owned)` is null when the served entry is newer than the computed one. `isCompanionDefeated(owned, vitality)` falls back to the served `defeated`. Rows, the content and the Journal details bookmark use it. The cubit equality test was updated in the GREEN commit (the state now has `sources`). Note: a Journal-level single-pump test showed that even the character lags one frame in the harness, so the pin is at the row and state level. |
| A-04 | LOW | fixed | `75dd0397` → `b594cf40` | Integer round-half-up `(Δ·e·2 + span) ~/ (2·span)`. The test vector is from the BE rule: max 16, life 3, T 9000 → at +4500 ms the BE gives 11, the old FE gave 10. A brute-force check (3.2 M exact-span cases) gave 96 float mismatches and 0 after the fix. The residual difference from the BE `ceil` of `fullLifeAt` is inherent: the FE never reads `recoveryTime` (D-24). |
| A-05 | LOW | deferred | — | UX choice: should a refused `givePotion` keep the sheet open and drop the target? That needs a product decision, and the BE refusal plus the banner already explain the failure. Not a small, safe change. |
| A-06 | LOW | fixed | `9dd14fa6` → `776cefe9` | `Semantics(enabled: !isDrinking)` on the «Dai a …» parchment. |
| A-07 | LOW | fixed | `fe75465a` → `8bfed04a`, `bea699c7` | (b) A single `CharacterAssets.chosenPetNames` getter replaces the two copies in `shop.dart` and `transaction_modal.dart`. (a) The doc comments of `lifeAsOf` / `fullLifeAt` are now written once each, in a docs-only commit. |
| A-08 | INFO | fixed | `94d553dc` → `ae52bbe1` | The speed text line is gone from `CompanionRow` (the card prints it) and from `CompanionInfo` (the sheet's card prints it; `speedKey` removed). One speed per row and one in the details sheet. The pins were retargeted RED-first (tap target, position, style and order now use the card or the equipped mark). |
| A-09 | INFO | deferred | — | Showing level, xp and life in the shop's sell-side details needs the owned entry and a vitality source in the shop (no `CompanionVitalityCubit` there). Not small. |
| A-10 | INFO | fixed | `14cf3067` → `cd49fc65` | `CompanionSection.toggle` (haptic + ignored-pending) is now public and shared with the Journal details bookmark. |
| B-01 | MEDIUM | not_needed | — | Ruled: the BE decides the key (Phase 23 plan 09: push id = pet id). No FE change. |
| B-02 | MEDIUM | fixed | `b9a9b93f` → `d6aa7306` | A blank or missing name no longer drops the entry. `QuestCompanionOutcome` falls back to «Il tuo compagno» (the existing xp-line wording, now `QuestCompanionOutcome.unnamedLabel`, also used by `companionXpGainedLine`). `MissionCompanion` falls back to «Compagno» (the BE fallback), so the slider stays. The `quest_result_test` pin «missing name → null companion» was retargeted to a missing `lifeBefore` in the GREEN commit. |
| B-03 | LOW | fixed | `b301ffa9` → `e3cd9419` | `companionNamePromptTitle('')` reads «Come chiamerai il tuo compagno?». |
| B-04 | LOW | not_needed | — | The reviewer found no defect: the stale read is harmless, and replaying the prompt is deliberate. |
| B-05 | LOW | fixed | `75ebbd70` → `6c58fb2b` | With no proposal and no correction, the slider shows «Vita prima dello scontro» (`companionLifeBeforeKeyFor`). The label is hidden when a simulated value or a correction exists. |
| B-06 | LOW | fixed | `690254f2` → `b21194eb` | The confirm button is disabled while the normalised text equals `initialName`. Clearing a name stays out of scope (D-31). |
| B-07 | LOW | fixed | `26e6e97d` → `e8928eb5` | Checked against the BE (`rename-pet.int-spec.ts`: `FORBIDDEN` from the `ownerOnly` guard). `FORBIDDEN` → `forbidden` («Questo personaggio non può farlo»). A served but unknown code → `refused`, and with `badUserInput` it reads «Qualcosa è andato storto» with no «riprova». Only `declined` / `unknown` (no code) still offer a retry. |
| B-08 | INFO | not_needed | — | Display-only reading of D-17/D-33. The reviewer asks for no action. |
| B-09 | INFO | not_needed | — | Harmless until the BE sends the push, and the reviewer says so. The popup entry belongs to the gate plan. |
| B-10 | INFO | not_needed | — | List of areas verified clean. |

## Tests added (16)

A-01 1, A-02 1, A-03 2, A-04 1, A-06 1, A-07 1, A-10 1, B-02 2, B-03 1, B-05 1, B-07 4 (two rename cases split from one, two notice cases split from one). The A-08 and B-06 pins were retargeted, not added.

---

_Fixed: 2026-11-14_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
