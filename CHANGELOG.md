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
