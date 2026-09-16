# ASTRA 0.0.8 — OBSERVER HYPOTHESIS PASS

0.0.7의 Archive/관계/시각 Notebook 위에 **플레이어 가설 조작 + 3번째 사건 + 개인 이벤트 + 연출 + CI**를 추가한 버전입니다.

## 0.0.8 핵심
- Investigator Board에서 **증거를 직접 선택하고 Crew와 연결/삭제**
  - 클릭: 의심 가설
  - Shift+클릭: 해명 가설
  - Ctrl/Cmd+클릭: 질문표시
  - 우클릭: 사용자 연결 삭제
- 사용자 가설은 TruthEngine/NPC 의심도에 영향을 주지 않는 별도 레이어
- 3번째 Incident **Echo Ward** 추가
- 8명 각각의 성격을 반영한 **Private Channel 개인 이벤트 선택지**
- 사건 완료 기록 외에 개인 이벤트 선택/가설 편집 횟수도 Archive에 저장
- UI 클릭 / 증거 확보 / 투표용 가벼운 절차음과 화면 flash/shake 연출
- GitHub Actions에서 **Godot 4.7.2 stable headless import/parse 검사**
- 기존 랜덤 Null, AI 대화/회의, 3-Day, 관계 이벤트, 영구 Archive 유지

## 사건
1. Dead Air — 통신/전력 조작
2. Glass Garden — 생명유지/오염 조작
3. Echo Ward — 의료 기록/냉동수면 조작

## 실행
Godot 4.x에서 `project.godot` Import 후 F5.
AI 백엔드 없이 전체 핵심 루프 플레이 가능.

## 다음 목표 — 0.0.9
- 클릭형 가설을 실제 추리 제출 시스템으로 발전
- 각 사건 전용 피해자/장소 일러스트 확대
- 개인 이벤트를 짧은 분기 씬으로 확장
- BGM/공간음/캐릭터 보이스 블립
- CI 통과 이후 자동 웹 빌드/플레이 링크 생성
