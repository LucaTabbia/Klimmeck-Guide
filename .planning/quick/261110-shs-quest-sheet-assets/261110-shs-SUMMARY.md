---
quick: 261110-shs
title: Quest sheets re-uploaded on Cloudinary and torn heal sheets
date: 2026-11-10
branch: feat/18-heal-quests-by-size
commits: [a27f2f0, 9c0b175]
status: complete
---

# Quick task 261110-shs — quest sheet assets

**Trigger (user, 2026-11-10):** «Ho rivisto gli asset dei fogli quest. Quelli aggiornati sono già su Cloudinary», then the nine links and «Le due nuove servono per le quest heal».

**Finding:** the Cloudinary ids carry a version and a random suffix, so a re-uploaded file gets a new id. A `curl -sI` on the eighteen quest sheet ids of `lib/config/cloudinary_assets.dart` showed seven of them answering 404: `questSheetTorn1/2`, `storyTornSheet1/2`, `huntTornSheet1/2` and `crimeSheet2`. Every torn sheet and half of the crime sheets would not load on any build.

**Change:**

- `lib/config/cloudinary_assets.dart`: the seven constants point to the new files (names of the constants unchanged); two new constants `announcementTornSheet1` / `announcementTornSheet2`.
- `lib/models/quest/quest_paper_asset.dart`: a torn heal (Phase 18 D-20, heal with no effect or held in the viewer's lane) uses the torn announcement sheets instead of borrowing the generic torn quest sheets. Study keeps no torn variant.
- `test/models/quest/quest_paper_asset_test.dart`: the nine ids pinned, the torn heal mapping, study among the never-torn families.

**TDD:** RED `a27f2f0` (compile failure: the two constants did not exist), GREEN `9c0b175`.

**Gates:** the nine new URLs answer 200; full suite 3914 tests green; analyzer 47 info / 0 error / 0 warning; `tool/hardening_check.sh` OK; no old id left in `lib/` or `test/`.

**Note:** the fix lives on the Phase 18 branch because the torn heal mapping exists only there. `develop` keeps the seven dead ids until this branch is merged: if the torn sheets are needed before, cherry-pick the constants of `9c0b175` on a `fix/` branch from `develop`.
