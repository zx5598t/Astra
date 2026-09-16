# ASTRA AI Development Rules

1. Never let an LLM mutate TruthEngine or decide canonical facts.
2. Game outcomes, evidence, roles, votes, scoring and RNG must be deterministic game code.
3. Preserve all existing features unless the task explicitly removes them.
4. Version changes must update `VERSION`, `README.md`, `CHANGELOG.md` and `AstraGameState.VERSION`.
5. NPC model output must be structured and validated before display.
6. An NPC may reference only facts it knows or facts intentionally exposed to it.
7. AI failure must always fall back to a playable rule-based path.
8. Keep the project directly runnable from `project.godot` with Godot 4.x.
9. Prefer small, testable version increments over large rewrites.
10. The player should infer the answer; UI must not reveal hidden role truth before result resolution.
