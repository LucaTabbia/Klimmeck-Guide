# Phase 22: Companion Defeat, Rest and Recovery - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-14
**Phase:** 22-companion-defeat-rest-and-recovery (joint with BE Phase 23)
**Areas discussed:** Recovery times, Potions on the companion, What the player sees, Fights in sequence and travel, Companion name (added by the user)

## Recovery times
| Question | Options | User's choice |
|---|---|---|
| Source of the full recovery time | DB field per pet (rec.) / by rarity only / formula from maxXp | «Come risposta 1, ma tieni in considerazione anche la quantità di vita massima» |
| Defeat vs rest clock | Same clock (rec.) / slower after a defeat / fixed wait then full | «Come risposta 1, ma il compagno non è mai a vita 0, il minimo è 1 (non può morire un pet)» |
| Who recovers | Every unequipped companion (rec.) / only those put to rest / one at a time | Every unequipped companion |

## Potions on the companion
| Question | Options | User's choice |
|---|---|---|
| Wait | One per companion (rec.) / one shared / character apart, companions together | One per companion |
| Potion on a defeated companion | Yes, shortens (rec.) / No, only time | No, only time |
| Targets | Equipped and resting (rec.) / only equipped / only resting | Equipped and resting |
| Gesture | From the potion sheet (rec.) / from the companion parchment / both | From the potion sheet |

## What the player sees
| Question | Options | User's choice |
|---|---|---|
| Life in the Journal | Text + countdown (rec.) / text with life rising live / bar | Text with life rising live |
| Result sheet | Life always + defeat line (rec.) / only the defeat | Life always + defeat line |
| Push | Only a defeated one back in strength (rec.) / everyone / none | Only a defeated one back in strength |

## Fights in sequence and travel
| Question | Options | User's choice |
|---|---|---|
| Dungeon | Out of the following floors (rec.) / back each floor at 1 | Out of the following floors |
| Mount defeated in an ambush | Travel unchanged (rec.) / rest of the travel on foot | Free text: on foot + push for every ambush + parchments at Map opening mid-travel + redirection to the nearest city when the food no longer suffices |
| Confirmation of the travel rule (4 points) | Yes / quest kept / push only when the companion falls | «Sì, tutto giusto» |
| Innkeeper | Proposal + correction (rec.) / simulation as is / companions untouched | Proposal + correction |

**Notes:** verified in the BE before the confirmation that food depends on the duration (1 power / 3 minutes), so a slower travel needs more food.

## Companion name (user message mid-discuss)
| Question | Options | User's choice |
|---|---|---|
| Rename | Yes, from the Journal (rec.) / only if skipped / only at acquisition | Yes, from the Journal |
| Wording | Name in sentences, species on the parchment (rec.) / name everywhere / name and species always | Name in sentences, species on the parchment |
| Checks | Same rules as the character name (rec.) / length and characters only | Same rules as the character name |

## Claude's Discretion
Wire shape, lazy vs sweep recovery, push scheduling, rename gesture, prompt placement, final copy.

## Deferred Ideas
Companion portrait on the Profile; push for hurt companions at the end of the rest.
