# ASTRA AI / CODE AGENTS GUIDE

## Current live target
- Version: 0.0.4 — Social Pressure
- Repository is the source of truth for development.
- Godot 4.x / GDScript.

## Non-negotiable architecture
1. `TruthEngine` alone owns canonical truth, roles, evidence facts, and outcome truth.
2. LLM output is performance, not authority.
3. NPC can reference only allowed fact refs supplied in its AI context.
4. AI failure must preserve a complete offline rule-based game.
5. NPC relationships may bias interpretation and votes, but must not reveal hidden role truth.

## Character consistency
- Use `docs/CHARACTERS.md` as the character bible.
- Preserve 8-person core cast (4F / 4M) unless explicitly expanding it.
- Dialogue should follow each NPC's speech style, social goal, and pressure response.

## Version discipline
When changing version, update VERSION, README, CHANGELOG, project.godot, and the active runtime version layer.
