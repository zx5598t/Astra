# ASTRA 0.5.0 구현 계획

## 변경 범위
scripts/core/{crew_catalog,case_catalog,case_generator,game_session,meta_progress,story_content,dialogue_bank,dialogue_variants,private_events,social_events,unlocks}.gd, scripts/ui/{app,title_screen,opening_view,game_screen,art,notebook_panel}.gd, views/{investigation,meeting,vote,result,interrogation}_view.gd, 신규 voyage_content.gd / voyage_view.gd, assets/art050, tests, VERSION/project.godot 및 플레이 문서.

## 보존과 대체
Claim Ledger, 진술 교차검증, 무고한 거짓말, NPC 관계, 플레이어 행동 기억, 최근 대사 감쇠, 저장 슬롯, 접근성, 오프라인 실행과 선택형 AI를 보존한다. 외부 탐사요원의 과거 재구성, 첫판 8인 공개, 교정 시험, 플레이어 2표, 투표 흔들림, 의미 없는 분 단위 비용은 대체한다. 기존 추리 엔진은 뒤 챕터에서 점진적으로 사용한다.

## 호환 ID와 이미지
| 저장 ID | 표시 인물 | 자산 ID | 직업 |
|---|---|---|---|
|mira|미라|mira|의무관|
|rho|준|jun|기관 엔지니어|
|dax|다렌|daren|시스템 설계자|
|noa|노아|noa|기록관|
|sena|세나|sena|보안 책임자|
|vale|소렌|soren|통신관|
|eli|루칸|lucan|항법사|
|lyra|마렌|maren|생태학자|
내부 ID를 유지해 기존 관계·진술·세이브 참조를 보존한다. 표시 이름과 새 자산 경로는 카탈로그에서만 해석한다. 제공된 94장 중 폴더별 대표 전신 8장, 인물별 상반신과 미니 얼굴 8종을 우선 연결한다. 다인 포즈 시트는 단일 인물 셀만 잘라 사용한다. 감정별 파일이 없으면 같은 인물 neutral로 복귀한다. 원본은 변경하지 않는다.

## 첫 경험과 스토리
제목 화면은 인물 없는 ASTRA 실내, 목적지 미확인, 시작/이어하기 중심. 탐사요원이 의료실에서 깨어나 미라, 준, 다렌, 노아를 만나며 수면실 전력과 서로 다른 목적지 기록을 확인한다. 첫 루프에는 전체 회의나 격리 시험 없이, 기록의 날짜가 바뀌는 순간으로 끝낸다.
CALIBRATION(호환 키/첫 각성) 4명 → DEAD AIR 4명 → GLASS GARDEN 세나 → ECHO WARD 소렌 → SILENT ORBIT 루칸 → RED SHIFT 마렌 → LAST LIGHT. 각성은 장면으로 제공하고 신규 기능은 그 후 필요할 때만 노출한다. 중반에는 오래된 도착 완료 기록을 발견하되 최종 원인은 확정하지 않는다.

## 상태와 대화
세션이 탐색 장소, 조사 기록, 대화 장면/선택, 지연 반응, 인물 동선, 목적지 기억, 과거 관계를 소유한다. 메타에는 감정 잔향/장기 신뢰와 지난 루프의 기억 차이를 저장한다. 현재 사건 의심·스트레스와 분리한다. 장면은 화자/상대/장소/관계/루프/발견 조건으로 선택하고 최근 장면·조합을 감쇠한다. 침묵, NPC 개입, 먼저 말 걸기, 선택 없는 장면과 1~4개 선택을 섞는다. 주요 정보에는 조사/대화의 복수 경로와 확정 재접근을 제공한다.

## 자유도와 미완성 감사
이동 후 바로 조사·대화, 동행/공유/관찰 선택과 결과를 지원한다. 장소별 hotspot 좌표와 사물명을 사용한다. 현재 목표와 요약은 짧게, 기록 상세는 선택적으로 연다. 기존 개인 이벤트 한 개/인물, 로봇 같은 다렌, 과도한 세나 군대체, 모든 질문을 기다리는 NPC, 30분/AP 이중 자원, 고정 hotspot, 투표 흔들림과 2표가 변경 대상이다.

## 우선순위 및 검증
P0 정체성/자산/첫 화면 → P1 실제 4인 시작/각성/루프 저장 → P2 완성된 장면 데이터 및 대사 재작성 → P3 탐색/회의/투표/노트 → P4 반복성과 밸런스.
Godot import와 기존 회귀 테스트, 신규 4~8인 생성/단서 일관성, 각성/감정/관계/장면/저장 왕복, 옛 세이브, 100 seed 장면 다양성, 1366×768 및 1920×1080 렌더 검사를 수행한다. 테스트 결과와 실제 구현 범위는 QA_REPORT 및 요구사항 추적 문서에 기록한다.
