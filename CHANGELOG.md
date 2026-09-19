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
