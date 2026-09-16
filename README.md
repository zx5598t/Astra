# ASTRA 0.0.6 — CASE SHUFFLE PROTOCOL

AI-native social deduction RPG 프로토타입입니다.

## 0.0.6 핵심
- **8명 캐릭터 / 남4·여4 유지**
- 매 Seed마다 **Null 2명의 신분을 무작위 배정**
- 캐릭터 직업/개성은 유지하고 숨겨진 역할만 바뀜
- **Dead Air / Glass Garden** 두 사건 템플릿
- 사건에 맞춰 핵심 증거의 대상과 알리바이 지지 단서가 자동 재배치
- **Investigator Notebook**: 증거 → 인물 연결, 알리바이, 직접 모순 후보 표시
- 최대 3 Day 루프와 이전 발언 기억 유지
- 공개 회의의 일부 발언도 선택적으로 AI가 연기
- AI 서버가 없으면 기존 규칙 기반 대사로 완전 플레이 가능

## 실행
1. Godot 4.x에서 `project.godot` Import
2. F5
3. 기본 씬은 `scenes/main_v006.tscn`

## AI 서버는 선택 사항
```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env   # Windows
# cp .env.example .env   # macOS/Linux
uvicorn app:app --host 127.0.0.1 --port 8787
```

`.env`의 `OPENAI_API_KEY`는 서버에만 둡니다. Godot 프로젝트나 GitHub에 API 키를 넣지 않습니다.

## 설계 원칙
`TruthEngine`과 게임 코드가 실제 역할, 증거, 투표, 승패를 결정합니다. AI는 허용된 사실만 받아 캐릭터다운 표현을 생성하는 연기 계층입니다.

## 다음 목표 — 0.0.7
- Notebook을 실제 노드/선 그래프로 시각화
- 표정별 실제 캐릭터 아트 슬롯
- 사건별 환경 배경과 장면 전환
- 캐릭터 간 개인 이벤트 / 관계 이벤트
- 세션 메타 진행 저장
