# START HERE — ASTRA 0.0.8

1. Godot 4.7.2 stable 권장
2. `project.godot` Import
3. F5
4. AI 서버 없이도 플레이 가능

## 새 추리 보드 조작
- 증거 노드 클릭 → Crew 클릭: 의심 연결
- Shift + Crew 클릭: 해명 연결
- Ctrl/Cmd + Crew 클릭: 질문 연결
- 우클릭 Crew: 선택 증거와의 사용자 연결 삭제

## 자동 검사
GitHub Actions의 `Godot CI`가 main/release 브랜치 push와 PR마다 headless import/parse 검사를 수행합니다.
