# ASTRA 0.2.0 — NIGHT CYCLE

고장 난 우주선에서 벌어지는 **1인용 마피아(소셜 디덕션) 추리 RPG**입니다.
승무원 8명 중 2명은 Null. 두 Null은 사건 당시 서로 다른 장소에서 조작을 하나씩 실행했습니다.
흔적과 알리바이를 맞춰 거짓말을 찾아내고, 회의에서 여론을 움직여 **최대 4일 안에** 두 명을 모두 격리하세요.
밤이 되면 Null도 움직입니다.

> 0.2.0은 0.1.x의 문제(실행·화면 사용성, 추리가 성립하지 않는 구조, 버전을 덧칠한 코드)를 분석해 게임 전체를 다시 만든 버전입니다.
> 무엇이 왜 바뀌었는지는 [`docs/ANALYSIS_0.2.0.md`](docs/ANALYSIS_0.2.0.md)에 정리했습니다.

## 실행하기

### 방법 1 · 실행 파일 (Godot 설치 불필요)
[Releases](../../releases)에서 `ASTRA-0.2.0-windows.zip`을 받아 압축을 풀고 `ASTRA.exe`를 실행하세요.
(Releases가 비어 있다면 Actions 탭 → **Windows build** → 최신 실행의 Artifacts에서 받을 수 있습니다.)

### 방법 2 · 더블클릭 실행기 (Windows)
1. [Godot 4.7.x](https://godotengine.org/download/windows/) (Standard)를 받아 압축을 풉니다.
2. 이 저장소 폴더의 **`run_astra.bat`** 을 더블클릭합니다.
   - 다운로드·바탕화면·문서 폴더에서 Godot을 자동으로 찾습니다.
   - 못 찾으면 안내가 뜹니다. 폴더에 `godot_path.txt`를 만들고 Godot exe 경로를 한 줄로 적으면 됩니다.
   - 첫 실행 때만 에셋을 가져오느라 1분 정도 걸립니다.
   - `run_astra.bat --editor` 로 실행하면 Godot 에디터로 프로젝트가 열립니다.

### 방법 3 · Godot 에디터
Godot 4.7.x 실행 → **가져오기** → 이 폴더의 `project.godot` 선택 → **가져오기 및 편집** → `F5`.

### 직접 실행 파일 만들기
에디터 메뉴에서 **내보내기 템플릿 관리**로 4.7.2 템플릿을 설치한 뒤 `tools/build_windows.bat` 실행 → `build/ASTRA/ASTRA.exe`.

## 플레이 요약

| 단계 | 할 일 |
|---|---|
| 브리핑 | 사건 시간대와 두 조작(무엇이, 어디서, 몇 시에)을 확인. 2일차부터는 밤사이 보고 |
| 현장 조사 | 구역을 조사해 단서 확보. 흔적은 범인 이름 대신 **후보 명단**을 준다. 같은 조작의 흔적 두 개의 **교집합**이 실행자 |
| 개인 심문 | 알리바이를 모아 출입 기록과 대조. 모순을 추궁하면 **숨긴 사정**(무고한 거짓말)이나 **실언**(Null의 결정적 실수)이 나온다 |
| 공개 회의 | 모두의 알리바이 공개와 반박. 발언권 2회로 **단서 공개 · 지목 · 변호**. 투표 의향이 실시간으로 보인다 |
| 격리 투표 | 조사관의 표는 2표. 두 명을 `N`으로 표시해 두면 **추리 보고서**가 함께 제출돼 채점된다 |
| 밤 | Null이 한 명을 습격하고 흔적을 지운다. **보호** 또는 **감시**로 막으면 침입자의 흔적이 새 단서로 남는다 |

- **조사 방식**: 분석관(조사 +1) · 공감관(심문 +1, 거짓말 징후 파악) · 감사관(검시 기록 보유, 격리자 정체 감사)
- **사건 3개**: DEAD AIR → GLASS GARDEN → ECHO WARD. 뒤로 갈수록 시간대 밖의 가짜 흔적, 서로 알리바이를 맞춘 Null, 적극적인 증거 인멸이 늘어납니다. 매 판 Null·위치·단서 배치가 새로 섞입니다.
- **단축키**: `Space` 다음 단계 · `1~8` 승무원 선택 · `M` 표시 변경 · `Tab` 노트 탭 · `Esc` 메뉴 · `F11` 전체 화면

자세한 규칙은 게임 안 **플레이 방법**과 [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)에 있습니다.

## 프로젝트 구조

```
scenes/main.tscn            진입 씬 (scripts/ui/app.gd)
scripts/core/               게임 규칙 — UI와 분리된 순수 로직
  game_session.gd           한 사건의 상태 머신 (단계, 조사, 심문, 회의, 투표, 밤, 채점)
  case_generator.gd         시드 기반 진실·알리바이·단서 생성
  case_catalog.gd           사건 3개 데이터
  crew_catalog.gd           승무원 8명 데이터와 추리용 특성표
  dialogue_bank.gd          캐릭터별 말투로 쓴 대사
  private_events.gd         캐릭터별 개인 면담과 선택지
  josa.gd                   한국어 조사(은/는, 이/가…) 자동 처리
  meta_progress.gd          아카이브 저장 (v4 세이브 호환)
  settings.gd               설정 저장
scripts/ui/                 화면 (타이틀, 게임 화면, 단계별 뷰, 노트, 모달)
scripts/fx/                 배너·토스트·절차 생성 효과음, 별 배경
scripts/net/                선택형 AI 백엔드 연결 (기본 꺼짐)
tests/                      헤드리스 테스트 (규칙·생성기·저장·밸런스 시뮬레이션·UI 스모크)
backend/                    선택형 AI 대사 연기 서버 (FastAPI)
tools/build_windows.bat     Windows 실행 파일 빌드
```

## 테스트

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/ui_smoke.gd
```

`run_tests.gd`는 규칙 검사와 함께 **추리 봇 / 무작위 봇 / 방관 봇**으로 수백 판을 돌려 “추리해야 이기고, 가만히 있으면 진다”는 밸런스를 확인합니다. GitHub Actions(`Godot CI`)가 push마다 전부 실행합니다.

## AI 대사 연기 (선택)

`backend/`의 로컬 서버를 켜고 게임 **설정 → AI 연기 사용**을 켜면, 심문 대사를 모델이 캐릭터 말투로 다시 연기합니다.
AI는 표현만 바꾸며 진실·단서·점수에는 관여하지 않습니다. 꺼져 있어도 모든 기능이 동작합니다. → [`backend/README.md`](backend/README.md)

## 문서

- [`START_HERE.md`](START_HERE.md) — 처음 실행하는 사람을 위한 안내
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — 0.2.0 규칙과 시스템 설계
- [`docs/ANALYSIS_0.2.0.md`](docs/ANALYSIS_0.2.0.md) — 0.1.x 분석과 개편 내역
- [`docs/CHARACTERS.md`](docs/CHARACTERS.md) — 캐릭터 바이블 (말투, 숨긴 사정 포함)
- [`AGENTS.md`](AGENTS.md) — 코드를 고치는 사람/AI를 위한 규칙
- [`CHANGELOG.md`](CHANGELOG.md)
