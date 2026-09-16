# ASTRA 0.0.2 — INCIDENT ZERO: DEAD AIR

AI-native social deduction RPG의 첫 번째 **게임다운 플레이 가능 버전**입니다.

## 가장 쉬운 실행 방법

### 방법 A — Godot에서 실행
1. **Godot 4.x** 실행
2. Project Manager에서 **Import** 클릭
3. 이 저장소를 내려받은 폴더 안의 `project.godot` 선택
4. Import & Edit
5. 에디터 오른쪽 위 **▶ Run Project** 또는 키보드 **F5** 실행

### GitHub에서 받은 경우
1. GitHub 저장소의 **Code → Download ZIP**
2. 압축 해제
3. Godot → Import → 압축 푼 폴더의 `project.godot`
4. **F5**

## 0.0.2에서 달라진 점
- 타이틀 화면과 플레이 방법 화면
- 별이 움직이는 우주 배경
- 카드형 승무원 선택 UI
- 현장 조사 행동력 3
- 개인 심문 행동력 3
- 의료실 / 엔진실 / 통신실 각각 2개 증거
- 6개 증거 중 발견 순서가 Seed에 따라 변화
- 알리바이 / 동기 / 증거 제시 / 회유 / 압박
- 신뢰도·스트레스·기억·공개 주장 표시
- 공개 회의에서 NPC별 현재 의심 대상 표시
- 격리 투표와 NPC 투표
- 점수와 Case Confidence
- 결과 화면 및 즉시 재도전
- AI Gateway restricted schema / Claim Validator 골격
- AI API 없이도 완전 오프라인 플레이 가능

## 현재 사건의 목표
함장 Ives가 07:36~07:39 사이 사망했다. 승무원은 6명이고 그중 Null은 2명이다. 플레이어는 제한된 조사와 심문을 통해 증거와 증언을 비교하고 한 명을 격리한다.

## 중요한 설계 원칙
`TruthEngine`만 실제 사실을 결정합니다. NPC의 대사나 향후 연결할 LLM은 세계의 정답을 변경할 수 없습니다.

## 폴더 구조
```text
Astra/
├─ project.godot
├─ VERSION
├─ README.md
├─ CHANGELOG.md
├─ AGENTS.md
├─ scenes/
│  └─ main.tscn
└─ scripts/
   ├─ main.gd
   ├─ game_state.gd
   ├─ npc_state.gd
   ├─ truth_engine.gd
   ├─ ai_gateway.gd
   └─ starfield.gd
```

## 다음 목표 — 0.0.3
- 실제 AI backend 선택 연결
- NPC별 제한된 자연어 표현 생성
- Question Lattice
- NPC 간 자율 발언 / 끼어들기
- 캐릭터 초상화와 표정 연출
- 효과음 / UI 사운드
- 2차 사건 또는 다중 Day 구조
