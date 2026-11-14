# Phase 22 — deferred items (out of scope, not fixed)

- **Shop coin satchel overflows in widget tests (found in 22-12).** With a character that has coins, `CoinsDisplay` inside the shop's satchel (`shop.dart` `_buildCoinsDisplay`, column layout, `coins_display.dart:121`) overflows by 6 px on the 780x360 test surface with the test font (sizes scale with the screen height, the text does not). Pre-existing: no earlier shop test gave the character coins. The 22-12 purchase-prompt tests pump the shop on a 780x480 surface instead. Not seen on the device so far.
