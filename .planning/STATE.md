---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Healing & Models
status: phase-complete
last_updated: "2026-11-11T20:00:00.000Z"
last_activity: 2026-11-11 -- Phase 18 plan 18-13 executed (device E2E complete, HEAL-01..06 complete)
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 13
  completed_plans: 13
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-11-10 at the v1.1 start)

**Core value:** I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.
**Current focus:** Phase 18 — Heal Quests by City Size — complete 13/13 on `feat/18-heal-quests-by-size` (device E2E passed 2026-11-11 against BE `develop` 66df2ef2, HEAL-01..06 complete); next: the PR to `develop` opened by the user, then Phase 19 (↔ BE Phase 19)

## Current Position

Milestone: **v1.1 Healing & Models** — started 2026-11-10 (Phases 18–19; previous: v1.0 Core Loop, shipped 2026-11-10, tag `v1.0`)
Phase: 18 of 19 (Heal Quests by City Size) — complete 13/13 on `feat/18-heal-quests-by-size`: device E2E 18-13 passed on 2026-11-11 (steps 1–14 pass, optional 15 skipped; extra prison/guard checks pass, E5 not explicitly confirmed)
Plan: 13 of 13
Status: Phase complete — `18-HUMAN-UAT.md` complete, FE `BACKEND-NOTES.md` written; UAT fixes on the branch (Library «Nuovo» on a never-opened book — Phase 17 D-07 amended by the user; pawn labels on one line; flattened magic sheet); full suite 4031 green, analyzer 47 info / 0 warning / 0 error, 46/46 documents OK.
Last activity: 2026-11-11 -- Phase 18 plan 18-13 executed (device E2E, requirements closed, FE handoff)
Next step: the user opens the PR `feat/18-heal-quests-by-size` → `develop` (`GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop`, never `main`), then Phase 19 Model Review (gated on the BE Phase 19 merge). Still to check on the device: a narrative quest sheet with prizes, a cost line and the Paladin title overflowed by 22 px on the landscape test harness with the test font (pre-existing, A-IN-05) — not exercised in 18-13.

## Current Milestone

v1.1 Healing & Models: Phase 18 Heal Quests by City Size (HEAL-01..06, ↔ BE 18) → Phase 19 Model Review companion (MODEL-01..04, ↔ BE 19). Companion BE milestone v1.1 «Cura e modelli» (BE Phases 18–20; BE 20 has no FE phase). Research skipped at the milestone start (phases already discussed); per-phase research stays in plan-phase.

## Accumulated Context

- Stack: Flutter (mobile) + NestJS + MongoDB + GraphQL (HTTP + WS) + REST; `graphql_flutter` 5.2.1, `flutter_bloc`, FCM data-only, `flutter_map`.
- Entry points: `lib/main.dart` (prod, `--dart-define-from-file=env/prod.json`) and `lib/main_dev.dart` (`--flavor dev`, `.env` with `DEV_AUTH_ENABLED=true` for the bypass); release signed with `android/key.properties` outside VCS.
- The world lives only in the DB (BE D-36); asset on Cloudinary; single Twitch channel, the streamer is the only `innkeeper`.
- Backend is the source of truth for every rule; the FE maps `extensions.code` to Italian banners (`BAD_USER_INPUT` generic copy in all 11 classifiers).
- Device UAT setup (adb reverse, Doze, tunnel for the release build) is recorded in the orchestrator's memory, not a product concern.
- Formatting baseline is not `dart format`-clean: format only the touched files, never a directory.

### Roadmap Evolution

- v1.0 Core Loop: 12 phases from the brief (Auth split into Phase 1 stub + Phase 11 real, Settings/Notifications split), extended on 2026-10-29 with Phases 13–17 mirroring BE 11–16, executed 1 → 11 → 2 … 10 → 13 → 14 → 15 → 16 → 17 → 12 (Hardening last). Details in `milestones/v1.0-ROADMAP.md`.
- 2026-11-10: milestone archived; `REQUIREMENTS.md` removed (recreated by `/gsd-new-milestone`).
- 2026-11-10: milestone v1.1 Healing & Models started with Phases 18–19 (scope confirmed by the user: only the phases discussed on 2026-11-09); `REQUIREMENTS.md` recreated with HEAL-01..06 and MODEL-01..04.

## Open Questions / Blockers

- **CHAR-06** (client-side NSFW pre-screen) — known gap of v1.0; decide in v1.1 whether to drop it on the server-side moderation (BE Phase 10 + HARDEN-10 codes).
- **Backend rule F2** (Phase 9 UAT): a started quest whose participant is archived is fought as an occupied seat — honoured by the BE 9.2/10 seat holders; keep an eye on it in the Phase 19 model review.
- **Auto-realignment after a network loss** (18-13 step 3): after the USB tunnel came back the app had not realigned by itself within ~40 s (restarted); not reproduced in a controlled way — investigate the WS reconnection/refetch.
- **Board families E5** (18-13): quest families per type not explicitly confirmed by the user on the device; no defect reported.
- **iOS** never exercised (push, signing, store) — post-v1.0.
- **Dev setup reminders for the user** (from the Phase 12 UAT): `DEV_AUTH_ENABLED=true` back in the FE `.env`, the tunnel redirect URI removed from the Twitch app, tunnel and emulator stopped.

### Quick Tasks Completed (v1.0)

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 261022-f0n | worldMission listed and acceptable only in its own city (D-11/D-16 amended, user correction) | 2026-10-22 | 10d6298 | [261022-f0n-worldmission-listed-and-acceptable-only-](./quick/261022-f0n-worldmission-listed-and-acceptable-only-/) |
| fast-261022 | quest parsing tolerant to catalog items without description and prizeItem as AssetQuantity (board empty with the live catalog) | 2026-10-22 | e4211cc | — (gsd-fast, inline) |
| fast-261022b | prize loot crash in the quest sheet (effect/power selected for prizeItem, LootItemCard null-safe) | 2026-10-22 | c663be2 | — (gsd-fast, inline) |
| 261022-qkx | tear geometry: horizontal tear at 10% height, lower piece slides off-screen unclipped, seeded jaggedness (D-06 amended after the device UAT) | 2026-10-22 | f8e08ef | [261022-qkx-tear-geometry-horizontal-tear-near-the-t](./quick/261022-qkx-tear-geometry-horizontal-tear-near-the-t/) |
| 261025-grp | waiting-for-party label (k/N), abandonQuest with parchment confirmation, questCancelled push category (BE 09-19 contract; branch feat/party-waiting from feat/07-travel) | 2026-10-25 | 4633b3f | [261025-grp-party-waiting-abandon](./quick/261025-grp-party-waiting-abandon/) |
| 261026-gld | dashed route (preview and remaining part) in primaryGold after the device UAT (D-06 amended, user feedback on step 3) | 2026-10-26 | 8ba1154 | [261026-gld-gold-route-dash](./quick/261026-gld-gold-route-dash/) |
| 261026-prt | live party counter: questUpdated subscription watched while the lane waits for the party (BE 09-20) | 2026-10-26 | 073c39f | [261026-prt-party-counter-live](./quick/261026-prt-party-counter-live/) |
| 261102-lor | drop Lore.unlocked from the lore documents and model (BE Phase 11 D-25, BE PR #17; branch fix/lore-unlocked-field from develop, to merge with the end of that phase) | 2026-11-02 | d6346a9 | [261102-lor-lore-unlocked-field](./quick/261102-lor-lore-unlocked-field/) |
| 261105-hea | `heal` as ninth spell use type («Cura», provisional icon) and tolerant parsing of unknown use types (BE quick task twin on the same branch name; branch fix/spell-heal-use-type from develop) | 2026-11-05 | 250c9f0 | [261105-hea-spell-heal-use-type](./quick/261105-hea-spell-heal-use-type/) |
| 261105-lgd | legends take the hero seats after the legend seats, before the wildcards (BE 13.1 D-08 mirror in `canRegisterWithTitle`; branch feat/quests-per-area-follow-ups stacked on fix/spell-heal-use-type) | 2026-11-05 | 6508fed | [261105-lgd-legend-hero-seat](./quick/261105-lgd-legend-hero-seat/) |
| 261105-scp | `QuestScopeListener`: reread `quests` when `characterUpdated` changes location, title or a lane's quest (BE 13.1 D-05 `quests` per area; same branch) | 2026-11-05 | d677a24 | [261105-scp-quest-scope-reread](./quick/261105-scp-quest-scope-reread/) |
| 261109-inj | `LootItem.canHeal` read by the FE and shown as «Cura: …» on heal items (shop and Journal); BE twin on the same branch name | 2026-11-09 | branch gemello `fix/…` | [261109-inj-loot-effected-injuries](./quick/261109-inj-loot-effected-injuries/) |
| 261109-inj2 | nine new `InjuryType`s (37) with labels, severity and effects; tolerant parsing of the character injuries; BE twin | 2026-11-09 | branch gemello `fix/…` | [261109-inj2-new-injury-types](./quick/261109-inj2-new-injury-types/) |
| 261110-shs | seven quest sheet ids re-uploaded on Cloudinary (old ones 404) and the two new torn announcement sheets for a torn heal (on the Phase 18 branch) | 2026-11-10 | 9c0b175 | [261110-shs-quest-sheet-assets](./quick/261110-shs-quest-sheet-assets/) |
| 261110-mag | quest type `magic` («Magia», own sheets `magicSheet` / `tornMagicSheet`, treated like a study) and the general rule «every non-acceptable quest is drawn torn, a busy lane excepted»; job, crime and study wait for their torn assets; BE twin on the BE Phase 18 branch | 2026-11-10 | a0c870b | [261110-mag-quest-magic-type](./quick/261110-mag-quest-magic-type/) |
| 261110-shs2 | every quest type now draws its own sheets, whole and torn (crime, guard, hunt on the «game» files, job, heal, world mission, boss, aid, revised magic; study on the announcement sheets; dungeon on the generic quest sheets); constants renamed after the quest type they draw (`enemySheet…` for boss/enemy files named `huntSheet…` on Cloudinary, `huntSheet…` for the `gameSheet…` files) | 2026-11-10 | 07a753e | commits only, see `quest_paper_asset.dart` |
| 261110-cgd | prison after a crime arrest (countdown from `imprisonedUntil`, marker «In prigione per: …» over the pawn, board and shop closed, travel blocked, `CHARACTER_IMPRISONED` notices) and guard encounter lines on the result sheet; `prisonRelease` push category («Uscita di prigione»); fragment selections deferred to plan 18-12; BE twins `261110-cgd` and `261110-prp` on the BE Phase 18 branch | 2026-11-10 | 761b73e | [261110-cgd-crime-arrest-guard-encounter](./quick/261110-cgd-crime-arrest-guard-encounter/) |

## Session Continuity

Last session: 2026-11-10 — v1.1 milestone start (FE and BE)
Stopped at: Completed 18-13-PLAN.md (2026-11-11) — Phase 18 complete, PR to `develop` next
Resume file: .planning/phases/18-heal-quests-by-size/18-13-SUMMARY.md
