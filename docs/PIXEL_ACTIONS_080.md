# 도트 캐릭터 동작 (0.8.0)

## 지금 들어 있는 것 — 그림을 새로 그리지 않고 만든 동작

도트 시트에는 **걷기 3프레임 × 4방향**만 그려져 있습니다. 게임은 이 프레임을 다시 그리거나 늘리지 않고,
몸을 세 띠(머리·상체·다리)로 나눠 **정수 픽셀 단위로만** 움직여 아래 동작을 만듭니다
(`scripts/ui/pixel/pixel_actor.gd`의 `MOTION_SHADER`). 다리는 항상 바닥에 붙어 있습니다.

| 동작 | 어디서 보이나 |
|---|---|
| 숨쉬기 (1px, 사람마다 박자 다름) | 서 있는 모든 사람 |
| 걷기 무게중심 (딛는 프레임에서 몸이 내려감, 옆으로 걸을 때 앞으로 기울기) | 걷는 모든 사람 |
| 말하며 끄덕임 | 대사가 나오는 동안 말하는 사람 |
| 끄덕임 · 두 번 끄덕임 · 고개 숙여 인사 · 갸웃 · 고개 젓기 · 한숨 · 떨림 | 대사 신호, 한가할 때 |
| 놀람 점프 · 기쁨 점프(두 번) · 점프 | 다가갔을 때(작업 중이던 사람), 과제 성공 |
| 무게 옮기기 (걷기 한 프레임을 잠깐) | 한가할 때 |
| 작업 자세 — 뒷모습(콘솔에 손), 옆모습(몸을 기울임), 정면(읽기) | 콘솔·작업대·문 앞 사람, 과제 중 탐사요원 |
| 앉기 (탁자가 다리를 가림) | 라운지 저녁 식사 |
| 두리번거리기 · 흘끗 보기 · 서성이기 | 한가할 때 (사람마다 성격에 따라 빈도 다름) |
| 말풍선 `!` `?` `…` `♪` · 땀방울 | 알아챔, 질문, 망설임, 기쁨, 긴장 |

방 안의 사람들은 탐사요원이 가까이 오면 하던 일을 멈추고 돌아보고(작업 중이던 사람은 처음 한 번 `!`),
멀어지면 잠시 뒤 다시 일로 돌아갑니다. 장면이 끝나면 탐사요원이 문 쪽으로 몇 걸음 걸어 나가고 사람들이 그 모습을 봅니다.
설정의 "흔들림·번쩍임 줄이기"를 켜면 점프·띠 움직임이 꺼지고 말풍선만 남습니다.

## 직접 그린 동작을 넣고 싶을 때 (선택)

그림으로만 가능한 동작(손을 드는 손짓, 의자에 앉은 다리, 콘솔을 두드리는 손, 놀라서 움츠림)은
**액션 시트**를 넣으면 그 동작만 그림으로 바뀝니다. 없는 사람은 지금처럼 만든 동작을 씁니다.

### 넣는 곳
- 승무원: `0.5.0 수정 인물 이미지/Astra/미니 도트 캐릭/액션/<한글 이름>.png` (예: `액션/미라.png`)
- 탐사요원: 걷기 시트와 같은 폴더에 `<같은 파일 이름>_action.png`
  (예: `assets/player_src/p1.png` → `assets/player_src/p1_action.png`. 임시 폴더를 쓰는 동안은 `임시/<파일 이름>_action.png`)

### 형식 — 걷기 시트와 같게
- 투명 배경 PNG, **3열 × 4행**, 크기는 자유(걷기 시트처럼 1254×1254 권장).
- 캐릭터 크기·비율·색은 걷기 시트와 같게. 걷기 시트와 **같은 배율로** 줄이므로, 크게 그리면 게임에서도 크게 나옵니다.
- 각 칸의 발(또는 앉은 엉덩이·의자 아래)이 칸 아래쪽에 오게.

| 행 | 동작 | 칸 1 | 칸 2 | 칸 3 | 게임에서 |
|---|---|---|---|---|---|
| 1 | 작업 (뒷모습, 두 손을 콘솔/책상 위에) | 손 위치 A | 손 위치 B | 손 위치 C | 뒷모습으로 일할 때 반복 |
| 2 | 말하기 (정면, 손짓) | 손짓 A | 손짓 B | 손짓 C | 정면으로 말할 때 반복 |
| 3 | 앉기 (정면, 의자에 앉음 — 다리는 탁자에 가려지니 대충이어도 됨) | 기본 | 말하는 입 | 웃음 | 식탁 장면 |
| 4 | 반응 (정면) | 놀람(어깨 올라감) | 끄덕임/생각 | 풀썩(한숨, 고개 숙임) | 놀람·끄덕임·한숨 제스처 동안 |

### 넣은 다음
```
godot --headless --path . --script res://tools/import_pixel_080.gd
```
`assets/pixel080/crew/<id>_action.png`(탐사요원은 `player/<preset>_action.png`)가 생기고 게임이 자동으로 씁니다.
`tests/pixel_080_tests.gd`와 `tests/visual_motion_080.gd`(창 필요)로 확인할 수 있습니다.

### 이미지 생성 도구에 줄 때 쓸 수 있는 요청문 (예)
> Using the attached walking sprite sheet as the exact character reference (same pixel-art chibi style, same size,
> proportions, palette and outfit), draw a new sprite sheet on a transparent background, 3 columns × 4 rows,
> evenly spaced: row 1 back view typing on a console with both hands (3 frames); row 2 front view talking with
> small hand gestures (3 frames); row 3 front view sitting on a chair at a table: neutral / talking / smiling;
> row 4 front view reactions: surprised (shoulders up) / nodding, thinking / slumped sigh with head down.
> Keep the feet (or the seat) at the bottom of each cell.

## 새 걷기 시트를 넣을 때
- `pixel_actor.gd`의 `NECK_ROWS`는 정면 프레임에서 **턱 아래 두 줄**의 행 번호입니다(머리 띠가 얼굴을 가로지르지 않게).
  새 캐릭터·새 그림이면 한 번 확인해 주세요. 표에 없으면 70을 씁니다.
