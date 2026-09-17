# ASTRA CHANGELOG

## 0.1.0 — First Vertical Slice
- Added INCIDENT ARCHIVE campaign-style title screen.
- Added sequential incident unlocks: Dead Air → Glass Garden → Echo Ward.
- Added replay access for cleared incidents.
- Added per-case completion status and best CASE THEORY score display.
- Added three Investigator Protocols: ANALYST, EMPATH, AUDITOR.
- Upgraded Archive persistence to save v4 with per-case best theory records.
- Added explicit post-case progression and next-incident guidance.
- Added `docs/VERTICAL_SLICE_010.md`.
- Added vertical-slice CI covering campaign unlock rules and initialization of all three incident templates.
- Added `main_v010.gd` / `main_v010.tscn` as the 0.1.0 entry point.

## 0.0.9 — Case Analysis
- Added two-suspect CASE THEORY submission before each isolation vote.
- Added final deduction grading (0–100) and S/A/B/C/Fragmented labels.
- Added evidence-support / contradiction / confidence calibration to theory review.
- Added cinematic Incident Stage cards for all three cases.
- Expanded private character scenes from two choices to three.
- Added persistent theory statistics to Archive save v3.
- Added CI smoke test covering state setup, investigation, and theory submission.

## 0.0.8
- Player-authored hypothesis links.
- Echo Ward case.
- Personal events and feedback FX.
- Godot 4.7.2 CI.
