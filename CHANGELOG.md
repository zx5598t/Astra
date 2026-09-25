## 0.8.2 — PLAYER MATTERS

Player-agency stabilization pass over 0.8.1. No new mode, character, protocol, Act or ending.

- Added runtime provenance for player contact → public fact → meeting reasoning → NPC vote changes, reusing the authoritative Stage state and DecisionTrace paths.
- Player contacts now retain the action that exposed a fact; public evidence records source/provenance/trigger without a new persistent save field or snapshot-version bump.
- Meeting interventions compare NPC intent before/after the action and record attributable opinion/vote changes for deterministic paired QA.
- Player accusations retain the evidence ids the explorer actually knew, so later reasoning can distinguish an evidence-backed push from unsupported pressure.
- Added Stage 2–4 paired agency regression/probe coverage; win rate remains a reported metric, not the sole balance target.
- Snapshot v4 and meta save v12 remain unchanged.

## 0.8.1 — CONTAINMENT TUNING

Stabilization pass over 0.8.0. No new mode, character, lore branch or protocol.

- Archive protocol selection now reads the authoritative `AstraGameSession.protocols_for_stage()` list: Stage 5 auto-equips GUARDIAN, Stage 6 offers GUARDIAN/ANALYST, Stage 7+ adds EMPATH, and legacy AUDITOR is never player-facing.
- Archive replay and campaign availability are slot-scoped. A failed attempt remains history/statistics but no longer counts as a clear or unlocks the next Stage.
- Global historical completion uses `case_wins`; Deep completion is derived from actual campaign clears while preserving a legitimate old completion flag.
- Removed known always-pass assertions (`or true`, `ties >= 0`) and added progression/Archive regressions.
- Meeting evidence ownership is stricter: private records, witnesses and hearsay are substantially less likely to surface untouched, while facts the explorer first drew out are more likely to enter the public room. Public evidence telemetry records whether prior player contact existed.
- Added a same-seed Stage 3 agency probe requiring player contact to change whether at least one fact reaches the public meeting.

## 0.8.0 — CONTAINMENT

Social-deduction core rebuild. One Stage = one game; a Day is a round inside it.

**Final pass — deduction, replay, campaign (latest)**
- Evidence curve: how far a Day's two traces narrow the room is drawn per Day (Day 1 mostly 2–3 people, Day 2 1–2, Day 3+ mostly 1); record and sighting kind are chosen together; small rooms use a second sighting instead of a naming log; new traits (hair length, cabin wing via corridor sensors).
- No single-shape formulas (measured by `tests/probe_replay_080.gd`): honest mistaken sightings, a Null's borrowed alibi, harmless true observations anyone (a Null too) can hold, Nulls slower to make the first accusation. First accuser is a Null 35% (was 62%); "holds no clue" 21% (base ≈ 18%).
- Retold sightings now come up in the meeting; the explorer can ask the witness directly (“본 사람에게 직접 묻는다”); a hearsay stops counting once its source is heard.
- Reasons are spoken by provenance (“내가 확인한 기록”, “루칸이 봤다는 것”, “제가 본 것과 말이 다른 점”), never “I saw it” for a log.
- Night targets weigh threat, the Null's style, the shield rule and relationships; the explorer's threat fades by day like everyone's.
- Aegis saves become a question the next morning (“왜 나였을까”, and someone may doubt what the shield caught).
- Isolation words by situation (resigned / hurt by a friend's vote / confused / to the explorer); three distinct final pleas each.
- Morning vignettes: someone suspected yesterday, someone whose vote sent an innocent to a pod (Part I only), small habits; at most one per morning.
- 탐사요원 등록 (name + look, temporary looks p1–p6 until final art); face and name in meeting, vote and night screens.
- Pixel pipeline `tools/import_pixel_080.gd`: 14 walking sheets normalised from the originals (alpha-bound cuts, one scale per character, feet anchored, fringe removed at export).
- Nine interludes (Stages 2, 3, 4, 6, 8, 10, 11, 12, 13): small rooms, 1–3 minutes, tasks = signal trace, power routing, ordering, choosing one alarm. Failure or skipping never blocks.
- Pixel characters move like people (`docs/PIXEL_ACTIONS_080.md`): made from the walking frames by whole-pixel band moves (head / upper body; legs planted, nothing redrawn or stretched) — breathing, walk weight, nods while talking, bow, tilt, head shake, sigh, start, joy jump, weight shift, work poses at consoles, sitting behind the lounge table; speech-bubble emotes (! ? … ♪, sweat). People work, notice the explorer when close (a start the first time), go back to work, pace, glance, look around; tasks end with reactions; the scene ends with a few steps to the door. Optional drawn action sheets (work / talk / sit / reactions) replace the made-up poses when added.
- Failure flow: 재구성 실패, heavier “fracture” scene from Stage 9, 기록 확인 / 재구성 재시도 / 타이틀. Retry = new seed (never the previous one); load = same reconstruction. Death echo and Residual Echo (one beat of feeling, never a role).
- Finale: one decision about the unsigned re-sleep order, epilogue in three tones (TRUST / FRACTURE / DISCOVERY), campaign callbacks, ASTRA's last line, credits, DEEP RECONSTRUCTION unlocked (archive-wide).
- DEEP RECONSTRUCTION: one life, run-seeded depths, one announced modifier per depth from 4 (잡음 / 정전 / 분열 / 메아리 / 고요한 갑판), two Nulls from 7, local bests; a death closes the run before anything can be reloaded.
- UI: no phase banners (they covered the first lines), no duplicate “new fact” toast, toasts over the task line, meeting mood shown once, vote rules explained once, later vote reveals faster; portrait fringe shader; analyst comparisons get a reaction from the person compared.
- New tests: `campaign_080_tests.gd`, `deep_080_tests.gd`, `pixel_080_tests.gd`; walkthrough fails on any unformatted line.

**Structure**
- 13 Stages in two Parts. PART I (Stages 1–4): 4 → 5 → 6 → 7 crew, one Null. PART II (Stage 5+): all eight crew, two Nulls, one specialist protocol.
- A Day is Morning → Conversation → Meeting → Vote → Night. The investigation phase and ship-exploration flow were removed from the main loop (old saves in `INVESTIGATION`/`EXPLORE` resume in Conversation).
- Every Day isolates exactly one person. No abstention anywhere; a tie goes to a runoff between the tied; a tied runoff is decided by the explorer. The explorer's ballot weighs one.
- Parity counts living non-Null crew plus the explorer. The explorer can be attacked at night; the explorer's death ends the Stage at once. No time-out.
- No role is shown on isolation; the Stage result reveals the Nulls.

**Day Packets and information**
- Each Day generates a deterministic, snapshot-stable Day Packet (incident, 3–7 fragments held by people, 0–1 harmless lie, 0–1 Null deception) validated against a fairness contract (≤1% regeneration failures across 2,340 packets in tests).
- Logs are unread until their keeper opens them; unopened logs that would expose a Null can be wiped overnight.
- One person's sighting carries half weight until a second independent source agrees; an unanswered excuse softens a log.
- Stage themes: Stage 2 concealment, Stage 3 distorted hearsay, Stage 4 time/place frames; Part II mixes them.

**People**
- NPCs judge from what they know (`AstraKnowledgeModel`) with per-person conviction, bandwagon and regard for the explorer; unsure people follow those they trust, including the explorer.
- Nulls keep their own voice and choose a survival style (DEFLECTOR / QUIET / ALLY / COUNTERATTACK); two Nulls are not a perfect team.
- Seven-axis persona and a Stage spotlight map for all eight crew (`AstraCrewCatalog.PERSONA`, `SPOTLIGHT`).
- New voiced lines: second excuses, expert confirmations, character references from friends, first-person reasons, voiced ballots, final words (including “I hid something, but not what you think”), friend reactions to an isolation, callbacks to what the explorer did yesterday, small habits.

**Conversation and meeting**
- One click on a face starts a conversation; at most three follow-ups, built from what the explorer knows. Confrontations can be asked calmly or pressed.
- The meeting plays one argument at a time and pauses; the explorer has one intervention (two with EMPATH) chosen from 2–3 options that fit that moment (re-check, press, defend, open a log, ask for the basis, accuse). Contested excuses, refutable frames and exposed baseless accusations change how the room votes.
- A Day question ties the Day together and grows out of yesterday.

**Protocols (PART II)**
- GUARDIAN (Stage 5): Aegis field, 2 charges per Stage, not the same door twice in a row, self allowed; the report never names the attacker.
- ANALYST (Stage 6): once a Day, CONSISTENT / CONFLICT / INSUFFICIENT.
- EMPATH (Stage 7): once a Day, one extra follow-up or one extra meeting intervention.
- Protocols are introduced and chosen inside the story; AUDITOR saves migrate to ANALYST (or NONE where it does not exist).

**Presentation**
- New in-Stage screen: one thin status bar (PART · STAGE · DAY, four-step stepper, who is awake), one instruction line, and views that carry their own next step. Onboarding modals, the separate bottom bar, the mark button and the hint strip were removed.
- New visual-novel stage for the opening, mornings and results with large portraits and expressions; conversation, meeting, vote, night and result screens rebuilt around large faces.
- Title: NEW GAME / CONTINUE per slot / DELETE CAMPAIGN; slot-scoped progress; a cleared campaign between Stages stays visible.
- Glossary (용어) and a short how-to-play replace the old codex help; wording simplified.
- The 0.7.x scene paintings (art071–073) return as backgrounds for resolutions and crew moments.

**Art**
- Sena and Maren fully replaced from the new artwork; all eight characters' cast/portrait/head/expression sets re-cut (`tools/import_080_art.gd`, `assets/art050/manifest_080.json`).

**Tests**
- New `tests/run_tests.gd` (rules, fairness, flow, conversation, meeting, vote, night, parity, knowledge, protocols, story and dialogue consistency, saves, balance, player contribution), new `tests/ui_smoke.gd`, `tests/walkthrough_080.gd`, `tests/visual_080.gd`, `tests/balance_probe.gd`. CI and the Windows build read one list, `tests/ci_suite.txt`.
- Retired 37 legacy test scripts that exercised removed systems (exploration, voyage traversal, abstain votes, investigation, old meeting/aftermath UI).

**Version**: 0.8.0 · meta save v12 (loads v11 and older) · session snapshot v4.

## 0.7.4 — PLAYBACK

- Completed the PLAYBACK pass on top of the merged breathing-room guard without introducing a Narrative/Playback/Cutscene manager or new persistent state.
- Preserved one-action breathing room after MANDATORY/FOLLOWUP/FOCUS beats while keeping player-directed conversation and explicit topic selection available.
- Fixed ACT II result continuity: SECOND_WATCH through THRESHOLD now have chapter-specific reset residue instead of falling back to CALIBRATION's bandage framing.
- Expanded `tests/playback_074_tests.gd` across strong-scene collision, player agency, continuation/consequence reachability, LAST_LIGHT → SECOND_WATCH → THRESHOLD progression, Night/Briefing feedback ownership, save-v11 legacy hydration, character exposure and all 15 existing visual mappings.
- Kept the authored library, visual assets and save schema unchanged: new scenes **0**, deleted scenes **0**, new images **0**, new persistent fields **0**, save **v11**.
- Existing campaign simulations, story/editorial regressions, UI smoke and bot gates remain CI-owned; thresholds were not weakened.

## 0.7.3 — HUMAN SIGNAL

- Added five exact micro-arc / relationship visual beats for Sena, Noa, Soren + Lucan, Daren + Jun, and Maren using the existing voyage-stage art path.
- Polished those five action/dialogue beats so pose, exchange, blocking, correction, and preservation carry character meaning without extra clicks.
- Added `assets/art073/` as 1280×720 SVG scene art while retaining all 0.7.1 and 0.7.2 visual mappings and room/portrait fallback.
- Added Linux + Windows HUMAN SIGNAL regression coverage; save schema remains v11 with no migration or new persistent fields.

# 0.7.2 · ACT I VISUAL STORY PASS · 2026-09-22

ACT I의 기억점 5장에 신규 1280×720 SVG 장면 아트를 추가했다: **CALIBRATION / ECHO_WARD / SILENT_ORBIT / RED_SHIFT / LAST_LIGHT**. DEAD_AIR는 LAST_LIGHT의 병렬 기록 이미지와 역할이 겹쳐 제외했고, 초반 5~10분의 기억점을 위해 CALIBRATION을 선택했다.

표시는 0.7.1의 `AstraArt.story_scene()` + `AstraVoyageView` stage 교체 방식을 그대로 확장했다. ECHO_WARD·SILENT_ORBIT·RED_SHIFT·LAST_LIGHT는 `story_resolution_*` reveal에서, CALIBRATION은 기존 `first_wake`에서만 표시된다. 이미지가 없거나 매핑되지 않은 장면은 기존 room art/portrait fallback을 유지한다. 새 manager/cutscene/save 필드는 없다.

ECHO_WARD는 소렌의 청취 전문성, SILENT_ORBIT은 별→시스템 시각→도착 기록→정비 이력, RED_SHIFT는 생장선→독립 날짜→필기 습관, LAST_LIGHT는 서명→체크섬→병렬 유효성 순서가 읽히도록 action/dialogue를 다듬었다. player-facing `history` 표현도 자연스러운 한국어로 정리했다. 0.7.0 CI 누락 3종(act2 simulation / crew glimpse / character arc)과 신규 `visual_story_072_tests.gd`를 CI에 직접 연결했다. save schema는 **v11 유지**다.

# 0.7.1 · VISUAL STORY PASS · 2026-09-22

0.7.0의 ACT II 구조와 save schema v11은 그대로 두고, **SECOND_WATCH · BLIND_DECK · THREE_MINUTES_DARK · CONTINUITY · THRESHOLD** 다섯 핵심 resolution에 실제 장면 아트를 연결했다. 신규 자산은 `assets/art071/`의 1280×720 SVG 5장이다. 인물 얼굴을 새로 정의하지 않고 근무 로그, 숨은 정비 갑판, 겹치는 비상 경보, 평범한 생활 기록, 장기수면 재개 공백처럼 플레이어가 그 장면에서 실제로 봐야 하는 상황을 중심으로 구성했다.

새 컷신 엔진이나 art manager는 만들지 않았다. 기존 `AstraArt`에 0.7.1 매핑 하나를 추가하고, `AstraVoyageView`의 기존 stage가 `story_resolution_*` 동안만 해당 이미지를 사용한다. 파일이 없거나 매핑되지 않은 장면은 기존 room art + portrait 경로로 자동 fallback한다. 저장 필드와 progression은 바뀌지 않는다.

다섯 장면의 situation/outro와 resolution action/dialogue도 이미지와 중복 설명하지 않도록 다듬었다. SECOND_WATCH는 “사고 기록”보다 몇 주간의 평범한 근무를, BLIND_DECK은 지도 밖 공간의 실제 사용 흔적을, THREE_MINUTES_DARK는 역할 분담과 정보 출처 차이를, CONTINUITY는 재난보다 오래 남은 생활 흔적을, THRESHOLD는 정상 생활 → 긴 공백 → 장기수면 재개의 차분한 충격을 강조한다. canonical fact, handling choice, reveal 순서와 ACT II 결론은 유지한다.

전용 `visual_story_071_tests.gd`를 추가하고 기존 `story_070_consistency.gd` / `act2_070_tests.gd`와 함께 GitHub Actions gate에 연결했다. 기존 `ui_smoke.gd`는 모든 캠페인 장을 직접 플레이하므로 다섯 resolution art 경로도 실제 UI 흐름에서 함께 검증한다.

# 0.7.0 · SECOND WATCH · 2026-09-22

ACT I(Day 1~7) 재구축 + ACT II(Day 8~13) 신설. 실제 리포지토리를 먼저 감사한 뒤 진행했다: 거의 모든 서사 지원 시스템(Knowledge/Decision/Routine/Consequence/Motive/Incident/Codex/Claim Ledger/relationship 3계층/storylet scheduler)이 이미 구현되어 있었고, 8명 전원이 이미 4단계 개인 micro-arc를 갖고 있었다. 새 manager를 추가하지 않고 기존 API를 확장했다.

**ACT I 재구축.** CALIBRATION은 authored `trace_steps: 1`이 `get_case()`에서 무조건 2로 덮어써지던 버그를 수정했다(하루 1건 대신 2건 조사를 유도하던 실제 버그). Day 1~5의 첫 등장 대사에 있던 "저는 의무관 미라예요" 식 자기소개를 제거하고, 캐릭터 첫 등장 시 초상화 근처에 이름·직책·관찰 가능한 행동 한 줄이 몇 초간 스쳐 가는 비모달 FIRST IMPRESSION을 추가했다(모달/확인 버튼/게임 정지 없음). 슬롯별로 한 캠페인에 한 번만 보이며(`AstraMetaProgress.slot_crew_glimpsed`), 새 캠페인에서는 다시 보인다. Day 1~3은 선택적 pair/observation 장면이 전혀 없어 캠페인 전체에서 가장 빠르게 느껴지던 문제였다 — storylets_052~055.gd의 공유 게이트는 그대로 두고, Day 2(노아·다렌 cross-check, 미라 self-neglect 예고)·Day 3(준/세나 병렬 관찰)에 명시적 `chapters` 오버라이드를 가진 신규 장면만 추가했다. Day 4/5/6의 RESOLUTION_BEATS를 확장했다: 소렌의 자기 목소리 분석에 전문적 청취 근거를, SILENT_ORBIT에 세 번째 근거(system time)와 평범한 정비 기록 발견을, RED_SHIFT의 "내 필체" reveal을 단발성 outro 대신 실제 beat로 승격했다.

**ACT II 신설.** LAST_LIGHT 다음에 SECOND WATCH·BORROWED DAYS·BLIND DECK·THREE MINUTES DARK·CONTINUITY·THRESHOLD 6일을 추가해 `AstraCaseCatalog.CAMPAIGN`이 6개에서 12개가 됐다. ACT는 저장 값이 아니라 campaign day에서 파생되며(`AstraVoyageContent.act_for`), Day 8 잠금 해제는 기존 슬롯별 이전-장 완료 체인을 그대로 쓰므로 새 save 필드가 없다(schema v11 유지). storylets_052~055.gd의 MID_CHAPTERS/LATE 게이트와 incident_model.gd의 모든 incident "chapters" 목록에 ACT II 6일을 추가해, 기존 608개 personality/relationship 장면과 8종 incident가 LAST_LIGHT 이후에도 계속 등장하도록 했다(신규 시스템 없이 기존 라이브러리 재사용). THREE_MINUTES_DARK의 "동시다발 문제" 연출은 엔진이 `active_incident`를 한 번에 하나만 지원한다는 제약을 그대로 인정하고, 서사적으로는 동시 발생으로 서술하되 기계적으로는 하나만 직접 처리·나머지는 기존 NPC 자율 판단 시스템으로 위임했다.

**개발 중 발견/수정한 버그 1건.** ACT II 6일의 `CHAPTERS[...]["fact"]`에 새 문자열(`duty_log` 등)을 썼더니 investigation point가 그 fact를 절대 만들어내지 못해 `goal_done`이 영원히 true가 되지 않는 버그가 있었다 — investigation point는 `AstraVoyageContent.ROOMS`의 고정된 8개 공유 태그(power/signal/destination/security/archive/arrival/everyday/sample)만 사용하는 전역 공유 pool이었다. 전체 캠페인 UI 구동 검증(ui_smoke.gd)으로 발견했으며, 6일 모두 기존 태그로 재매핑해 해결했다. 이 재발을 막는 회귀 테스트를 `tests/story_070_consistency.gd`에 추가했다.

**캐릭터 심화.** `storylets_054.gd`의 8개 4단계 개인 arc(미라 자기방치·준 실수·다렌 실패한 모델·노아 개인 사본·세나 과잉보호·소렌 청취피로·루칸 위험경로·마렌 표본보존)가 이미 설계 의도와 거의 정확히 일치해 새로 만들지 않았다. `content_audit.gd`의 pair 분포 리포트로 확인한, 대사가 전혀 없던 4개 조합(준-소렌, 세나-노아, 마렌-소렌, 루칸-노아)에 장면 1개씩과 `AstraCrewCatalog.PAIR_CANDIDATES` 이력을 새로 추가했다.

authored voyage/reactive scene library는 **622개**(신규 14개: ACT I 텍스처 4 + BLIND DECK 동행 관찰 6 + 미탐색 pair 4)이며, 인물별로는 미라 100 / 준 84 / 다렌 75 / 노아 80 / 세나 74 / 소렌 65 / 루칸 63 / 마렌 81이다. 21개 서로 다른 pair 조합(이전 17개).

전용 0.7.0 회귀는 `story_070_consistency.gd`(278건, 필수 reveal 존재 여부 포함), `act2_070_tests.gd`(26건, 슬롯별 순차 잠금 해제), `character_arc_070_tests.gd`(115건), `act2_070_simulation.gd`(20 seed, 520건, dead-end 0건, THRESHOLD reveal 20/20 도달)이다. 기존 test suite 전체(story_consistency/campaign_tests/voyage_tests/storylet_scheduler_tests/human_trace_061/human_aftermath_062/mira_content_tests/content_audit/ui_smoke/run_tests bot gate)를 로컬 Godot 4.7.2로 개별 실행해 확인했으며 기존 threshold를 낮추지 않았다(bot gate smart 80%/random 20%/passive 0%, Phase 1 baseline과 동일). save schema는 **v11**을 유지하고, 정식 Windows package/tag/GitHub Release는 사용자 요청 전까지 보류한다.

# 0.6.2 · HUMAN AFTERMATH · 2026-09-22

HUMAN TRACE의 선택→반응→story hook 흐름에 player-facing aftermath ownership과 source provenance를 명시했다. 중요한 residue는 ordinary optional content와 섞이지 않도록 continuation으로 표시하며, 반응은 dialogue, loop residue는 character action, 다음 mystery는 story hook이 각각 primary presentation을 맡는다. 새 relationship/memory/consequence 시스템은 추가하지 않았고 save schema v11을 유지한다.

전용 HUMAN AFTERMATH regression은 authored handling reaction, source event, inactive speaker, hidden selector truth, continuation priority, save contract를 검사한다. 500-loop simulation, human-readable editorial report, 1366×768/1920×1080 전용 UI smoke와 visual capture를 추가했다. RED_SHIFT residue의 행동 주체와 speaker/portrait가 어긋날 수 있던 callback presentation 1건을 수정했다. 정식 Windows package/tag/GitHub Release는 사용자 정책에 따라 보류한다.

# 0.6.1 · HUMAN TRACE · 2026-09-22

- DEAD_AIR~LAST_LIGHT의 canonical resolution 뒤에 장별 3개 handling choice를 연결했다. 사실 자체와 chapter order는 분기하지 않는다.
- 기존 voyage choice pipeline, memory_tags, DialogueMemory, KnowledgeModel, evidence ownership, Notebook note를 재사용한다.
- 선택 뒤 최대 한 번의 짧은 authored reaction을 거쳐 기존 story hook으로 복귀한다.
- 이전 loop의 선택은 직접 기억 대사가 아니라 기록 배치·습관·echo처럼 작은 residue callback으로 돌아올 수 있다.
- 이미 본 동일 resolution은 결론 설명을 압축하되 현재 loop의 선택지는 유지하고 “장면 전체 보기” payload를 보존한다.
- Windows release workflow는 v* tag push 또는 workflow_dispatch에서만 실행한다. main VERSION 변경만으로 packaging/release가 시작되지 않는다.
- save schema는 실제 최신 저장소 기준 v11을 유지하며 migration을 추가하지 않는다.

# 0.6.0 · FIRST CONTACT / STORY LOOP · 2026-09-22

0.6.0은 FIRST CONTACT부터 LAST_LIGHT까지 조사 → 판단 → 결과 → 다음 질문의 장 흐름을 실제 플레이에 연결한다. CALIBRATION은 네 명의 승무원, 직접 조사 1회, 선택 상태 확인, discussion/review, 순차 합류를 유지하며 핵심 reveal은 Result 전에 경험 가능하도록 한다.

NPC 투표는 유효 대상이 있으면 자신이 아는 정보와 DecisionTrace를 바탕으로 대상을 선택한다. 빈 문자열 fallback 기권을 허용하지 않고, 기권은 legal target 부재 등 명시된 조건에서만 reason code·사람이 읽을 수 있는 reason·DecisionTrace와 함께 기록한다. Null도 동일한 투표 규칙 위에서 생존 전략을 사용하며 2-Null의 고정 담합 패턴을 만들지 않는다.

Null 배정은 play seed 기반 deterministic assignment와 recent-history soft anti-repeat를 유지한다. replay QA는 같은 stage의 여러 seed에서 single/pair 분포, history soft exclusion, same seed + same history 재현성을 검증한다.

잘못된 격리의 정보 비용은 지정된 다음 날에만 적용되며 이후 날짜와 다른 run/slot으로 전파되지 않는다. voyage memory와 reset 경계, FIRST CONTACT, story consistency, LAST_LIGHT 복수 history, Linux/Windows CI gate를 함께 검증한다.

# 0.5.7 · CLEAR SIGNAL · 2026-09-21

0.5.6 ECHOES까지 축적된 608개의 authored voyage/reactive scene과 Living Crew, Routine, Micro-Arc, Consequence, Motive, Incident, Codex를 삭제하거나 다시 만들지 않고 **한 loop에서 보이는 고중요도 서사의 밀도와 연결 순서**를 정리했다. 신규 authored voyage scene은 **0개**이며 save schema는 **v10**을 유지한다.

새 focus context는 플레이어가 실제로 본 loop focus family/event, 최근 visible focus, speaker exposure, explicit topic만 사용한다. hidden Null assignment, motive assignment, raw relationship float는 selector에 넣지 않는다. 실제 continuation과 authored FOLLOWUP/consequence, mandatory/progression은 새 스레드 예산을 소비하지 않으며 explicit topic과 direct pinned-question match도 계속 찾아갈 수 있다.

관련 없는 새 FOCUS family는 두 개까지 자연스럽게 열리고, 세 번째부터 soft weight가 낮아지며 네 번째 이후는 예외적으로만 나타난다. hard cap은 두지 않았다. 이미 보인 continuation에는 가중치를 주고, 한 화자에게 optional scene이 몰리면 speaker exposure로 완화한다. 미라의 ECHO WARD 이후 optional exposure 최대 **4회**는 유지된다. dense loop에서는 두 번째 autonomous beat를 삭제하지 않고 defer한다.

현실적인 public voyage path로 500 loop를 실행한 최종 기준은 high-salience distinct family 평균 **2.22**, P95 **3**, 최대 **4**, unrelated 4+ loop **11/500**, continuation **10회**, zero-meaningful consecutive **0**, visible signatures **500/500**, autonomous unique **23**, 0.5.3 authored coverage **59.3%**, rare immediate repeat **0**, Mira optional max **4**다. CLEAR SIGNAL invariant **47 checks**와 runtime exposure **10 checks**가 Linux validation과 Windows release-candidate gate에 연결됐다.

content audit은 608개 library 자체를 경고하지 않고 위 runtime gate로 노출 밀도를 검증한다. 반복 opener가 5회 이상이면 단순 단어 목록 대신 scene ID·speaker·action preview를 출력해 실제 편집 대상으로 바로 연결한다.

구현 기준 commit `dc3755eeac2b3420418daf1acac4d777cd8df05c`, GitHub Actions run `35572924051`에서 Linux validation / Windows validation / Windows release-candidate가 모두 GREEN이었다. VERSION 0.5.7 승격 commit `dc4292bcd53c64fa2128593a6e35c788f2c8f7c7`, RC run `35573583450`도 모두 GREEN이며 그 사전 RC ZIP(92,844,194 bytes)의 SHA-256은 `a9d1bdb0959c9d2dd3a51953daed48e8d146a7e33d17a1de862e1579d0a2f48b`이다. 이후 공식 tag commit `e4b20a77e7295ff4afa4c4ed086f738272d9409e`의 Windows run `35575857561`도 GREEN이었고, GitHub Release `v0.5.7`은 artifact `10627638550`의 `ASTRA-0.5.7-windows.zip`(92,844,194 bytes, SHA-256 `5ea10cb171ce3d42e66da54c3c14d2adff6f9648a3d86e8166146c016a0846ec`)을 공식 asset으로 사용한다.

# 0.5.6 · ECHOES · 2026-09-21

0.5.5 FAULT LINES까지 축적된 관계·DecisionTrace·Consequence·Living Crew를 다시 만들지 않고, **플레이어가 실제로 본 변화만 짧고 읽을 수 있게 되돌려 주는 피드백**과 **Observation Codex**를 완성했다.

Crew Archive의 observation은 총 **32개**다(STABLE 14 / OBSERVED 10 / ECHO 8, 8명 각 4개). 실제 awakening/authored scene/visible relationship milestone을 경험했을 때만 해금되며, hidden relationship float·motive·Null state·미표시 storylet을 근거로 자동 추론하지 않는다. Notebook은 현재 항해의 working memory, Archive는 항해를 넘어 남는 실제 목격 기록으로 역할을 분리했다.

관계 feedback은 같은 pair/day/axis의 작은 변화를 aggregate하고 미세 변화는 숨긴다. 밤은 즉시 consequence, 다음 날 briefing은 지속되는 relationship/opinion aftermath를 담당하도록 분리해 같은 문장을 연속 화면에서 반복하지 않는다. CALIBRATION의 Codex unlock은 저장하되 연속 toast는 생략한다.

save schema는 **v10**을 유지한다. v9/legacy hydrate는 known_people과 실제 seen scene처럼 안전하게 복원 가능한 근거만 사용하고, snapshot resume 뒤 이미 meta에 저장된 Codex pending을 정리해 result의 "새 기록" 중복을 막는다.

신규 authored voyage scene은 **0개**이며 전체 library는 **608개**를 유지한다. 최종 측정 캐릭터별 authored scene은 미라 98 / 준 81 / 다렌 74 / 노아 79 / 세나 71 / 소렌 64 / 루칸 62 / 마렌 79다.

0.5.6 전용 release gate는 Codex **95 checks**, ECHOES **33 checks**이며 Linux/Windows validation과 Windows release-candidate pre-build에 모두 연결했다. 기존 0.5.1~0.5.5 regression threshold는 낮추지 않았다.

# 0.5.5 · FAULT LINES · 2026-09-21

0.5.4 AFTERMATH의 Routine / Knowledge / Decision / Consequence 기반을 유지하면서 **Personal Motive → Dynamic Incident → Cooperative Investigation → Delegation → Loop Foreknowledge → Familiar Scene Compression → Narrative Momentum**을 연결했다.

Personal Motive는 ECHO WARD 이후 loop마다 일부 활동 중 NPC에게만 1~3개 배정되며 최대 3명이다. motive assignment는 Null 목록을 입력받아도 결과 계산에 사용하지 않아 **motive != Null**을 보장한다. 행동 목격·동행 조사·위임·incident 같은 서로 다른 source가 쌓일 때 HIDDEN → SUSPECTED → PARTIAL → REVEALED 내부 상태가 진행되지만 상태명/수치는 UI에 노출하지 않는다.

함선 Incident는 **8종**(COMMS_SPIKE / POWER_RELAY / DOOR_LOCK / NAV_DRIFT / OXYGEN_BALANCE / SAMPLE_CONTAINMENT / ARCHIVE_CORRUPTION / MEDICAL_SHORTAGE)이다. CALIBRATION/DEAD AIR/GLASS GARDEN에는 발생하지 않으며 한 loop 최대 1건, 실시간 카운트다운 없이 기존 action economy를 사용한다.

기존 companion을 Cooperative Investigation으로 확장했다. 핵심 fact는 동일하고 secondary observation만 인물 전문성에 따라 달라진다. SILENT ORBIT 이후에는 한 loop에 optional investigation 하나를 위임할 수 있으며 보고는 TESTIMONY 출처로 기록된다.

이전 loop에서 실제로 본 incident만 foreknowledge 선택이 열리며 사용은 loop당 최대 2회다. 선행 대응은 항상 이득이 아니라 원래 생성될 기록을 잃는 trade-off를 가진다. NPC는 플레이어가 경보보다 먼저 움직인 사실에 반응한다.

Notebook 정보에는 DIRECT / RECORD / TESTIMONY / RUMOR를 확률 대신 자연어 출처로 표시한다. 반복 장면은 seen count와 안전 조건을 모두 만족할 때만 압축하며 언제든 전체 장면을 펼칠 수 있다.

0.5.5 authored/reactive scene **71개**를 추가해 전체 library는 **608개**가 됐다. 신규 분배는 미라 10 / 준 9 / 다렌 8 / 노아 9 / 세나 8 / 소렌 9 / 루칸 9 / 마렌 9다. 19년 전 도착 뒤에도 일정 기간 정상 업무가 이어졌다는 평범한 post-arrival record 후보 4개를 추가하되 한 캠페인에서 최대 2개만 보이게 했다.

0.5.4 save의 신규 필드 부재는 optional nested default로 hydrate하며 강제 reset하지 않는다. 신규 CI는 motive/Null 독립성, chapter incident gate, foreknowledge 조건, 71 scene ID/초반 보호, specialist observation, 500-loop motive simulation, 1,000 incident simulation, human-readable editorial sample을 검증한다.

# 0.5.4 · AFTERMATH · 2026-09-21

0.5.3 HEARTBEAT의 Living Crew를 다시 만들지 않고 관계·기억·KnowledgeModel·DecisionModel·storylet scheduler를 **Crew Routine → Routine Deviation → Micro-Arc → Consequence** 흐름으로 실제 플레이에 연결했다.

정상 생활 baseline은 8명 합계 **36개 활동**, authored deviation은 **27개 상황 / 10개 reason tag**다. CALIBRATION과 DEAD AIR에는 눈에 띄는 routine deviation을 넣지 않고 GLASS GARDEN은 최대 1개, 이후 장은 최대 3개로 제한한다. ECHO는 loop 0에서 나오지 않고 NULL_ACTIVITY는 실제 Null만 사용할 수 있다.

여덟 명에게 4-beat 대표 micro-arc를 하나씩 추가했다: Mira Self Neglect, Jun Mistake, Daren Failed Model, Noa Private Copy, Sena Overprotection, Soren Listening Fatigue, Lucan Risk Route, Maren Save One Sample.

0.5.4 authored scene **64개**를 추가해 전체 voyage/reactive library는 **537개**가 됐다. 화자별 총량은 미라 88, 준 72, 다렌 66, 노아 70, 세나 63, 소렌 55, 루칸 53, 마렌 70이다. 소렌·루칸에는 각각 10개를 추가했다.

Consequence event는 **23개**다(IMMEDIATE 4 / DELAYED 8 / NEXT_DAY 7 / NEXT_LOOP 4). queue는 최대 12개이며 expiry가 있고, NEXT_LOOP event는 voyage memory를 통해 carry된다.

Curiosity Question은 한 개만 pin할 수 있다. 투표 변경은 DecisionTrace의 strongest reason을 이용해 new_evidence / relationship_change / memory_change / uncertainty로 구분하고, 개표 화면에서 이전 표와 현재 표, 이유를 짧게 보여 준다.

0.5.4 테스트에는 routine model, micro-arc, consequence chain, meaningful choice, curiosity pin, decision legibility, save compatibility, AFTERMATH 500-loop simulation, 5/20-loop human-readable editorial report를 추가했다.
# 0.5.3 · HEARTBEAT · 2026-09-21

0.5.2의 Living Crew / Knowledge / Decision 기반을 그대로 이어 받아, 그 시스템이 실제 장면과 반복 플레이에서 체감되도록 연결했다.

미라를 ASTRA의 **Emotional Anchor**로 강화했다. 정해진 연애 루트나 plot armor를 주지 않고 CARE / DAILY / MEDICAL / PLAYER / RELATIONSHIP / ECHO / CONFLICT 콘텐츠를 확장했다. authored speaker scene은 미라 80개로 가장 깊지만 중후반 한 루프의 optional Mira 노출은 최대 4개이며, 미라가 Null·격리 대상이 되는 기존 규칙도 그대로 유지한다. 미라 private event는 13개로 확대했다.

0.5.3 authored scene 81개를 추가해 전체 voyage/reactive scene library는 **473개**가 됐다. 화자별 총량은 미라 80, 준 65, 다렌 59, 노아 63, 세나 56, 소렌 45, 루칸 43, 마렌 62다. 관계 장면은 서로 앞 말을 실제로 받도록 line relation metadata를 추가했고, pair storylet은 이미 만난 활동 중 동료가 상황에 맞으면 자연스럽게 합류할 수 있게 했다.

새 `AstraStoryletScheduler`는 미노출 authored scene을 약간 우대하고 최근 family를 억제하며 rare/uncommon 이벤트에 내부 pity를 적용한다. RNG는 scene을 고를 뿐 대사를 생성하지 않는다. `AstraCrewActivityModel`에는 **27개의 autonomous crew beat**를 추가해 NPC가 플레이어와 대화할 때만 존재하는 느낌을 줄였다. 목격하지 못한 event는 정상적으로 지나갈 수 있다.

KnowledgeModel에는 NPC→NPC 명시적 전파 경로를 추가했다. A가 실제로 아는 사실만 B에게 전달할 수 있고, B가 C에게 말하기 전 C는 그 사실을 알지 못한다. player/private/public ownership은 Notebook의 가벼운 “정보 공유” 표시와 provenance에 연결된다. 자율 정보 공유에도 DecisionTrace가 남는다.

플레이어 행동 기억과 관계 callback을 강화했다. 미라는 evidence_first / people_first / protective / skeptical / secretive / confrontational / patient 패턴에 모두 반응할 수 있고, 약속·의료 비밀 존중·미라 지목/변호 같은 일부 행동은 뒤의 authored scene 조건이 된다. NPC끼리 공개적으로 변호한 사실도 다음 관계 장면에서 사용할 수 있다.

Curiosity Question은 Notebook의 **지금 궁금한 것**으로 표시하며 최대 3개만 보여 준다. 질문은 OPEN / PARTIAL / ANSWERED / CHANGED 상태를 사용하고, 해결했다고 생각한 질문도 다음 loop의 기록 변화로 다시 CHANGED가 될 수 있다.

검증에는 Mira content/agency/phrase audit, storylet pity와 multi-line coherence, autonomous active-state, knowledge propagation, relationship callback, player-visible 500-loop HEARTBEAT simulation을 추가했다. 검증 기준점에서 500 loop의 visible signature는 500/500, Mira optional exposure 평균 2.50/최대 4, autonomous 27종, 0.5.3 scene coverage 65.4%, rare 즉시 반복 0회였다.

## 0.5.2 · Living Crew · internal branch

0.5.2는 별도 정식 GitHub Release로 발행하지 않은 내부 Living Crew 개발 브랜치다. 0.5.1의 미완성 stabilization 작업을 회수하고 `AstraKnowledgeModel`, `AstraDecisionModel`, `AstraLivingCrew`, `AstraStorylets052`를 추가했다. 관계 5축, 캐릭터 baseline/deviation, player behavior profile, rolling dialogue memory, social theme/loop hook, knowledge provenance, vote DecisionTrace, curiosity question, 1,000 conversation / 1,000 meeting / 500-loop simulation이 이 브랜치에서 만들어졌다.

0.5.2의 코드와 테스트는 0.5.3의 기반으로 보존했다. 공식 릴리스 이력처럼 꾸미지 않고 internal branch로 기록한다.

## 0.5.1 · internal stabilization / incomplete branch

0.5.1은 정식 완결 릴리스가 아니라 0.5.0 이후 onboarding, unlock timing, slot intro, contextual help, objective/archive copy 정합성, meeting coherence, auto UX, 1366×768/1920×1080 검증을 누적하던 내부 브랜치였다. 이 작업은 폐기하지 않고 0.5.2와 0.5.3에 그대로 이어졌다.

# 0.5.0 · 2026-09-20

첫 30분의 시스템 노출을 다시 설계했다. CALIBRATION은 전원 패널 1회 + 미라와의 직접 대화 1회만 요구하고, DEAD_AIR는 조사/대화까지만, GLASS_GARDEN은 짧은 회의까지, ECHO_WARD부터 투표와 밤을 해금한다. 상단 단계 표시와 브리핑도 실제 챕터 흐름만 보여 준다.

모든 발언·투표·밤 행동의 대상을 단일 ACTIVE 참가자 규칙으로 통일했다. 장기수면 격리와 생체 신호 두절을 별개 상태로 표시하며, 자기투표·비활성 승무원 투표/발언/보호 대상을 모델 단계에서 차단한다. 투표 결과에는 NPC별 판단 이유가 기록된다.

회의는 무작위 독백 묶음 대신 논점 단위의 연결 대화로 바꿨다. 한 사람이 의혹을 제기하면 지목된 사람이 즉시 답하고, UI에는 새 논점/직전 발언에 대한 답을 표시한다. 자동 진행은 중요한 발언에서 실제로 일시정지되며 계속 버튼이 보인다.

캐릭터 콘텐츠를 대폭 확장했다. 탐색용 작성 장면은 170개에서 **280개**로 늘었고 캐릭터별 장면 수를 28~36개로 다르게 배분했다. 핵심 관계 8쌍에는 최소 2개 이상의 전용 장면을 추가했고 3인 대화 4개를 넣었다. 개인 이벤트는 캐릭터별 4~6개, 총 **40개**로 늘려 날짜·신뢰·긴장 조건에 따라 다른 장면이 나온다.

대화 결과는 숨은 수치 대신 **납득함 / 흔들림 / 아직 저항함 / 불확실 / 화남**으로 즉시 피드백한다. 새 승무원이 깨어나는 장면은 여러 인물이 함께 반응하는 짧은 입장 장면으로 다시 작성했다.

검증 체계도 강화했다. 기존 규칙·저장·UI·사회추리·반복 플레이·항해 테스트에 더해 1,000개 이상의 생성 투표 불변조건, 260개 이상 장면/40개 이상 개인 이벤트/핵심 관계 장면을 검사하는 content audit, 첫판과 7개 장 연속 서사 정합성 검사를 릴리스 게이트로 추가했다. GitHub Actions는 Linux 검증과 별도로 Windows 가상 PC에서 Godot 4.7.2 import, 모델 테스트, UI smoke, 메인 장면 부팅을 실제 실행한다.

# 0.4.2 · 2026-09-20

순서 독립적인 pair_history(과거 관계)와 다섯 축으로 나뉜 echo_state(감정 잔향)로 관계 시스템을 다시 짰다. CALIBRATION·DEAD_AIR·GLASS_GARDEN의 방 목록과 완료 조건, 챕터별 AP 예산을 데이터로 옮겨 초반 난이도를 낮췄다. 선택 effect를 11종으로 넓히고 8인의 "trust" 장면 선택지를 각자 다르게 다시 썼다. 남은 살인사건-시대 잔재 문구를 정리하고 `content_audit.gd`를 실제 품질 게이트로 승격했다. 상세: [릴리스 노트](docs/RELEASE_NOTES.md).

# 0.4.1 · 2026-09-19

새 8인 캐릭터 및 이미지, 4인 첫 각성, 단계별 합류, 탐색과 170개 장면, 목적지·과거 관계 변화, 감정 잔향 저장, 물품 백업, 동일 1표와 화자 중심 회의를 적용했다. 이번 패스에서 첫판을 한 곳(의료실)으로 좁히고, 캠페인 6개 장의 옛 살인사건 플롯(Ives/Orin 등)을 voyage 서사에 맞춰 전면 재작성했다. 상세: [릴리스 노트](docs/RELEASE_NOTES.md).

# ASTRA CHANGELOG

## 0.4.0 — First Contact (2026-09-18)

전체 내용은 `docs/RELEASE_NOTES.md`, 설계 판단 근거는 `docs/WHY_CHANGED.md`에 있습니다.

### 타이틀 · 저장
- 타이틀 문구를 "처음 시작 / 새로 시작 / 이어하기"로 교체. 세계관 용어 대신 동작 이름으로.
- 저장 슬롯 3개. 칸마다 사건·일차·단계·저장 시각과 [이어하기] [삭제]. 새 사건은 빈 칸 우선.
- 0.3.1의 단일 저장은 첫 실행 시 1번 칸으로 자동 이전. 덮어쓰기 경고 제거.

### 첫 경험
- 60초 이내 콜드 오픈 12비트. 클릭 진행, 첫 프레임부터 건너뛰기 가능.
- 왜 Null을 찾는지 오프닝과 브리핑이 직접 설명. 브리핑을 "무슨 일이 있었나 /
  사고가 아닌 이유 / 당신이 할 일" 세 단으로 재구성.
- 새 튜토리얼 사건 **CALIBRATION** — 4인 · 3장소 · Null 1 · 단서 6 · 1일 · 회의 1회.
  Null과 무고한 거짓말쟁이가 함께 들어 있어 "거짓말 = 범인"이 아님을 직접 겪습니다.
- 튜토리얼 사건에 변주 3종(통신 차단·전력 차단·기록 삭제). 장소·시각·도입 문구가 시드로 바뀝니다.
- 튜토리얼 단서를 6개에서 5개로 축소(흔적 2개 → 1개). 안내 문구를 더 쉬운 말로 재작성.
- 첫 실행 질문은 하나. "사회추리 게임은 처음이신가요?"
- 타이틀은 처음 켰을 때 버튼이 하나.

### 읽기
- 타입 스케일 5단계로 통일(`T_DISPLAY`~`T_META`). 본문 19px, 최소 16px.
- 인물 스테이지를 원화와 같은 3:4로 맞추고 잘라내기 대신 맞추기로 변경. 초상 잘림 해소.
- 아트 위 맨몸 텍스트 제거. 모든 글 블록이 불투명 패널 안으로.
- 심문 좌측 컬럼·질문 목록·개인 면담 스크롤화. 잘림 해소.
- 회의 자동 재생(0.55초) 제거. 클릭 진행이 기본, 자동은 옵션이며 중요한 대사에서 멈춤.
- 회의에서 다음 발언을 누르면 그 발언으로 자동 스크롤.

### 인물 식별
- 이름을 한글로 표기 (미라·로우·엘리·세나·베일·노아·리라·닥스).
- 이름이 나오는 모든 곳에 얼굴 아이콘과 직책 병기. 전신 SD 스프라이트는 작은 크기에서
  식별되지 않아 원화에서 얼굴만 잘라낸 192px 아이콘으로 교체.
- 처음 보는 인물은 한 명씩 등장 카드로 소개.
- 사람을 고르면 그가 누구를 왜 의심하는지 표시. 수치는 노출하지 않음.

### 안내
- 현재 목표 줄 상시 표시. 하루의 6단계 스테퍼.
- 남은 행동력을 테두리 박스 + pip으로 표시.
- 할 일이 끝나면 다음 버튼이 초록 ✔로 전환.
- 조사 지점에 금색 링, 장소 버튼에 남은 개수 표시, 튜토리얼에서 타겟 강조.
- 튜토리얼은 조사·심문을 끝내야 다음 단계로 진행.
- 모든 단서에 "이게 무슨 뜻이죠?" 해설 + 용어 각주. 정답은 말하지 않음.
- 3층 도움말: 툴팁 / 화면별 [?] / 해금된 항목만 보이는 Codex.

### 사회추리
- **주장 기록(Claim Ledger)** — 공개 발언 전부 저장, 자기모순 탐지, 철회 기록.
- **대질** 추가 — 두 사람에게 위치를 다시 말하게 합니다. 어긋나면 공개 모순으로 남고,
  맞으면 두 사람 다 의심에서 멀어집니다. 회의 발언권 1회 소모.
- 개표에 조사관의 2표를 별도 행으로 표시하고 총합 산식을 명시.
- 조사관의 발언도 기록. NPC가 플레이어의 행동 패턴을 근거로 공개 지적.
- 투표 직전 상위 의심 대상 2인의 마지막 진술.
- 개표를 한 표씩 공개. 조사관의 2표를 목록에 명시.
- 회의 발언 수 제한, 같은 사람의 연속 발언 금지.

### 대사
- 고빈도 키에 캐릭터별 변형 2개씩 추가 (256줄).
- 질문 3종 추가: 목격 / 시간축 / 신뢰.
- 성격별 회피 반응(`deflect`) 추가.
- 최근 18줄 기억으로 같은 문장 연속 출현 방지.

### 반복 플레이
- Null 배정에 최근 이력 감쇠 적용. 특정 인물 편중 방지.
- 판 종료 시 이번 재구성 요약, 패배 시 놓친 것 제시.
- 두 번 지면 게임이 먼저 스토리 속도 제안.
- `tests/replay_variety.gd` 신설.

### 해금
- 11단계 점진적 해금. 잠긴 기능은 회색이 아니라 **비표시**.
- 해금 시 기능 설명 + 세계관 한 줄.

### 난이도
- 스토리 / 표준 / 전문가. 쓸모없는 단서를 늘리지 않고 사람의 행동으로 조절.

### 모션
- 초상 상시 호흡 애니메이션 제거, 답변 pulse 제거, 화면 흔들림 제거.

### 자산
- 투명 누끼 16장, 텍스트 없는 키아트 3장, SD 도트 8종 편입.
- 나머지 25장은 참고용. 근거는 `docs/ASSET_AUDIT.md`.

### 호환 · 검증
- 0.3.1 저장(v1 스냅샷 포함) 그대로 로드.
- 신규 테스트 `social_tests.gd`(748) · `replay_variety.gd`(42).
- 기존 테스트 전부 유지: `run_tests`(41,687) · `campaign_tests`(108) · `redesign_tests`(954).

## 0.3.1 — 마지막 교신 (2026-09-18)

- 투명 캐릭터 32개, 장소 배경 8장, 단서/장비 아이콘 통합.
- 타이틀, 장소 조사, 접이식 노트, 수동 가설과 회의 제시.
- 개표 전 표·관계 수치 숨김, 상황별 질문과 개인 대화, 백업/휴식.
- 체험형 첫 사건 안내, 진실 재구성과 기억 조각, 접근성 설정.
- 기존 저장 호환 검증, 새 규칙 및 리소스 테스트 추가.

# ASTRA CHANGELOG

## 0.3.0 — Last Light

- 8인 캐릭터 초상화를 애니메이션풍 아트로 교체하고 타이틀·승무원 아카이브·조사 화면 개편.
- 현재 단계와 남은 행동, 다음 목표를 강조하고 넓어진 콘텐츠 영역 및 키보드 포커스 제공.
- 캠페인 6개 챕터, 사건별 추가 임무 및 기록으로 확장.
- 전용 사건 배경 6종과 진행 중 사건 자동 저장·이어하기 추가.
- 노트 전환을 N으로 이동하고 Tab은 표준 버튼 포커스로 사용.
- Windows 아이콘·제품 버전 정보를 추가하고 엔진·게임 데이터를 내장한 exe 및 SHA-256 제공.
- 소스 실행기는 엔진 버전을 확인하고 매 실행 전 변경된 에셋을 가져오며 오류를 로그에 보존.
- Windows CI에서 규칙·UI 테스트 후 실제 Windows 실행판을 부팅해야 배포하도록 강화.
- 기존 저장 데이터 호환 유지.

## 0.2.0 — Night Cycle (rebuild)

분석 결과와 근거는 `docs/ANALYSIS_0.2.0.md`에 있습니다.

### 실행 · 인터페이스
- `run_astra.bat`: Godot 4.7 자동 탐색(환경 변수 · `godot_path.txt` · PATH · 다운로드/바탕화면/문서 폴더), 첫 실행 에셋 가져오기, 게임/에디터 실행.
- Windows 내보내기 프리셋과 `tools/build_windows.bat`, 태그를 올리면 `ASTRA-x.y.z-windows.zip`을 Release로 올리는 워크플로.
- 창이 화면보다 크면 자동 축소, 비율 유지 스케일, `F11` 전체 화면, 설정(음량 · 회의 속도 · 안내 문구 · AI).
- 화면 전면 재설계: 상단 단계 표시줄 + 행동력, 단계 안내 문구, 승무원 명단(신뢰·긴장·내 판단 표시·투표 의향), 단계별 중앙 화면, 우측 노트(단서 · 추리 노트 · 기록), 하단 다음 단계 버튼(남은 행동력 경고).
- 심문 답변이 스크롤 아래로 숨던 문제, 이벤트 본문이 가려지던 문제, 노트북 보드가 잘리던 문제, 투표 버튼이 묻히던 문제 해결.
- AI 서버가 없어도 매 질문마다 연결을 시도하고 개발용 주소를 노출하던 문제 해결(설정에서 켤 때만 동작, 연결 확인 기능).
- 첫 실행 안내, 게임 내 플레이 방법, 일시 정지 메뉴, 단축키(Space · 1~8 · M · Tab · Esc · F11).

### 게임성
- **추리 구조 재설계**: 단서가 범인 이름을 직접 말하지 않음. 흔적은 후보 명단을 주고, 같은 조작의 흔적 두 개를 교차해야 실행자가 드러남.
- 모든 승무원의 실제 위치와 진술을 생성: 출입 기록·목격자와 대조해 거짓말을 찾는 알리바이 퍼즐.
- 사건마다 사정이 있어 거짓말하는 **무고한 승무원** 1명(추궁하면 사연을 털어놓음).
- **밤 단계 신설**: Null의 습격과 증거 인멸, 플레이어의 보호/감시, 막아 냈을 때 새 단서.
- **공개 회의 재설계**: 알리바이 공개, 목격자 반박과 Null의 맞반박, 의심 발언, 조사관 발언권 2회(단서 공개 · 지목 · 변호), 실시간 투표 의향.
- 심문 7종(알리바이 · 단서 제시 · 모순 추궁 · 의심 인물 · 긴장 완화 · 압박 · 속마음), 거짓말 징후, Null의 **실언**.
- 개인 면담 8종을 캐릭터별로 새로 작성: 선택에 따라 단서 · 반응 관찰 · 순찰 허가 · 회의 중재 등 실제 효과. 상대가 Null이면 거짓 정보가 섞일 수 있음.
- 조사 방식 재정의: 분석관(조사 +1) · 공감관(심문 +1, 징후 포착) · 감사관(검시 기록, 격리자 감사). 기존 보너스가 사라지던 버그 수정.
- 사건별 난이도 차등(무관한 흔적 · 알리바이 맞추기 · 인멸 확률), 매 판 새 배치.
- 추리 보고서는 명단의 `N` 표시 두 명으로 투표와 함께 제출. 채점·등급(S~D) 재설계, 회의 질문 무한 점수 버그 제거.

### 대사 · 선택지
- 한국어 조사 자동 처리(`은(는)` 표기 제거).
- 캐릭터별 말투로 대사 전면 재작성: Mira 해요체, Rho·Eli 반말, Sena 다나까체, Vale 공손한 해요체, Noa 짧은 인용체, Lyra 따뜻한 해요체, Dax 하다체.
- 선택지 문구를 결과가 예측되도록 정리하고, 효과 힌트를 함께 표시.

### 구조 · 품질
- 버전별 상속 스크립트(`main_v004`~`main_v011`, 상태 6단 상속)를 제거하고 `scripts/core`(규칙) / `scripts/ui`(화면) / `scripts/fx` / `scripts/net`으로 재구성.
- 테스트: 사건 생성 불변식(450건), 단계·행동력·저장 규칙, 봇 시뮬레이션 밸런스, 헤드리스 UI 스모크. CI에서 전 스크립트 파싱 검사.
- 아카이브 저장 v5(v4 호환).
- `release/0.1.2`의 손상된 base64 초상화 에셋은 사용 불가로 판단해 포함하지 않음.


## 0.1.1 — Character Performance
- Added animated character portrait presentation with fade/scale transitions.
- Added name, job, and expression-state overlays to the portrait area.
- Added response cues for interrogation intents.
- Added meeting Speaker Spotlight that sequences claim/challenge/interjection cards.
- Added cinematic phase transition banners for the full investigation loop.
- Expanded procedural audio feedback for selection, dialogue, phase changes, unlocks, and case completion.
- Added case-specific opening stings and stronger evidence-acquired feedback.
- Added `main_v011.gd` / `main_v011.tscn` as the 0.1.1 entry point.
- Added presentation-specific headless smoke coverage to Godot CI.

## 0.1.0 — First Vertical Slice
- Added INCIDENT ARCHIVE campaign-style title screen.
- Added sequential incident unlocks: Dead Air → Glass Garden → Echo Ward.
- Added replay access for cleared incidents.
- Added per-case completion status and best CASE THEORY score display.
- Added three Investigator Protocols: ANALYST, EMPATH, AUDITOR.
- Upgraded Archive persistence to save v4 with per-case best theory records.
- Added explicit post-case progression and next-incident guidance.
- Added `docs/VERTICAL_SLICE_010.md`.
- Added vertical-slice CI covering campaign unlock rules and initialization of all three incident templates.
- Added `main_v010.gd` / `main_v010.tscn` as the 0.1.0 entry point.

## 0.0.9 — Case Analysis
- Added two-suspect CASE THEORY submission before each isolation vote.
- Added final deduction grading (0–100) and S/A/B/C/Fragmented labels.
- Added evidence-support / contradiction / confidence calibration to theory review.
- Added cinematic Incident Stage cards for all three cases.
- Expanded private character scenes from two choices to three.
- Added persistent theory statistics to Archive save v3.
- Added CI smoke test covering state setup, investigation, and theory submission.

## 0.0.8
- Player-authored hypothesis links.
- Echo Ward case.
- Personal events and feedback FX.
- Godot 4.7.2 CI.
