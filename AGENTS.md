# ASTRA AI / CODE AGENTS GUIDE

## Current live target
- Version: 0.0.5
- Main scene: `scenes/main_v005.tscn`
- Game state: `AstraLoopGameState`

## Non-negotiable architecture
- TruthEngine owns canonical truth.
- AI is a performance layer only.
- Never place provider API keys in Godot/client code.
- AI relationship_delta is a proposal only; game code decides relationship math.
- AI responses must pass `AIGateway.validate_action()` before display.
- Any AI/network failure must preserve a complete offline play path.

## Product direction
- 8 attractive, distinct crew members (4F / 4M).
- Persistent memories and relationships across days/loops.
- Player should infer motives from contradictions, not read hidden roles from UI.
- Prefer incremental versioned layers over destructive rewrites.
