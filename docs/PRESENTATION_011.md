# ASTRA 0.1.1 — Presentation Layer

0.1.1의 목표는 추리 규칙을 바꾸는 것이 아니라, 이미 존재하는 캐릭터·회의·사건 흐름이 실제 게임 장면처럼 느껴지도록 연출 계층을 추가하는 것이다.

## Character Presentation
- 기존 초상화 에셋을 그대로 사용한다.
- 인물 선택이 바뀌면 portrait가 fade + scale-in 된다.
- 초상화 위에 이름 / 직업 / 현재 expression slot을 표시한다.
- expression slot은 기존 `calm / warm / tense` 체계를 그대로 사용한다.
- 심문 동작 뒤에는 ALIBI RESPONSE, EVIDENCE REACTION, PRESSURE RESPONSE 같은 cue를 잠시 표시한다.
- 연출 계층은 Truth / suspicion / trust 값을 직접 수정하지 않는다.

## Meeting Speaker Spotlight
- MEETING 진입 시 최대 4개의 핵심 meeting event를 상단 카드로 순차 재생한다.
- `claim` → PUBLIC CLAIM
- `challenge` → CHALLENGE
- `defend` → INTERJECTION
- 카드 색상은 실제 speaker의 accent를 사용한다.
- 기존 상세 회의 로그는 유지되므로 연출을 놓쳐도 정보가 사라지지 않는다.

## Phase Feedback
단계가 바뀔 때 중앙 상단 배너를 표시한다.
- BRIEFING — INCIDENT BRIEF
- INVESTIGATION — FIELD INVESTIGATION
- INTERROGATION — PRIVATE INTERROGATION
- MEETING — PUBLIC MEETING
- VOTE — CASE THEORY / ISOLATION
- RESULT — INCIDENT CLOSED

증거를 새로 확보하면 별도의 `EVIDENCE ACQUIRED` 배너를 표시한다.

## Audio
외부 음원 파일 없이 `AudioStreamGenerator`로 짧은 procedural tone을 생성한다.
- select
- talk
- evidence
- phase
- alert
- unlock
- complete
- case opening sting

향후 실제 사운드 에셋으로 교체하더라도 호출 키는 유지할 수 있다.

## Safety / Truth Boundary
연출 코드는 게임의 진실 그래프를 변경하지 않는다.
- Null 역할 변경 금지
- 증거 생성/삭제 금지
- NPC suspicion 직접 조작 금지
- CASE THEORY 점수 변경 금지

Presentation은 화면과 사운드만 담당한다.

## CI
0.1.1부터 별도 presentation smoke test가 다음을 headless로 생성한다.
1. TextureRect + character presentation
2. 감정 표시와 response cue
3. meeting cinematic
4. meeting event 재생/종료

이 테스트와 기존 전체 GDScript 검사, CASE THEORY test, Vertical Slice test, main scene boot가 모두 성공해야 release를 main으로 승격한다.
