---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Core Loop
status: completed
last_updated: "2026-11-10T01:30:00.000Z"
last_activity: 2026-11-10 -- v1.0 Core Loop milestone completed and archived (17/17 phases, 180/180 plans)
progress:
  total_phases: 17
  completed_phases: 17
  total_plans: 180
  completed_plans: 180
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-11-10 after the v1.0 milestone)

**Core value:** I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.
**Current focus:** Planning the next milestone (v1.1) with `/gsd-new-milestone`

## Current Position

Milestone: **v1.0 Core Loop — SHIPPED 2026-11-10** (archive: `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md`; summary: `MILESTONES.md`; retrospective: `RETROSPECTIVE.md`)
Phase: none active — all 17 phases complete (last: Phase 12 Hardening, device E2E approved 2026-11-10, FE PR #45 merged on `develop` `8d8cc34`)
Plan: —
Status: v1.0 milestone complete — close recorded on `docs/v1-milestone-close` (PR → `develop`); tag `v1.0` to be created on the `develop` merge commit after the PR merge
Last activity: 2026-11-10 -- v1.0 milestone completed and archived
Next step: `/gsd-new-milestone` (v1.1). Candidates already discussed: Phase 18 Heal quests by size (+ journal potions, `feat/18-heal-quests-by-size`, ↔ BE 18), Phase 19 Model review (`feat/19-model-review`, ↔ BE 19), BE Phase 20 progressive food and life (BE only). Those branches carry their own edits of `ROADMAP.md`, `REQUIREMENTS.md` and `STATE.md` from before the close and must be rebased: their phase sections go under the v1.1 milestone of the new roadmap, `REQUIREMENTS.md` is recreated by the new milestone.

## Current Milestone

None — v1.0 Core Loop shipped. The companion BE milestone v1.0 (21 phases, 261 plans) closed the same day on BE `develop` `9973fcb1`.

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

## Open Questions / Blockers

- **CHAR-06** (client-side NSFW pre-screen) — known gap of v1.0; decide in v1.1 whether to drop it on the server-side moderation (BE Phase 10 + HARDEN-10 codes).
- **Backend rule F2** (Phase 9 UAT): a started quest whose participant is archived is fought as an occupied seat — honoured by the BE 9.2/10 seat holders; keep an eye on it in the Phase 19 model review.
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
| 261109-inj | `LootItem.canHeal` read by the FE and shown as «Cura: …» on heal items (shop and Journal); BE twin on the same branch name | 2026-11-09 | — | — (recorded in the Phase 12 branch history) |
| 261109-inj2 | nine new `InjuryType`s (37) with labels, severity and effects; tolerant parsing of the character injuries; BE twin | 2026-11-09 | — | — (recorded in the Phase 12 branch history) |

## Session Continuity

Last session: 2026-11-10 — v1.0 milestone close (FE then BE)
Stopped at: milestone archived; PR `docs/v1-milestone-close` → `develop` to merge, then tag `v1.0`
Resume file: .planning/MILESTONES.md
