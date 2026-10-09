---
status: passed
phase: 02-character-creation
source: [02-11-PLAN.md Task 2]
started: 2026-10-09
updated: 2026-10-09T12:00:00Z
---

# Phase 2 — Manual UAT (dev end-to-end)

Prerequisites: BE on branch `feat/02.1-character-creation-contract` on :3000 with Cloudinary keys; app `.env` with `DEV_AUTH_ENABLED=true` and matching `DEV_AUTH_ACCESS_TOKEN`; dev user with `currentCharacter: null`. Record outcomes only (no tokens, no `.env` values, no signed URLs).

## Tests

### 1. Cold start lands on the sheet
expected: after the splash the "Il tuo personaggio" sheet appears, not the shell.
result: pass (approvato dall'utente, 2026-10-09)

### 2. Empty sheet
expected: "Crea" disabled; the age field says "Scegli prima la razza".
result: pass (approvato dall'utente, 2026-10-09)

### 3. Name validation
expected: "A" -> "Il nome deve avere almeno 2 lettere"; "Aria2" -> "Solo lettere, spazi, apostrofi e trattini"; "Aria" clears the error.
result: pass (approvato dall'utente, 2026-10-09)

### 4. Age range per race
expected: Elfo + 30 -> "Per la razza Elfo l'eta va da 100 a 9999 anni"; switching to Umano clears the error and keeps 30.
result: pass (approvato dall'utente, 2026-10-09)

### 5. Portrait pick and remove
expected: "Galleria" -> preview replaces the silhouette; "Rimuovi" restores it; pick again.
result: pass (approvato dall'utente, 2026-10-09)

### 6. Create with portrait
expected: choose sex, pronoun, class (+ optional story); "Crea" shows progress only on the button; the shell opens directly and the profile shows "Aria" with the portrait.
result: pass (approvato dall'utente, 2026-10-09)

### 7. Duplicate name and create without portrait
expected: after clearing `currentCharacter` and deleting the character in Mongo and restarting, an existing name gives "Nome gia in uso" with all fields kept; a new name without portrait enters the shell with the silhouette wherever the portrait appears.
result: pass (approvato dall'utente, 2026-10-09)

### 8. Esci
expected: "Esci" -> "Sei sicuro di voler uscire?" -> "Esci" -> sign-in screen.
result: pass (approvato dall'utente, 2026-10-09)

### 9. Camera and permission denial (optional, real device)
expected: "Fotocamera" path works; permission denial shows the domain message.
result: skipped (optional, real device; not run)

## Summary

total: 9
passed: 8
issues: 0
pending: 0
skipped: 1
blocked: 0

## Gaps
