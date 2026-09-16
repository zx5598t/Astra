# ASTRA AI / CODE AGENTS GUIDE

## Current live target
- Version: 0.0.7
- Main scene: `scenes/main_v007.tscn`
- Runtime state: `AstraProgressionGameState`
- Persistent meta: `AstraMetaProgress`

## Non-negotiable architecture
- TruthEngine owns canonical truth.
- Random Null assignment is engine-owned and never exposed before results.
- AI is expression only and must preserve offline fallback.
- Notebook may visualize discovered information but must never leak hidden roles.
- Character identity/job/personality stays stable even when hidden role changes.
- Persistent save contains meta progression, not secret answer data for an active case.

## Visual direction
- Keep 4F / 4M attractive cast readable and distinct.
- Expression assets are split into calm/warm/tense overlay slots as a replaceable pipeline.
- Incident environments should be visually distinguishable before more detailed final art replaces SVG prototypes.
