# START HERE — ASTRA 0.0.5

1. Godot 4.x 실행
2. Astra 폴더의 `project.godot` Import
3. F5
4. 기본 상태는 **Offline fallback**이므로 AI 설정 없이도 플레이 가능

## 선택: AI 대사 켜기
`backend/README.md` 절차대로 백엔드를 실행합니다.
백엔드가 `127.0.0.1:8787`에서 실행되면 대화 시 규칙 기반 결과 뒤에 검증된 AI 연기가 표시됩니다.

## 0.0.5 플레이 변화
한 명을 격리해도 곧바로 끝나지 않습니다. 최대 3일 동안 이전 발언과 관계를 기억하며 남은 Null을 추적합니다.
