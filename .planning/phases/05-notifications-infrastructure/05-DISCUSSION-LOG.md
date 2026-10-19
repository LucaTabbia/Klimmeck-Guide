# Phase 5: Notifications Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-19
**Phase:** 05-notifications-infrastructure
**Areas discussed:** Notification permission, Tap routing & popups, In-app banner, Registration lifecycle & logout, Firebase config files, Platform scope (iOS), Legacy cleanup
**Mode:** interactive (the orchestrator proposed the options with a recommended default; the user chose). Not re-asked: everything fixed by the BE Phase 5 contract (`BACKEND-NOTES.md`) and by FE Phase 4 D-09..D-14 (device-only toggles).

---

## Notification permission (NOTIF-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Hint row in Settings (recommended) | Row under the toggles whenever the OS permission is not granted; "Attiva" prompts or opens settings; Phase 7 adds the travel trigger | |
| Prompt when a toggle turns ON | Contextual, but defaults are ON | |
| Only Phase 7 | Phase 5 exposes `ensureRequested()` only; UAT uses a dev trigger | ✓ |

**User's choice:** Only Phase 7 — the first travel confirmation is the single prompt trigger.
**Notes:** Follow-up on the denied state and on the UAT below.

| Option (denied permission) | Description | Selected |
|--------|-------------|----------|
| Hint + open system settings (recommended) | Row in Settings only when denied; "Attiva" → `openAppSettings()`; no nagging | ✓ |
| Total silence | No UI at all | |
| Also an in-game notice | One-off banner when an event cannot be shown | |

| Option (UAT without a prompt) | Description | Selected |
|--------|-------------|----------|
| Manual grant from Android settings (recommended) | No code; nothing to strip in Phase 12 | ✓ |
| Dev-bypass-only trigger | Settings row prompts when `DEV_AUTH_ENABLED=true` | |

---

## Tap routing & context popups (NOTIF-06)

| Option (`travelEnd`/`questEnd`) | Description | Selected |
|--------|-------------|----------|
| Generic replaceable popup (recommended) | Parchment popup with title/body behind a per-type registry | |
| Map tab only, no popup | Phase 5 routes to the map; popups arrive with Phases 7/9 | ✓ |
| Real data now | Re-query GraphQL by `data.id` | |

| Option (`streamerLive` popup) | Description | Selected |
|--------|-------------|----------|
| Title and body + close (recommended) | Payload copy in a parchment sheet | |
| Add "Guarda la live" | Button opening the Twitch channel via `url_launcher` | ✓ (superseded below) |
| No popup | Only the notification/banner | |

| Option (tap behaviour per type, system notification and banner alike) | Description | Selected |
|--------|-------------|----------|
| Map tab; streamer live opens Twitch (recommended) | Personal types → Map; `streamerLive` → Twitch directly, no map, no popup; NOTIF-06 amended | ✓ |
| Always Map tab, then live popup | As NOTIF-06 was written | |
| Banner without tap, notification → Map | Banner informative only | |

**User's choice:** Map tab for personal types; `streamerLive` opens **`https://www.twitch.tv/lordreavor`** directly (URL provided by the user mid-discussion). The "Guarda la live" popup is therefore superseded.
**Notes:** NOTIF-06 and ROADMAP SC 4 amended with a dated note in this discuss.

| Option (channel URL source) | Description | Selected |
|--------|-------------|----------|
| `.env` `TWITCH_CHANNEL_URL` (recommended) | Read by `EnvConfig` | |
| Constant in `lib/config/` | Single channel by design; URL is not a secret | ✓ (URL typed by the user) |

---

## In-app banner (NOTIF-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Top strip, 5 s, tap navigates (recommended) | Thin parchment/ink overlay at the top, auto-dismiss, one at a time | ✓ (with per-type tap) |
| Bottom strip | Risks covering the satchel | |
| Persistent until dismissed | More visible, more invasive | |

**User's choice:** "Striscia in alto, 5 s, ma solo se necessario c'è la navigazione. Lo decideremo sulla base del tipo di notifica." → navigation on tap is per type (D-17).

---

## Registration lifecycle & logout (NOTIF-01)

| Option (unregister before `logout`) | Description | Selected |
|--------|-------------|----------|
| Hook in the auth services (recommended) | Additive `onBeforeLogout` callback in both services, inside the logout single-flight | |
| In `AuthCubit.logout()` | Cubit awaits `unregister()` (timeout) then calls the service | ✓ |
| No unregister | Rely on the backend token claim | |

**User's choice:** `AuthCubit.logout()` orchestrates unregister → logout.

---

## Firebase config files

| Option | Description | Selected |
|--------|-------------|----------|
| Out of the VCS (recommended) | `.gitignore`, provided locally; app boots without them | ✓ |
| Committed | Google treats them as non-secret | |

---

## Platform scope (iOS)

| Option | Description | Selected |
|--------|-------------|----------|
| iOS config yes, UAT deferred (recommended) | Info.plist/entitlements wired, iPhone verification pending | |
| Android only | No change under `ios/`; iOS in a later phase | ✓ |
| Full iOS with UAT | Apple account + APNs key available | |

---

## Legacy cleanup (Boy Scout)

| Option | Description | Selected |
|--------|-------------|----------|
| Remove both (recommended) | Drop `firebase_auth` from pubspec, delete `lib/utils/notification.dart` | ✓ |
| Only the legacy file | Keep `firebase_auth` | |
| Touch nothing | Separate `refactor/` PR | |

---

## Claude's Discretion

Names/folders, channel id and importance, banner animation, dedup windows, retry caps, `uuid` version, how the pending intent is provided, resume re-check of the permission status, hint-row copy, the shape of the popup hook for Phases 7/9, test layout.

## Deferred Ideas

iOS support (user decision), context popups for `travelEnd`/`questEnd` (Phases 7/9), streamer-live popup (superseded), server-side preferences, persisted dedup ledger, inbox/badges/pre-permission explainer, `combatResult` type (Phase 9).
