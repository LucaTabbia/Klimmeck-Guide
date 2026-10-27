---
phase: 08
slug: spells-section-journal-tab
audited: 2026-10-27
status: secured
asvs_level: 1
block_on: high
threats_total: 50
threats_mitigated: 44
threats_accepted: 5
threats_transferred: 1
threats_open: 0
threats_open_blocking: 0
threats_deferred: 0
open_ids: []
deferred_ids: []
updated: 2026-10-27
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

## Update 2026-10-27 - 08-12 outcome and extension 08-13/08-14

Read at HEAD `62fd38c` (later `7e34e8a`, a fixer test commit; the fixer edits to `journal.dart` and `shop_modal.dart` do not touch the threat surface). The six deferred threats of 08-12 are resolved and the extension threats T-8-41..T-8-50 are verified. No `.env` read, no BE repo touched. Targeted suite (`test/utils`, `test/shared/components`, `test/screens/mainScreen/tabs/journal`, `test/models/enums`): 348 tests; one run showed a transient red `journal_items_test.dart` "WR-01" case (the fixer's failing-test-first commit `7e34e8a` landing mid-audit); the same file re-run is 5/5 green.

### 1. Deferred threats of 08-12 (T-8-35..T-8-40) - resolved

| Threat | Cat. | Disp | Status | Evidence |
|--------|------|------|--------|----------|
| T-8-35 | DoS | M | CLOSED | BE gate passed first (`spellStates` on BE `origin/develop` `10e5f43`, PR #14, `08-12-SUMMARY.md`); `tool/schema_check` 34 OK vs that ref (SUMMARY, `08-VALIDATION.md` row 8-12-01); `character_fragment.dart:52-58` selects `spellStates { usages recoveries spell { id } }` (`test/graphql/character_fragment_test.dart`); device E2E 12/12 against the live BE confirms the stream works; parser stays tolerant (T-8-01). |
| T-8-36 | Tampering | M | CLOSED | SDL read equal to proposal A1/A2 before the edit (SUMMARY "BE gate"); `spell_state.dart:14-22` parses `spell.id`, `usages`, `recoveries`; handoff payload parse test in 08-VALIDATION; no semantic drift checkpoint raised. |
| T-8-37 | Info disc. | M | CLOSED | `grep -niE "token\|bearer\|twitchId\|MONGO_URI\|DEV_AUTH\|eyJ\|mongodb\|24-hex"` over `08-HUMAN-UAT.md`, `08-12-SUMMARY.md`, `BACKEND-NOTES.md`: every hit is prose ("no tokens in the transcript", "Nessun id utente, token o valore `.env`", "change stream MongoDB"); no values, no 24-hex ids, no JWTs. UAT notes line 30 states no user ids, Twitch ids, tokens or `.env` values. `.env` untracked (`git ls-files` shows only `.env.example`). |
| T-8-38 | Tampering | M | CLOSED | Device UAT step 11 "pass" (server offset drives the countdown, `08-HUMAN-UAT.md`), plus unit coverage T-8-10/T-8-19; `spell_state.dart:19` now `.toUtc()` (closes O-1). |
| T-8-39 | Repudiation | M | CLOSED | `REQUIREMENTS.md`: SPELL-01..07 `[x]` and traceability `Complete`; each maps to passed steps in the 08-12 SUMMARY table (all 12 pass). SPELL-08/09 correctly `[ ]` / `Pending` (extension, not yet device-proven). |
| T-8-40 | Tampering | M | CLOSED | BE read via `fetch`/`show` only (SUMMARY); `git diff 0bc37b8..HEAD --stat` shows no BE path (only the FE copy `BACKEND-NOTES.md`). |

Observation O-1 is resolved (`.toUtc()` in `SpellState.fromJson`).

### 2. Extension 08-13 (T-8-41..T-8-45)

| Threat | Cat. | Disp | Status | Evidence (file:line) | Test |
|--------|------|------|--------|----------------------|------|
| T-8-41 | DoS | M | CLOSED | `filter_values.dart:8-11` `found.whereType<T>()` drops nulls; `:20-30` reads `asset.item?.asEquipment?.equipType` / `item?.asLoot?.effect`; `shop_modal.dart` uses `e.item?.asEquipment?.equipType`; the old `e.item! as EquipmentItem` cast was removed (diff). Remaining `item!.id` at `shop_modal.dart:113,117,155,159` are pre-existing (not in the diff), see O-4. | `filter_values_test.dart` null cases |
| T-8-42 | Tampering | M | CLOSED | `spellbook_content.dart:51` slot row fed `spellbook.slots`; only `_entriesOf(filter)` (`:81-83`) filters known rows | `spellbook_content_test.dart` slot under filter |
| T-8-43 | Info disc. | A | CLOSED (accepted) | Selection is a widget field (`useTypeFilter` passed down, `setState` owner in `spells_section.dart`); grep `SharedPreferences` over journal, shop, `items_filter.dart`, `filter_values.dart` = 0; no GraphQL/repository change (see below). Logged below. | acceptance grep |
| T-8-44 | Spoofing | M | CLOSED | `items_filter.dart` reuses theme tokens (`KlimmeckGuideTheme.*`) and `CachedSvg`; grep `CircularProgress|Loader|showDialog|Skeleton|AppBar` over the new files = 0 | `items_filter_test.dart` |
| T-8-45 | Repudiation | A | CLOSED (accepted) | `spell_lines.dart:47-53` prefix is `useType?.label ?? 'Danno'`; presentational only, BE stays the source of truth. Logged below. | `spell_lines_test.dart` |

### 3. Extension 08-14 (T-8-46..T-8-50)

| Threat | Cat. | Disp | Status | Evidence (file:line) | Test |
|--------|------|------|--------|----------------------|------|
| T-8-46 | DoS | M | CLOSED | `journal.dart:227` `character.assets?.ownedItems ?? const <AssetQuantity>[]`; `:244-245` `if (owned.item case final item?)`; quantity passed nullable; grep `ownedItems!` = 0 | `journal_items_test.dart` (5 cases incl. empty list, vanished effect) |
| T-8-47 | DoS | M | CLOSED | `item_lines.dart:8-14` null effect -> `null`, null/0 power dropped; `item_row.dart:36,86` prints the line only when non-null | `item_lines_test.dart`, `item_row_test.dart` |
| T-8-48 | Info disc. | A | CLOSED (accepted) | `_selectedEffect` is a `State` field (`journal.dart:228`), never persisted nor sent; grep `SharedPreferences` = 0. Logged below. | acceptance grep |
| T-8-49 | Spoofing | M | CLOSED | shared `ItemsFilter` + theme tokens; no chrome/loader widgets in `journal.dart` items section (grep) | `items_filter_test.dart` |
| T-8-50 | Repudiation | A | CLOSED (accepted) | `effect_type.dart` `label` is a fixed Italian constant; `item_lines.dart` header "Copy provvisoria (D-19)"; BE stays the source of truth. Logged below. | `effect_type_test.dart` |

Cross-cutting checks for the extension:

- No data-path change: `git diff 36fd7c8..HEAD --stat` lists no file under `lib/graphql`, `lib/repository`, `lib/services` or `lib/network`; the filters are pure view state, no network or GraphQL document change.
- Enum parsing unchanged: the `effect_type.dart` diff only adds a `label` constant per value; `imageId` and `imagePath` (via `CloudinaryAssets.url`) are unchanged, parsing by name untouched. Chips use `imagePath` only: no new asset or URL.
- Rendering: BE strings are not interpolated into anything executable; the new copy is `'${effect.label}: $power'` (fixed label plus an `int`) and `'$prefix: ${type.label} $power'`; no URI, launch, HTML or format sink.
- Logging: no `print`/`debugPrint` in any new file (grep). The two pre-existing `debugPrint` of O-2 are unchanged.
- Null-safety: no new `!` on BE data in the audited new code (grep; only pre-existing `shop_modal.dart` `item!.id`).
- DoS by chips: `presentFilterValues` returns a subset of `T.values` (`EffectType` 5, `UseType` and `EquipType` enum-sized), so chip count is bounded by the enum size.

### Accepted Risks Log (added)

| Threat | Risk | Rationale |
|--------|------|-----------|
| T-8-43 | filter selection state | In-memory only, never persisted or sent, no PII (D-22). |
| T-8-45 | spell use-type copy may differ from BE logic | Presentational; BE is source of truth (CLAUDE.md rule 4); `Danno` fallback when `useType` is null. |
| T-8-48 | items filter selection state | In-memory only, never persisted or sent (D-28). |
| T-8-50 | item effect copy may differ from BE logic | Presentational; BE is source of truth. |

### Unregistered Flags (update)

None. `08-12`, `08-13` and `08-14` SUMMARY threat sections report no new surface or map to registered ids.

### Observations (added, no threat id)

- O-4: `shop_modal.dart:113,117,155,159` keep `item!.id` on rows of the shop lists. Pre-existing, outside the 08-13 register (the extension removed a `!` there, it added none); a partial payload with a null `item` would crash the shop list only. Optional hardening in a later phase.
- O-5: `EffectType.none` renders «Nessun effetto» as a line and chip (review IN-02); copy only, no security impact.
- O-6: reviewer WR-01/WR-02 (state written in build path, stale shop selection) are correctness items handled by the fixer; neither changes a threat disposition.

### Audit Trail (added)

| Date | Event |
|------|-------|
| 2026-10-27 | Update at HEAD `62fd38c`/`7e34e8a`: T-8-35..T-8-40 CLOSED (08-12 executed, device UAT 12/12, schema_check 34 OK); T-8-41..T-8-50 verified (6 mitigate, 4 accept), all CLOSED. Totals 50 threats: 44 mitigated, 5 accepted, 1 transferred, 0 open, 0 deferred. Status `secured`. |
