# ASTRA AI Development Rules — 0.0.6

1. TruthEngine / case state owns canonical truth. Never let an LLM assign roles or create evidence.
2. Null identities are randomized by deterministic seeded game code.
3. Character job, visual identity and personality remain stable across hidden-role randomization.
4. Evidence must carry explicit metadata (`signal`, `target_id`) so suspicion updates are explainable.
5. Investigator Notebook may show only discovered evidence and spoken claims; never reveal hidden roles.
6. AI meeting/dialogue output must be validated against allowed facts and targets.
7. API keys belong only in backend environment variables and must never be committed.
8. Offline fallback must remain fully playable.
9. Isolated NPCs may not speak, interrupt, receive new questions, or vote on later days.
10. Version changes update VERSION, project.godot, README, CHANGELOG and AI contract together.
