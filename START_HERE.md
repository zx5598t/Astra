# ASTRA 실행 시작하기 (Windows)

## 1) GitHub에서 게임 받기
1. Astra 저장소 화면에서 초록색 **Code** 버튼을 누릅니다.
2. **Download ZIP**을 누릅니다.
3. 받은 ZIP 파일을 원하는 폴더에 압축 해제합니다.

## 2) Godot에 프로젝트 등록
1. 설치한 **Godot 4.x**를 실행합니다.
2. 처음 뜨는 **Project Manager**에서 **Import**를 누릅니다.
3. 압축 해제한 Astra 폴더 안의 **`project.godot`** 파일을 선택합니다.
4. **Import & Edit**를 누릅니다.

## 3) 게임 실행
Godot 편집기가 열리면 키보드 **F5**를 누르거나, 오른쪽 위의 **▶ Run Project** 버튼을 누릅니다.

정상이라면 `ASTRA // SIGNAL LOST` → `INCIDENT ZERO` 타이틀 화면이 바로 뜹니다.

## 플레이 순서
`사건 브리핑 → 현장 조사 → 개인 심문 → 공개 회의 → 격리 투표 → 결과`

- 현장 조사: 행동력 3
- 개인 심문: 행동력 3
- 승무원 클릭: 해당 인물 선택
- 오른쪽 EVIDENCE / CASE LOG: 확보한 증거와 이전 발언 확인
- 다음 단계: 화면 아래 오른쪽 버튼

## 실행이 안 될 때
Godot 하단의 **Debugger / Errors**에 표시되는 빨간 오류 내용을 복사해서 ChatGPT에 보내면 해당 버전을 바로 수정할 수 있습니다.
