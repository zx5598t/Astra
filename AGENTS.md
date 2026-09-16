# ASTRA AI / CODE AGENTS GUIDE

## Current live target
- Version: **0.0.8**
- Main scene: `scenes/main_v008.tscn`
- Game state: `AstraHypothesisGameState`
- Incidents: Dead Air / Glass Garden / Echo Ward

## Non-negotiable architecture
- TruthEngine owns canonical truth.
- AI is performance only and cannot set roles/evidence/votes/win state.
- Player hypothesis links are private reasoning aids only; they must never mutate canonical truth or NPC suspicion.
- API keys stay server-side.
- Offline fallback remains fully playable.
- Archive saves only progression/player choices, never hidden role knowledge between runs.

## Quality gate
- Target Godot: 4.7.2 stable.
- GitHub Actions must import/parse the project headlessly on main/release push and PR.
- Fix CI/parser errors before adding more systems.
