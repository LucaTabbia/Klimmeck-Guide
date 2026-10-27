---
phase: 08
slug: spells-section-journal-tab
audited: 2026-10-27
status: secured_with_deferred
asvs_level: 1
block_on: high
threats_total: 40
threats_mitigated: 33
threats_accepted: 0
threats_transferred: 1
threats_open: 0
threats_open_blocking: 0
threats_deferred: 6
open_ids: []
deferred_ids: [T-8-35, T-8-36, T-8-37, T-8-38, T-8-39, T-8-40]
---

# Phase 08 - Security (Spells Section, Journal Tab, FE)

Audit of the `<threat_model>` blocks of plans 08-01..08-12 against HEAD `bc4b99e` of `feat/08-spells-section-journal-tab` (phase diff `0bc37b8..HEAD`, review fixes WR-01, WR-02, IN-01, IN-02 included). Evidence is the final code. Plan 08-12 (fragment `spellStates`, schema check, device UAT, closure) is deliberately not executed: it is gated by the merge of the BE Phase 9.1 PR (CONTEXT D-03). Its six threats are DEFERRED and are not counted as open.

Runs of this audit: targeted suite (`test/models/spell`, `equip_spell_request`, `test/models/character`, `spell_equip_failure`, `spells_repository`, `graphql_spells`, `test/graphql`, `test/tool`, `spell_outcome_listener`, `test/screens/mainScreen/tabs/journal`, `authenticated_shell`, `test/shared/components`, `spell_lines`) = 507 passed, 0 failed. `flutter analyze` was not re-run (baseline 53 issues, 0 errors per the repo rules). `.env` is untracked (`git ls-files` lists only `.env.example`); no command of this audit read it. BE repo not touched.

Disposition: M = mitigate (verified in code + test), T = transfer (BE, documented below).

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| BE `character`/`characterUpdated` -> `CharacterStatus` | `spellStates` may be absent, partial or malformed; each entry is parsed tolerantly and a bad one is dropped (`spell_state.dart:24-31`, `character_status.dart` `_spellStatesFrom`). |
| client -> GraphQL `equipSpell`/`unequipSpell` | Only the session character id and a catalog spell id are sent, as the typed `request` variable. The BE judges (slots, ownership, known spell). The mutation answer yields only a `bool`. |
| BE error payload -> domain failure -> banner | Classified by `extensions.code` only, `unknown` default; the banner shows fixed Italian copy, never server text. |
| user taps -> optimistic overlay -> BE | The overlay is UI only; it settles on `characterUpdated`, failure or the 15 s timeout. One mutation in flight, FIFO in tap order. |
| device clock -> countdown | Countdown is `recoveries[0] - serverNow` on `ServerClockService.now()`; uses are never incremented locally. |
| session lifetime -> cubit lifetime | `SpellsCubit` is provided by `AuthenticatedShell` (`authenticated_shell.dart` provider list) and closed at logout; `SpellRecoveryCubit` is created by the section and closed with it. |
| FE documents <-> BE schema | NOT audited here: DEFERRED to 08-12 (gate on BE 9.1). |

## Threat Verification

| Threat | Cat. | Component | Disp | Status | Evidence (file:line) | Test |
|--------|------|-----------|------|--------|----------------------|------|
| T-8-01 | DoS | `CharacterStatus.fromJson` | M | CLOSED | `spell_state.dart:24-31` `tryFromJson` (non-map -> null, `on Object` -> null); `character_status.dart` `_spellStatesFrom` (non-list -> null, entries via `tryFromJson` + `whereType`) | `character_status_test.dart:86` group `spellStates`; `spell_state_test.dart:66` group `tryFromJson` |
| T-8-02 | Tampering | recovery instants | M | CLOSED | `spell_state.dart:15-20` `DateTime.parse` then `..sort()`; `spell_recovery_status.dart:68` takes the minimum anyway, so order cannot mislead. See Observation O-1 (non-`Z` strings) | `spell_state_test.dart:8` UTC parse, unsorted case |
| T-8-03 | Tampering | `EquipSpellRequest` | M | CLOSED | `equip_spell_request.dart:14` `toJson` = `{id, spellId}`, no `usages` field | `equip_spell_request_test.dart` (key absent) |
| T-8-04 | Tampering | `KlimmeckGraphQl.equipSpell` | M | CLOSED | `graphql.dart` `_spellSlotMutation`: returns only `result['successful']`, non-bool -> `FormatException`; no state built from `CommonResponse` | `graphql_spells_test.dart` |
| T-8-05 | Info disc. | `spellEquipFailureFrom` | M | CLOSED | `spell_equip_failure.dart:51-67` switch on `graphQlErrorCode` only, `_ => unknown`; `toString` prints enum name (`:47`); no `.message` use in any spell file (grep) | `spell_equip_failure_test.dart:49` "ignores the message text and relies on the code only" |
| T-8-06 | DoS | `SpellsRepository` | M | CLOSED | `spells_repository.dart:18,48` 15 s `timeout` -> `timedOut`; `:49-55` every error -> `SpellEquipException`; `:41-43` `successful: false` -> `declined` | `spells_repository_test.dart` (fake_async) |
| T-8-07 | EoP | equip on another character | T | CLOSED | Owner check is BE `@OwnsCharacter` -> `FORBIDDEN` (`spell_equip_failure.dart:62` maps it to `forbidden`); the cubit sends only the loaded character id (`spells_cubit.dart:59-61` `character.id`) | `spell_equip_failure_test.dart` FORBIDDEN |
| T-8-08 | DoS | `SpellCard` | M | CLOSED | `spell_card.dart:70-77` optional fields guarded (`usages != null`, `isMarked != null`) before the only `!`; power/icons omitted when absent | `spell_card_test.dart` (missing/zero power, no bookmark) |
| T-8-09 | Tampering | equipment ribbon refactor | M | CLOSED | `bookmark_ribbon.dart` shared by `equipment_item_card.dart`, `equipment_info_sheet.dart`, `spell_card.dart` | `bookmark_ribbon_test.dart`, `equipment_item_card_test.dart`, `equipment_info_sheet_test.dart` (suite green) |
| T-8-10 | Tampering | `spellRecoveryStatusOf` | M | CLOSED | `spell_recovery_status.dart:59-74` only `next.difference(serverNow)`; `<= 0` -> `Arriving`; no usages arithmetic; no `DateTime.now` in `lib/models/spell`, journal tab, `spells_repository.dart` (grep = 0) | `spell_recovery_status_test.dart` Arriving cases |
| T-8-11 | Info disc. | `spell_lines.dart` | M | CLOSED | `spell_lines.dart` + `game_duration_format.dart` render formatted durations and fixed Italian copy; no ids | `spell_lines_test.dart`, `spell_info_test.dart` |
| T-8-12 | DoS | `Spellbook.of` | M | CLOSED | `spellbook.dart:78` `slotCount = max(0, maxActiveSpells ?? 0)`; `:93` `index >= active.length` -> empty slot; null `ActiveSpell.spell` skipped in `_serverActiveById` | `spellbook_test.dart:79,103` join/overflow cases |
| T-8-13 | Tampering | `intentFor` | M | CLOSED | `spellbook.dart:146-156` pending -> `ignoredPending`; full -> `blockedSlotsFull` on the optimistic count; BE still judges (`slotsFull` code mapped) | `spellbook_test.dart` intent/pending cases (`:198-265`) |
| T-8-14 | Tampering | slot thresholds | M | CLOSED | `spellbook.dart:78` slot count only from `maxActiveSpells`; no title/xp read (grep of `spellbook.dart` for `title`/`xp` = none) | `spellbook_test.dart:57-79` slot count cases |
| T-8-15 | DoS | `SpellsCubit` pending | M | CLOSED | `spells_cubit.dart:101-104` one `settleTimeout` timer per op, token-guarded (`:162,:181`); `:87-96` `close()` cancels timers, clears tokens/queue | `spells_cubit_test.dart:417,440,601` |
| T-8-16 | Tampering | overlay vs truth | M | CLOSED | `spells_cubit.dart:149-157` success only waits (`_succeeded`) or matches the synced character; no response data read (`SpellsRepository` returns `void`); `:161-168` unmatched success closes as `settledByTimeout` (silent realign, D-17) | `spells_cubit_test.dart:309,326,440,464` |
| T-8-17 | Tampering | rapid taps | M | CLOSED | `spells_cubit.dart:66-68` `ignoredPending` never calls the BE; `:44-47,118-127` one mutation at a time, FIFO (WR-02); `:136` a closed op in the queue is never sent | `spells_cubit_test.dart:506-600` (WR-02 group, incl. 577 and 589) |
| T-8-18 | Spoofing | cubit after logout | M | CLOSED | `spells_cubit.dart:10,17` `SafeEmit`; `close()` clears tokens; provided in the shell | `spells_cubit_test.dart:356,601`; `authenticated_shell_test.dart:236-251` closed on removal |
| T-8-19 | Tampering | countdown / device clock | M | CLOSED | `spell_recovery_cubit.dart:54` `_clock.now()` (server offset), `:23` re-derive on `offsetChanges` | `spell_recovery_cubit_test.dart:222` offset change; server-clock service tests (Phase 7). Device step: see T-8-38 |
| T-8-20 | DoS | ticker | M | CLOSED | `spell_recovery_cubit.dart:60-63` periodic timer only while a countdown exists; `:71-76` `close()` cancels timer and subscription | `spell_recovery_cubit_test.dart:148,198,255` |
| T-8-21 | Tampering | arriving state | M | CLOSED | `spell_recovery_status.dart:70` Arriving only changes the label; cubit exposes statuses, never usages | `spell_recovery_status_test.dart`; `spell_recovery_cubit_test.dart:179,237` |
| T-8-22 | DoS | `SpellInfo` | M | CLOSED | `spell_info.dart` no `!.` reads (grep = 0); every line optional | `spell_info_test.dart:86` partial catalog |
| T-8-23 | Tampering | sheet toggle on stale state | M | CLOSED | `spells_section.dart:22-27,120` sheet and rows share `toggleSpellWithFeedback`, decision stays in `SpellsCubit.toggle` | `spell_info_sheet_test.dart`, `journal_spells_test.dart`, `spells_section_test.dart` |
| T-8-24 | Tampering | presentational widgets | M | CLOSED | `known_spell_row.dart:11`, `spell_slot_row.dart:10`, `spellbook_content.dart:12`, `spell_card.dart:11` are `StatelessWidget`; only `SpellResist` is stateful (shake animation) | `known_spell_row_test.dart`, `spell_slot_row_test.dart`, `spell_card_test.dart` pending tokens |
| T-8-25 | DoS | slot row | M | CLOSED | boxes = `spellbook.slots.length` (bounded, `spellbook.dart:109`); `spell_slot_row.dart` uses `Wrap` | `spell_slot_row_test.dart`, `spellbook_test.dart:79,103` |
| T-8-26 | Tampering | stale view after rejection | M | CLOSED | `spell_outcome_listener.dart:19-26,49-53,67-72` silent `refreshCharacter()` on alreadyActive, notActive, notKnown, slotsFull, notFound (+ timedOut and settledByTimeout); no loader | `spell_outcome_listener_test.dart:123,146,175,194` |
| T-8-27 | Info disc. | banner | M | CLOSED | `spell_notice.dart:14-47` maps the domain enum to fixed copy, no `.message`, no code tokens; no `print`/log of payloads in any spell file (grep) | `spell_notice_test.dart`; `spell_outcome_listener_test.dart:160` |
| T-8-28 | Spoofing | banner on `UNAUTHENTICATED` | M | CLOSED | `spell_notice.dart:40` `unauthenticated -> null`; not in `_staleViewFailures` so no refresh (D-17: the session flow acts) | `spell_outcome_listener_test.dart:240` "nothing at all"; `spell_notice_test.dart:80` |
| T-8-29 | DoS | banner flood | M | CLOSED | `spell_outcome_listener.dart:59-64` `publishNotice` with `dedupKey` `spell|kind|failure|spellId` | `spell_outcome_listener_test.dart:136,168` dedupKey assertions |
| T-8-30 | EoP/session | cubit outliving session | M | CLOSED | `authenticated_shell.dart` `BlocProvider<SpellsCubit>` inside the shell (closed on removal) | `authenticated_shell_test.dart:236-251` |
| T-8-31 | Tampering | haptics on stale state | M | CLOSED | `spells_section.dart:22-32` haptic chosen from the intent returned by `SpellsCubit.toggle`; ignored/unknown -> none | `spells_section_test.dart:208` group `taps and haptics` |
| T-8-32 | DoS | ticker after leaving Journal | M | CLOSED | `spells_section.dart:55-57` `BlocProvider(create:)` closes the cubit with the section | `spells_section_test.dart` unmount; `spell_recovery_cubit_test.dart:255` |
| T-8-33 | DoS | Journal page `!` crashes | M | CLOSED | `journal.dart`: spell code extracted to `spells_section.dart`; remaining `!` in `journal.dart` are equipment/inventory paths (pre-existing, outside the register); spell section renders from `Spellbook` | `journal_spells_test.dart`, `spells_section_test.dart` |
| T-8-34 | Spoofing | gameplay chrome | M | CLOSED | grep for `CircularProgress`, `Loader`, `showDialog`, `Skeleton` over the new spell/journal files = 0 matches; optimistic look only | `spells_section_test.dart`, `spellbook_content_test.dart` |

## Deferred to Plan 08-12 (gated by the BE 9.1 PR, CONTEXT D-03)

DEFERRED (08-12, gated by the BE 9.1 PR). Not counted as OPEN, not blocking.

| Threat | Cat. | Component | Disp | Status | What closes it |
|--------|------|-----------|------|--------|----------------|
| T-8-35 | DoS | `CharacterFragment` (`spellStates`) | M | DEFERRED | BE gate first step; `tool/schema_check` 34/34 against `origin/develop` before any device run. Interim state: the fragment is not yet extended (`character_fragment.dart` untouched), so no FE document requests a field the BE may lack; the parser already tolerates absence (T-8-01). |
| T-8-36 | Tampering | `SpellState.fromJson` contract drift | M | DEFERRED | Handoff + generated SDL read before the fragment edit; parser aligned under TDD. |
| T-8-37 | Info disc. | E2E session | M | DEFERRED | No command reads `.env`; UAT notes without ids/tokens (to be verified when 08-12 runs). |
| T-8-38 | Tampering | countdown, device clock (E2E) | M | DEFERRED | Device UAT step 11; unit coverage already CLOSED under T-8-10/T-8-19. |
| T-8-39 | Repudiation | REQUIREMENTS traceability | M | DEFERRED | Ticks only for steps passed in `08-HUMAN-UAT.md`. |
| T-8-40 | Tampering | BE working tree | M | DEFERRED | BE accessed only via `fetch`/`show`. Observed in this audit: BE repo untouched (no BE path in `git diff 0bc37b8..HEAD`). |

## Accepted Risks Log

None. No threat of Phase 8 carries the `accept` disposition. Phase 7 accepted risks are not extended by Phase 8.

## Transferred Risks

| Threat | Transferred to | Documentation |
|--------|----------------|---------------|
| T-8-07 | BE `@OwnsCharacter` (`FORBIDDEN`), BE Phase 4 handoff | `BACKEND-NOTES.md`; FE sends only the session character id and maps `FORBIDDEN` to `forbidden` (fixed copy: "Questo personaggio non può farlo") |

## Unregistered Flags

None. The `## Threat Flags` of the eleven `08-NN-SUMMARY.md` (08-01..08-11) report "None" (no new network surface) or map to registered ids (T-8-15..T-8-18, T-8-26..T-8-34).

## Observations (no threat id)

- O-1: `SpellState.fromJson` uses `DateTime.parse`; an ISO string without `Z`/offset would yield a local-time instant. The BE contract is ISO `Z`; the countdown compares instants against `serverNow`, so a mismatch would only skew by the zone offset. Consider `.toUtc()` at parse when 08-12 aligns the parser to the generated SDL.
- O-2: `journal.dart:354,362` keep two `debugPrint` calls in the equipment equip path; pre-existing, no spell payloads.
- O-3: the stale-view set also includes `notKnown`, `notFound` and `timedOut` (banner plus silent re-read), a superset of the five codes of the plan; consistent with D-17 and tested (`spell_outcome_listener_test.dart:146,160,175`).

## Audit Trail

| Date | Event |
|------|-------|
| 2026-10-27 | Audit of plans 08-01..08-11 at HEAD `bc4b99e`: 34 threats verified (33 mitigate, 1 transfer), all CLOSED; 6 threats of 08-12 DEFERRED; 507 targeted tests green; no unregistered flags. |
