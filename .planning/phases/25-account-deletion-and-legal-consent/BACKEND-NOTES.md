# Phase 25 — Backend notes (handoff to BE Phase 26)

Authoritative decisions: `25-CONTEXT.md` (D-01..D-16). Names below are proposals: the BE fixes the contract in its own handoff and the FE aligns before selecting anything.

## What the app needs

1. **Own account deletion** — an authenticated mutation with no argument (the caller is the target). On success every session of the user is revoked at once; the app does its local teardown and shows the login with «Il tuo account è stato eliminato.» (D-03). Refused for the innkeeper role with its own error code (D-16).
2. **Deletion by the innkeeper** — a mutation reserved to the innkeeper taking a Twitch **username**; the BE resolves it to the Twitch ID and runs the same deletion, written in the admin audit log (D-15). Error codes the app must tell apart: unknown Twitch username, no account for that Twitch user, target is an innkeeper (D-16), Twitch lookup unavailable.
3. **Revocation reason** — a player deleted by the innkeeper while online should land on the login with the D-03 notice: the app needs to tell «account deleted» from the other revocation reasons (today: session expired, replaced by new login, role changed, channel access lost). If that is not feasible, say so: the fallback is the session-expired notice.
4. **Consent at login** — the login carries the accepted version of the documents (one string constant of the app, D-12); the BE stores version and date on the user and refuses a login without it with its own error code (D-09). Question for the BE: at which step of the Twitch flow (login start, ticket exchange) the version travels, and how the dev bypass (`DEV_AUTH_*`) carries it.
5. **Anonymous placeholder** — in a started group quest the seat of a deleted character stays until the conclusion with no character behind it (D-13). The app needs a registration it can draw without name and portrait (a null character with the seat still there, or an explicit flag): declare the shape, and whether it is a non-additive SDL change.

## What is deleted (BE side, from the legal pages)

User (Twitch ID, points), all characters including archived, quest results and anything keyed by the user or his characters, sessions and login tickets, push devices, portrait on Cloudinary. Stay to their TTL: admin audit log (90 days), EventSub message log (7 days), backups (30 days). No trace of the Twitch ID is kept: the same account logs in again from zero (D-04).

## Not needed

No endpoint serving the current document version, no re-acceptance flow, no migration of existing users (D-11: the app is not published).
