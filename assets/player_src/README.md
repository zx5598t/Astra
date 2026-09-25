# 탐사요원 이미지

0.9.0부터 탐사요원은 여섯 명(세린·미카·제이스·라엘·로건·시아)이고, 그림은 모두 사용자 원본 폴더에서 가져옵니다.
이 폴더(`assets/player_src/`)에는 더 이상 그림을 넣지 않습니다(`.gdignore`로 게임에서 제외).

| 쓰임 | 원본 (`../인물 이미지/Astra/`) | 변환 도구 | 결과 |
|---|---|---|---|
| 선택 화면 전신 | `플레이어/<이름>.png` | `tools/import_explorers_090.gd` | `assets/explorers/<id>/full.webp` |
| 초상화·표정 4종 | `플레이어/ChatGPT 이미지 … 05_41_43-1 ~ 05_41_46-4.png` (3×2, 순서: 라엘 로건 미카 / 세린 시아 제이스) | 같은 도구 | `bust_1..4.webp`, `head.webp` |
| 걷기 | `미니 도트 캐릭/<이름>.png` (4×4) | `tools/import_pixel_090.gd` | `assets/pixel080/player/<id>_a.png` |
| 도구 든 걷기 | `미니 도트 캐릭/<이름>1.png` | 같은 도구 | `<id>_a_carry.png` |
| 포즈 | `미니 도트 캐릭/<이름>2.png` | 같은 도구 | `<id>_a_poses.png` |

`explorer_id`(세린 = `serin`)와 그림 `art_id`(`serin_a`)는 따로 저장됩니다. 기존 저장의 임시 외형 p1~p6(`임시/` 폴더)은
그대로 불러오며 어느 탐사요원으로도 바뀌지 않습니다.

```bash
godot --headless --path . --script res://tools/import_explorers_090.gd
godot --headless --path . --script res://tools/import_pixel_090.gd
godot --headless --path . --import
```

원본은 잘라 내고 같은 배율로만 줄입니다(늘이지 않음). 동작 크기 맞춤 규칙은 `docs/PIXEL_ACTIONS_100.md`.
