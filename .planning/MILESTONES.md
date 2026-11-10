# Milestones

## v1.0 Core Loop (Shipped: 2026-11-10)

**Phases completed:** 17 phases, 180 plans, 131 tasks (plus 10 quick tasks and 2 inline fast fixes)
**Timeline:** roadmap 2026-04-10 → shipped 2026-11-10; Phase 1 completed 2026-04-15, Phases 2–17 executed between 2026-10-06 and 2026-11-10 (Hardening last)
**Codebase at the close:** 35 993 lines of Dart in `lib/` (491 files), 64 676 lines of tests (394 files), 3 704 tests green and analyzer 0 error / 0 warning at the Phase 12 gate; 1 610 commits, 22 merged PRs (last: FE PR #45 `refactor/12-hardening`, CI green)
**Companion:** backend milestone v1.0 Core Loop (BE) — 21 phases, 261 plans, closed the same day on BE `develop` `9973fcb1` (last PRs #27 Phase 17 and #28 city sizes)

**Delivered:** the viewer logs in with Twitch, receives the live user and character state, creates a character, accepts quests with the tear gesture, travels on the server clock with food and ambushes, sees every quest outcome on a parchment that is never lost, equips spells, buys from the city pools, unlocks lore, and the innkeeper runs the story and world-mission queue from the Locanda; the release build ships without the dev bypass, signed, TLS-only and verified by CI.

**Key accomplishments:**

1. **Real session against the backend** — BE-mediated Twitch login (ticket + S256 challenge), refresh single-flight and proactive, transparent retry, WebSocket re-authentication, atomic logout, `AuthGate`; «l'ultimo login caccia l'altro» with close `4409` and `SESSION_REVOKED` + reason turned into specific sign-in notices (Phases 1, 11, 12 ↔ BE 2, 17).
2. **Live state and notifications** — `userUpdated` / `characterUpdated` subscriptions with silent reconnect, server-clock offset, degraded-time watchdog; data-only FCM + in-app banners for travel end, streamer live, quest end, quest cancelled and ambush defeat, taps routed to the Map (Phases 3, 5, 7 ↔ BE 3, 5, 6).
3. **The core loop on the Map** — character creation page, quest board on a city marker with per-family sheets and the swipe-left tear, pawn drag → parchment confirmation with ETA, food and life → live travel on the road, combat result sheet with FIFO queue, acknowledgement and death-before-creation, Spells section with backend-driven slots and recovery countdowns (Phases 2, 6, 7, 8, 9, 15 ↔ BE 2.1, 7, 8, 9, 9.1, 9.2, 14).
4. **The world as data** — city shops selling only the city pool by size, server-generated enemy/boss quests with the multi-enemy contract and «Genera missioni», travel ambushes with reports in a carousel at arrival, unlockable lore (Library filtered per character, enemy silhouettes, «Nuovo» bookmarks) (Phases 13, 14, 16, 17 ↔ BE 11, 12, 13, 13.1, 15, 16).
5. **The innkeeper's Locanda** — live queue of story/worldMission requests, completion form with per-participant overrides, teleport from the queue, `QUEST_IN_PROGRESS` guard (Phase 10 ↔ BE 9, 10).
6. **Hardening and release readiness** — prod entry point without `DevAuthTokenService` (`lib/main_dev.dart` + `--flavor dev` keep the bypass), release bundle without `.env`, keystore signing with debug fallback, `InsecureTransportScreen` for cleartext URLs, silent logs, GitHub Actions CI with guard greps and the release build, leak-tracking harness over the shell → logout, concurrent-refresh / logout / identity-transition / dual-session tests, `BAD_USER_INPUT` and moderation codes in every classifier, `City.size` visibility with Talmvere always visible; device E2E on Samsung + emulator with the signed release through a TLS tunnel and the real Twitch login (Phase 12 ↔ BE 17).

**Known Gaps:**

- **CHAR-06** — client-side NSFW pre-screen of the portrait never shipped (user decision, Phase 2 D-17). The authoritative check is server-side since BE Phase 10 (Sightengine before Cloudinary) and the FE maps `IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE` since HARDEN-10; decide in v1.1 whether to drop the requirement or keep it.
- **iOS** — push, release signing and store readiness are Android-only in v1.0 (Phase 5 D-xx, Phase 12 scope).
- **Accessibility pass (FUT-04)** deferred to a later milestone.

**Process notes:**

- No `/gsd-audit-milestone` was run before this close: every phase closed with its VERIFICATION.md, SECURITY.md and a device HUMAN-UAT approved by the user, and the last phase (Hardening) was itself the cross-phase audit.
- Archive: `milestones/v1.0-ROADMAP.md` (full phase details, traceability and milestone summary) and `milestones/v1.0-REQUIREMENTS.md`; phase directories stay in `.planning/phases/` (`/gsd-cleanup` can move them later).
- Candidates for v1.1 already discussed on branches: Phase 18 Heal quests by size (+ journal potions with a global recovery, `feat/18-heal-quests-by-size`), Phase 19 Model review (`feat/19-model-review`), BE Phase 20 progressive food and life (BE only). Those branches edit `ROADMAP.md`, `REQUIREMENTS.md` and `STATE.md` and must be rebased on this close.

---
