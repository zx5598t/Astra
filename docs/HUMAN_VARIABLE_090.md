# HUMAN VARIABLE implementation record

## Compatibility and ownership

Snapshot v4 and meta save v12 remain unchanged. `AstraExplorerCatalog` normalizes optional `explorer_id` and `art_id`; `preset` remains the legacy alias. Missing or invalid identity becomes neutral, preserving name and valid pixel preset. New profiles select one of six authored identities. Stage-local meeting arcs and introduction history live in `flags.stage_080`. Identity never consumes generator RNG, changes roles/evidence, or grants a mechanical advantage.

## Identity and artwork

Six biographies, motivations, selection lines, openings and four question intents each are authored in `explorer_catalog.gd`, plus a first-contact exchange for all 48 explorer×crew pairs (19 tagged relationship tones; tagged pairs appear in Stages 1–2 and every third Stage after, the rest rotate) and each explorer's wording for all nine meeting moves.

Art comes only from the owner's drawings. An earlier draft of this version shipped generated portraits and bound the explorers to the temporary p1–p6 walking sheets (Serin was p2, etc.); both were wrong and are gone. Mapping now: `serin` → `serin_a` … `sia` → `sia_a`, built from `미니 도트 캐릭/<이름>.png` (4×4 walk), `<이름>1.png` (walk with tool) and `<이름>2.png` (poses) by `tools/import_pixel_090.gd`; full figures from `플레이어/<이름>.png` and four expression busts + a head from the 3×2 sheets `플레이어/ChatGPT 이미지 … 05_41_43-1 … 05_41_46-4.png` (order 라엘 로건 미카 / 세린 시아 제이스) by `tools/import_explorers_090.gd`. Legacy p1–p6 remain for old saves only.

## Motion

`tools/import_pixel_090.gd` replaces the 0.8 importer. Frames are 128×128 (was 96×128; long hair and coats were clipped). Explorers walk on four drawn frames per direction; three explorer sheets drew both side rows facing right, so left is mirrored. 176 pose cells (8 crew from two action sheets each, 6 explorers from one) are scaled to the walking figure (75% standing height, 25% head width), feet-anchored, effects outside the body removed; 0 clipped frames, walk head-top jitter ≤ 4 px. `루칸1.png` (Soren) and `소렌2.png` (Lucan) are mapped by drawing. `pixel_actor.gd` plays drawn poses with one-pixel dips in and out, push-off and settle around walks, a pass-through frame when turning round, talking gestures and listening poses; walking stays distance-driven and pixel-snapped. Details: `docs/PIXEL_ACTIONS_090.md`.

## Meetings

Each generated thread creates an argument record with its public source, subject, player response and closure. The player can perform up to three public-source checks per Day, at most one for each argument, independently of the existing one decisive action (two with EMPATH). A check replays a reachable public statement, obtains a subject response and a listener's public-knowledge interpretation. Retracted false sightings are explicitly labelled as retracted. These checks do not manufacture new facts or silently change suspicion scores. Decisive interventions retain the existing Knowledge/DecisionTrace effects. Spending the strong budget no longer automatically skips the remaining meeting windows. Final statements recall player defense or a checked argument.

Shared resistance vocabulary permits qualified concession, limited admission and demands for corroboration for both innocents and Nulls. No line is a role detector. Existing evidence curves, lies, refutation rules and balance gates are unchanged.

## Interludes

Five mechanic families: frequency+phase tuning, safe power bypass, ordered logs with a conclusion, two-sample comparison, and route planning within a round-trip budget. The existing authored schedule already separates these families across consecutive interludes, so no random scheduler was added. All randomness is seed-derived. Partial/skip paths still call the existing story-first completion contract and preserve evidence. No reflex timer is required.

## Story edits

Eight new first-contact callbacks; no new canon event, chapter or ending. Three morning ambience variants now use environmental traces instead of assuming a named crew member is alive. The duplicated Stage ending/next-hook beat was consolidated to the next hook. New explorer questions are authored in their own catalog; no UI-authored story data or new deduction manager was introduced.

## Verification artifacts

The shared `tests/ci_suite.txt` includes `human_variable_090_tests.gd`. `visual_human_090.gd` captures all six selection states and, for each of the fourteen people, every walk frame, band motion, transition and drawn pose at 1366×768 and 1920×1080. `visual_interludes_080.gd` captures the playable scene/task views. `walkthrough_080.gd` includes two explorer runs through Stages 1, 2, 3 and 5 with argument/check diagnostics. `agency_082_tests.gd` prints Stage 2–4 paired outcomes, days, innocent isolations, casualties and attributable public/meeting/vote changes. Actual results belong in QA_REPORT.md; passing scripted tests does not measure subjective readability or fun.
