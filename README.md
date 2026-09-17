# ASTRA 0.3.0 — LAST LIGHT

고장 난 우주선, 여덟 명의 승무원, 두 명의 잠입자. 흔적과 알리바이를 교차하고 회의에서 동료를 설득하는 **1인용 우주 마피아 추리 RPG**입니다.

## 다운로드하고 바로 실행

**[Windows 실행판 다운로드](https://github.com/zx5598t/Astra/releases/latest)** → `ASTRA-0.3.0-windows.zip` → **모두 압축 풀기** → 폴더 안 **`ASTRA.exe` 더블클릭**.

Godot, Python, 서버, 별도 설치 프로그램은 필요 없습니다. GitHub의 `Source code (zip)`은 개발용 소스입니다. Windows 10/11 64비트용이며, 실행판은 엔진과 게임 데이터를 하나의 exe에 담았습니다.

## 0.3.0의 변화

- 참고 이미지의 방향을 살린 **8인 애니메이션풍 캐릭터 초상화**, 인물 중심 타이틀과 승무원 아카이브.
- 현재 단계·남은 행동·다음 목표를 구분한 화면, 넓어진 조사 영역과 추리 노트, 키보드 포커스.
- **6개 챕터**로 확장된 캠페인과 각 사건의 추가 임무. 수사 결과를 기록하고 다음 사건으로 나아갑니다.
- 챕터별 전용 배경 6종과 **진행 중 사건 자동 저장·이어하기**.
- Windows 아이콘·버전 정보, 실행 오류 로그, 내보낸 exe 자체의 자동 부팅 검사와 SHA-256 파일.

## 플레이 흐름

| 단계 | 할 일 |
|---|---|
| 브리핑 | 사건의 시각·장소·추가 임무 확인 |
| 현장 조사 | 두 조작의 흔적을 모아 후보 명단 교차 |
| 개인 심문 | 알리바이를 출입 기록과 비교하고 모순 추궁 |
| 공개 회의 | 단서 공개·지목·변호로 투표 의향에 영향 |
| 격리 투표 | 두 용의자를 N으로 표시해 추리 보고서 제출 |
| 밤 | 동료 보호 또는 구역 감시로 Null의 습격 저지 |

같은 조작의 **실제 흔적 두 개의 교집합**이 실행자입니다. 사건 시간대 밖의 흔적은 구분하세요. 무고한 승무원도 사적인 이유로 거짓말할 수 있습니다.

**단축키**: `Space` 다음 단계 · `1~8` 인물 선택 · `M` 판단 표시 · `N` 노트 탭 · `Tab` 버튼 포커스 · `Esc` 메뉴 · `F11` 전체 화면.

## 개발용 소스로 실행

Godot **4.7.2 Standard**의 압축을 풀고 `run_astra.bat`을 실행합니다. 자동 탐색에 실패하면 `godot_path.txt`에 실행 파일의 전체 경로를 적습니다. `run_astra.bat --editor`는 에디터를 엽니다. 실행 준비 오류는 `build/logs/source-import.log`에 남습니다.

같은 버전의 Windows Export Templates를 설치한 뒤 `tools/build_windows.bat`을 실행하면 테스트 → 내보내기 → 실행판 부팅 검사를 거쳐 `build/ASTRA-0.3.0-windows.zip`을 만듭니다.

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/ui_smoke.gd
```

`Godot CI`는 release 브랜치를 검증합니다. 통과 후 main에 반영하고 `v0.3.0` 태그를 올리면 Windows runner가 규칙·UI·실행판을 다시 검사하고 Release를 게시합니다.

게임 규칙은 `scripts/core/`, 화면은 `scripts/ui/`, 데이터는 `case_catalog.gd`와 `crew_catalog.gd`에 있습니다. `AGENTS.md`에 구조·밸런스 규칙이 정리되어 있습니다.

AI 대사 연기는 설정에서 선택적으로 켤 수 있습니다. 기본 게임은 완전히 오프라인으로 작동합니다. AI는 표현만 바꾸며 사건의 진실과 규칙은 바꾸지 않습니다. [백엔드 안내](backend/README.md)

[처음 플레이하기](START_HERE.md) · [변경 내역](CHANGELOG.md) · [캐릭터 설정](docs/CHARACTERS.md) · [엔진 라이선스](LICENSES.md)
