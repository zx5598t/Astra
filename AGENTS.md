# ASTRA AI / CODE AGENTS GUIDE

## Current target
- Live version target: **0.0.9**.
- Preserve GitHub-first, incremental, CI-validated development.

## Authority layers
1. TruthEngine owns world truth.
2. Game state owns relationships, suspicion, votes, score and progression.
3. Player hypothesis links and CASE THEORY are player beliefs only.
4. AI performs dialogue/performance only.

## 0.0.9 guardrails
- Never reveal whether a submitted theory is correct before the case ends.
- Theory submission must never change hidden roles or NPC belief math.
- Isolation vote and two-suspect theory are separate systems.
- Final theory review may award score but cannot retroactively change the case outcome.
- Keep offline fallback playable.
- All release branches must pass Godot CI before main promotion.
