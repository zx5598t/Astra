# ASTRA — Guide for code agents and contributors

## Current target
- Version **0.5.3** (HEARTBEAT). Engine: **Godot 4.7.2 stable**, GL Compatibility renderer.
- GitHub-first, CI-validated. Every release branch must pass `Godot CI` before it is promoted to `main`.

## Architecture rules (why 0.2.0 was a rebuild)
0.1.x stacked a new script on top of the previous version for every release
(`main.gd -> main_v004.gd -> ... -> main_v011.gd`, six state classes deep) and patched labels by
walking the node tree. Do not reintroduce that pattern.

1. **One model, one place.** `scripts/core/game_session.gd` owns all case state and rules.
   UI calls its public methods (`advance`, `search_room`, `ask`, `present_clue`, `accuse`, `defend`,
   `cast_vote`, `choose_night_action`, `resolve_private_event`, `set_mark`) and re-renders on `changed`.
   UI never edits session fields directly.
2. **Content is data.** Cases live in `case_catalog.gd`, crew in `crew_catalog.gd`, lines in
   `dialogue_bank.gd`, private scenes in `private_events.gd`, authored voyage/storylets in
   `voyage_content.gd` + `storylets_052.gd` + `storylets_053.gd`, and autonomous beats in
   `crew_activity_model.gd`. Add content to registries/models, not UI code.
3. **Truth is generated, never hand-placed.** `case_generator.gd` builds positions, claims and clues from
   a seed. Invariants (checked by tests):
   - a clue never names a culprit directly; each Null is identified only by the intersection of the two
     real traces of their operation, or by breaking their alibi;
   - honest crew do not intentionally falsify their position unless the generated innocent discrepancy reason says they do;
   - one innocent discrepancy exists per case; `MISREMEMBERED` is sincere false memory and therefore `lie=false`;
   - decoy traces are timestamped outside the incident window and exclude that operation's culprit.
4. **Korean text goes through `AstraJosa`.** Use `{name|eun}`-style tokens in dialogue, `AstraJosa.eun()`
   etc. in UI code, and `|i`-style inline markers only inside `game_session.gd` strings that pass through
   `_josa_inline`. Never write `은(는)` / `이(가)`.
5. **Each character keeps their register**: 미라 해요체, 준/루칸/세나/다렌 자연스러운 반말, 소렌 차분한 해요체,
   노아 짧은 해요체, 마렌 따뜻한 해요체. See `docs/CHARACTERS.md`.
6. **Optional AI stays optional.** The backend may only reword a line that the rules already produced
   (`apply_ai_line`). It never changes roles, clues, suspicion, votes or score. Off by default.
7. **Saves stay compatible.** `AstraMetaProgress` currently writes save version 9 and must keep loading older archives. New Living Crew state belongs in optional nested dictionaries with defaults; never require old slots to contain 0.5.3-only keys.
8. **Knowledge is explicit.** NPC dialogue/decisions may only use facts reachable through `AstraKnowledgeModel`. If A tells B, C does not know it until a real propagation/public step occurs.
9. **RNG chooses authored content; it never writes it.** Use the session RNG or an intentionally seed-derived local RNG. New selectors must remain deterministic for the same seed + same player actions.
10. **Mira is an emotional anchor, not a protected route.** She can be Null, isolated, wrong, distant or in conflict. Do not make Mira immune to rules or let new Mira content erase another chapter's spotlight.

## Balance guardrails
`tests/run_tests.gd` plays hundreds of cases with three bots. Keep, across all cases/protocols:
- deduction bot win rate ≥ random bot + 30 percentage points (currently ~87% vs ~16%)
- passive bot (never investigates, always abstains) < 20% (currently ~10%)
If a change moves these, retune numbers in `game_session.gd` / `case_catalog.gd` rather than the tests.

## Before pushing
```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
godot --headless --path . --script res://tests/mira_content_tests.gd         # ASTRA 0.5.3 MIRA CONTENT TESTS OK
godot --headless --path . --script res://tests/heartbeat_053_simulation.gd   # ASTRA 0.5.3 HEARTBEAT SIMULATION OK
```
Commit `.import` and `.uid` files together with the assets/scripts they belong to.

## Release process
1. Work on `release/x.y.z`; bump `VERSION` and `config/version` in `project.godot`; update `CHANGELOG.md`
   and `docs/RELEASE_NOTES.md`.
2. Push; wait for `Godot CI` to pass.
3. Fast-forward `main` to the release branch.
4. Tag `vX.Y.Z` on `main` → the `Windows build` workflow publishes `ASTRA-X.Y.Z-windows.zip` as a Release.
5. The Windows job must validate the source and boot the actual exported `ASTRA.exe` before publishing.
