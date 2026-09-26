# ASTRA — Guide for code agents and contributors

## Current target
- Version **1.1.0 — LIVING PATHS**. Engine: **Godot 4.7.2 stable**, GL Compatibility renderer.
- 1.1 keeps the 1.0.1 deduction/fairness contract and adds reconverging player-chosen routes, existing consequence delivery, replay variation and history-sensitive finale reception.
- One Stage = one game; a Day = Morning → Conversation → Meeting → Vote → Night. PART I (Stages 1–4) one Null,
  PART II (Stage 5+) two Nulls and one protocol (GUARDIAN 5 / ANALYST 6 / EMPATH 7). No investigation phase,
  no exploration in the main loop, no abstention, exactly one isolation per Day, explorer death = immediate loss.
- All 0.8.0 per-Stage state lives in `flags["stage_080"]` (snapshot-safe). Day Packets come from
  `AstraCaseGenerator.generate_day_packet` and must pass `validate_day_packet` (fairness contract).
- Story content: `stage_story_080.gd` (openings, incidents, resolutions, failure). Dialogue: `social_lines_080.gd`.
  Persona/spotlight: `AstraCrewCatalog.PERSONA` / `SPOTLIGHT`. Judgement profiles: `AstraDecisionModel.JUDGEMENT`.
  Story ledger and continuity model: `docs/STORY_LEDGER_080.md`.
- UI: `scripts/ui/game_screen.gd` + one view per phase in `scripts/ui/views/`; scenes use `AstraVNStage`.
  Each view owns its next step; do not add a second "next" button or onboarding modals.
- GitHub-first, CI-validated. Every release branch must pass `Godot CI` before it is promoted to `main`.

## Architecture rules (why 0.2.0 was a rebuild)
0.1.x stacked a new script on top of the previous version for every release
(`main.gd -> main_v004.gd -> ... -> main_v011.gd`, six state classes deep) and patched labels by
walking the node tree. Do not reintroduce that pattern.

1. **One model, one place.** `scripts/core/game_session.gd` owns all case state and rules.
   UI calls its public methods (`advance`, `story_next`, `story_choose`, `ask`, `question_options`,
   `meeting_continue`, `meeting_options`, `intervene`, `cast_vote`, `resolve_tiebreak`, `choose_night_action`)
   and re-renders on `changed`. UI never edits session fields directly.
2. **Content is data.** Cases live in `case_catalog.gd`, crew in `crew_catalog.gd`, lines in
   `dialogue_bank.gd`, private scenes in `private_events.gd`, authored voyage/storylets in
   `voyage_content.gd` + `storylets_052.gd` + `storylets_053.gd` + `storylets_054.gd` + `storylets_055.gd`, and autonomous beats in
   `crew_activity_model.gd`. Add content to registries/models, not UI code.
3. **Truth is generated, never hand-placed.** `case_generator.gd` builds each Day Packet (positions, claims,
   fragments held by people) from the Stage seed and the Day. Invariants (checked by tests):
   - evidence against the acting Null is held by innocents through at least two access paths (two owners
     or an owner plus a backup keeper); the two traces leave the actor and at most two others, drawn per
     Day from an evidence curve (`NARROW_CURVE`: Day 1 mostly 2-3 people, Day 2 1-2, Day 3+ mostly 1) —
     never a fixed "Day 2 is the answer"; a sighting or log that names the actor outright is the exception;
   - innocents can leave the same shapes a Null leaves (harmless lies, honest mistaken sightings, a Null's
     borrowed alibi), and anyone, a Null included, can hold a harmless true observation (`ROUTINE`), so no
     single shape is a formula (tests/probe_replay_080.gd measures it);
   - honest crew never falsify their position; at most one innocent has a harmless reason to lie per Day,
     and `MISREMEMBERED` is sincere (`lie=false`);
   - a Null's false sighting is always refutable (a companion or an alibi log);
   - fragment text never names a role; packets are deterministic for the same seed and state.
4. **Korean text goes through `AstraJosa`.** Use `{name|eun}`-style tokens in dialogue, `AstraJosa.eun()`
   etc. in UI code, and `|i`-style inline markers only inside `game_session.gd` strings that pass through
   `_josa_inline`. Never write `은(는)` / `이(가)`.
5. **Each character keeps their register**: 미라 해요체, 준/루칸/세나/다렌 자연스러운 반말, 소렌 차분한 해요체,
   노아 짧은 해요체, 마렌 따뜻한 해요체. See `docs/CHARACTERS.md`.
6. **Optional AI stays optional.** The backend may only reword a line that the rules already produced
   (`apply_ai_line`). It never changes roles, clues, suspicion, votes or score. Off by default.
7. **Saves stay compatible.** `AstraMetaProgress` writes save version 12 (0.8.0) and must keep loading older archives; the session snapshot is v4 and migrates v1–v3 (INVESTIGATION/EXPLORE resume in Conversation, AUDITOR becomes ANALYST or NONE). New state belongs in optional nested dictionaries with defaults.
8. **Knowledge is explicit.** NPC dialogue/decisions may only use facts reachable through `AstraKnowledgeModel`. If A tells B, C does not know it until a real propagation/public step occurs.
9. **RNG chooses authored content; it never writes it.** Use the session RNG or an intentionally seed-derived local RNG. New selectors must remain deterministic for the same seed + same player actions.
10. **Mira is an emotional anchor, not a protected route.** She can be Null, isolated, wrong, distant or in conflict. Do not make Mira immune to rules or let new Mira content erase another chapter's spotlight.

## 0.8.0 campaign pass additions
- **Interludes** (`scripts/core/interludes_080.gd`, `scripts/ui/pixel/*`): short playable scenes placed in the
  Day 1 story queue (kind `interlude`). A story scene first: failing or skipping never blocks the Stage or
  erases evidence (`finish_interlude(id, "success"|"partial"|"skipped")`). Pixel sheets come only from
  `tools/import_pixel_090.gd` (originals untouched; 128x128 frames, rows down/up/left/right; it also writes
  `scripts/ui/pixel/pixel_manifest.gd`, never edit that by hand). Portraits carry
  feeling, pixel characters carry space — do not mix them. Motion beyond walking is made in
  `AstraPixelActor.MOTION_SHADER` by moving whole-pixel bands (head above `NECK_ROWS`, upper body above
  `WAIST_ROW`, legs planted) — never redraw or stretch the sheets. Drawn poses are cut from the user's action
  sheets at the walking figure's size, with a one-pixel dip in and out (`docs/PIXEL_ACTIONS_100.md`). Interlude actors carry `idle` (watch/work/sit/alert/pace); a seated
  actor needs a prop marked `front` (drawn again over them by y-sort).
- **Explorers (0.9.0/1.0.1 contract)**: a new campaign picks one of six explorers (`AstraExplorerCatalog`):
  `explorer_id` is who, `art_id` which drawings (`serin_a`...). Identity may change dialogue wording,
  first-contact tone (`FIRST_CONTACT`, rotating by Stage), relationship texture, a bounded social-trust starting
  nudge (`TONE_NUDGE`, at most ±0.02), meeting voice (`MEETING_VOICE`) and the next-day callback. That trust can
  indirectly affect later social following; do not claim same-seed NPC votes are invariant. Identity must never
  change Null assignment, case truth, generated/available evidence, RNG sequence, puzzle answers, direct deduction
  power, special abilities or action counts. Portraits: `tools/import_explorers_090.gd` → `assets/explorers/`.
  Old saves keep p1-p6 as a neutral explorer (`AstraMetaProgress.player_profile_for_slot`); never map a legacy look
  to one of the six.
- **Failure / echo**: the explorer's death ends the reconstruction at once; a retry is a new reconstruction
  (`AstraGameSession.fresh_seed(previous)`), a load is the same one. Residual Echo and the death echo leave at
  most one beat of feeling at the next first morning — never a role or an answer.
- **Finale**: clearing the last Stage plays one decision, an epilogue (TRUST / FRACTURE / DISCOVERY), campaign
  callbacks, ASTRA's last line, credits, then unlocks DEEP RECONSTRUCTION (archive-wide).
- **DEEP RECONSTRUCTION** (`scripts/core/deep_run.gd`, `scripts/ui/deep_screen.gd`): one life, depth from the run
  seed, one announced modifier per depth from 4, two Nulls from 7. A death closes the run file before anything
  can be reloaded. No stat upgrades.

## 1.0.0 / 1.0.1 CONVICTION rules
- **The room weighs only what was said aloud.** Board alibi conflicts count for NPCs after `_raise_pair` (a link,
  a contrast, a clarification to the companions, or `_thread_claims`); a public confession takes the conflict off.
  Private evidence can inform a ballot, but collective accusations require player-heard evidence, an independent
  source, an explicit raised contradiction or a validating Link. Do not silently pool private notebooks into a
  room-wide deduction engine. Stage-specific evidence topology belongs in authored `deduction_profile` data, not
  `if case_id == ...` branches.
- **Link verb** (`link_statements`, `link_evidence`, `judge_link`, `intervene("link", "stmt|ev[|ev2]")`): judged from
  content only (places, people, times, excuse method). Never read `_day_role`, `truth` or a fragment's `refutes` for a
  group record there. Every logically equivalent piece of evidence must pass. Evidence labels may expose provenance
  (direct witness / hearsay chain / record / public-private visibility), never a score or answer likelihood. Repeating
  the exact same Link combination must not reveal new information.
- Meeting: `MEETING_INTERVENTIONS = 3` strong moves + 3 clarifications a Day; `board_status`, `meeting_summary`,
  `ballot_reasons`/`set_ballot_reason`. No numbers on screen.
- **Rewind**: the app keeps the first save of each morning (`dawn_path`); a lost Stage can go back once
  (`rewind_memory` → `apply_rewind`). Memory is notes and leads only, never knowledge. Deep has no rewind.
- **Walking** is whole frames only (no band motion while moving), distance-driven with the sheet's `stride`,
  torso-anchored frames. Gate: `tests/motion_100_tests.gd`. The selection screen shows main illustrations only.
- **Tasks**: `AstraShipTask` housing; families signal / circuit / timeline / route (`minigame_100_tests.gd`).
  All four families keep keyboard controls and must also complete through mouse input only; Signal frequency/phase
  controls mutate the same state regardless of input device.
- **UI**: growing logs use `AstraUI.track_follow` + `follow_bottom` (after layout, never while the reader scrolls back)
  and end with `AstraUI.bottom_pad()`; a queued follow must re-check follow state after layout settles so wheel-up
  read-back wins. Multi-line choices use `AstraUI.choice_button`. Minimum supported window is 1120×700 and
  `tests/ui_layout_100.gd` covers minimum-size screens plus resize round-trips.

## 1.1.0 LIVING PATHS rules
- Do not add a BranchManager/NarrativeGraph/second story state machine. Route state belongs in existing GameSession/voyage nested dictionaries.
- Canon, hidden Null identity, base Day Packet and puzzle answers never select a story branch. Branch inputs are visible player choice/knowledge/relationships/consequences only.
- Five campaign anchors are authoritative: DEAD_AIR, ECHO_WARD, RED_SHIFT, BORROWED_DAYS, THREE_MINUTES_DARK.
- A meaningful branch changes at least two observable categories: scene, knowledge scope, provenance, NPC behavior, callback/relationship texture, meeting context, next Day/Stage or finale reception.
- Choice consequences use AstraConsequenceModel only. Preserve event-id deduplication across save/load/rewind.
- Deep Reconstruction does not expose campaign branch anchors.
- NEXT_LOOP callbacks are residue/familiarity, never explicit episodic memory.
- Finale action is never overwritten by history; history changes reception/callback texture only.
- Optional story exposure uses existing speaker_exposure and must never read role/truth/evidence to decide who gets a scene.
- Preserve Meta save v12 / Snapshot v4 unless a real schema requirement is documented and migrated.

## Balance guardrails
`tests/run_tests.gd` plays every Stage with three bots (SMART talks, follows up, intervenes and votes by
its own knowledge; RANDOM uses legal options blindly; PASSIVE talks to nobody and votes with the room).
Keep the historical global gates, plus the 1.0.1 release-polish gates:
- SMART wins ≥ 75% of Stages; SMART ≥ RANDOM + 10pp; SMART ≥ PASSIVE + 5pp; PART II PASSIVE ≤ 85%;
- Stage 2–4 quick ceiling: each PASSIVE ≤ 85% and ECHO_WARD must stay below the release ceiling;
- player contribution must materially exceed passive play; `causal_101_tests.gd` uses 100 same-seed ACTIVE/PASSIVE
  pairs per Stage and compares resolution time, innocent isolations, casualties, public facts, Links, stance changes,
  vote-intention changes, raised contradictions and meeting dead space;
- `fairness_101_tests.gd` separately audits 100 seeds/Stage for alternative proof routes and role-tell collapse.
PASSIVE win rate is a regression ceiling, not the design objective. Do not make NPCs random, forget known evidence,
remove fair clues, or weaken SMART just to lower PASSIVE. Prefer explicit player proof (Link/source verification/
clarification/presentation) changing the room. Do not lower a gate to make a change pass; change rules/content and
explain it in QA_REPORT. `tests/balance_probe.gd` prints the 100-game per-Stage tuning report.

## Before pushing
```bash
godot --headless --path . --import
# every line of tests/ci_suite.txt (CI and tools/build_windows.ps1 read the same list):
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
godot --headless --path . --script res://tests/walkthrough_080.gd           # writes build/qa/walkthrough_080.txt — read it
godot --path . --script res://tests/visual_080.gd                           # screenshots in build/qa (needs a window)
```
Commit `.import` and `.uid` files together with the assets/scripts they belong to.

## Release process
1. Work on a feature/release branch; bump `VERSION`, `project.godot` and Windows resource metadata; update changelog/release/QA docs.
2. Push and require the complete `Godot CI` matrix to pass on the release branch.
3. Fast-forward the tested release head to `main`; do not tag an untested merge result.
4. Require `Godot CI` to pass again on that exact main SHA, including Windows RC export and exported `ASTRA.exe` boot.
5. The version-specific publish workflow downloads the Windows artifact from that exact successful run, verifies its SHA256, then creates the `vX.Y.Z` tag and GitHub Release against the same main SHA. Never reuse an earlier-version RC artifact.
