# ASTRA 0.0.7 — ARCHIVE & RELATIONSHIP PASS

0.0.6의 랜덤 사건/AI/3-Day 구조 위에 시각적 추리와 지속 진행도를 추가한 버전입니다.

## 핵심 변경
- Investigator Notebook을 **실제 노드/연결선 보드**로 시각화
- Dead Air / Glass Garden의 **서로 다른 환경 배경** 추가
- 8명 캐릭터에 `calm / warm / tense` **표정 슬롯 오버레이** 추가
- 호감/마찰 수치가 높은 두 NPC 사이에 **관계 이벤트** 발생
- 완료 사건과 Insight를 `user://astra_meta.cfg`에 **영구 저장**
- 타이틀/점수 영역에 Archive Rank와 누적 Insight 표시
- 기존 랜덤 Null, 2개 사건, 3-Day, AI 회의 연기, Offline fallback 유지

## 플레이
Godot 4.x에서 `project.godot` Import 후 F5.
AI 백엔드 없이도 전체 루프를 플레이할 수 있습니다.

## 저장
완료한 사건 수, 누적 Insight, 정확한 격리 수, 일부 관계 이벤트 기록이 Godot의 `user://` 저장 경로에 남습니다.

## 다음 목표 — 0.0.8
- 추리 보드에서 플레이어가 직접 연결선 생성/삭제
- 사건 3번째 템플릿
- 캐릭터별 개인 이벤트 선택지
- 사운드/전환/화면 흔들림 등 연출 패스
- 런타임 오류 자동 검사용 CI 보강
