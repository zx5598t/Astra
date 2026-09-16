# Changelog

## 0.0.6 — Case Shuffle Protocol
- Hidden Null roles randomized every run while preserving character identity/jobs.
- Added two coherent case templates: Dead Air and Glass Garden.
- Evidence targets, clearing evidence and suspicion propagation now follow the randomized case truth.
- Added Investigator Notebook with evidence links, claims and contradiction candidates.
- Added session-level case progression and Insight score.
- Added optional AI performance for selected public-meeting lines.
- Prevented old Rho/Vale-specific evidence reactions from leaking into randomized cases.
- Bumped AI contract to 0.0.6 while preserving offline fallback.

## 0.0.5 — Loop Memory + AI Performance
- Added up to 3-day investigation loop.
- Added previous-day conversation memory and chained questioning.
- Added optional FastAPI/OpenAI performance backend.
- Added emotion presentation state and AI validation.
- Excluded isolated NPCs from later meetings.

## 0.0.4 — Social Pressure
- Dynamic question options.
- Relationship matrix.
- Meeting interruptions and rebuttals.
