# 0.5.0 이미지 연결

원본: 사용자가 제공한 `../0.5.0 수정 인물 이미지/Astra/`의 인물별 폴더, 총 94 PNG. 원본 파일은 변경하지 않았다.

| 출력 | 수량 | 사용 |
|---|---:|---|
| assets/art050/cast | 8 | 전신 |
| assets/art050/portraits | 8 | 대표 상반신 / 표정 fallback |
| assets/art050/heads | 8 | 명단, 이름 옆 얼굴, 회의 카드 |
| assets/art050/expressions | 96 | 인물별 12감정 |

자산 ID는 mira, jun, daren, noa, sena, soren, lucan, maren이다. `crew_catalog.gd`가 호환 저장 ID를 자산 ID로 변환한다. 모든 표정 fallback은 같은 인물이다. 마렌의 기본 표정은 더 큰 대표 이미지의 상반신을 사용한다.

`tools/import_050.gd`와 `tools/art050_sources.json`으로 변환을 재현한다. 시트 전체를 인물로 표시하지 않고 셀을 잘라 낸다. 흰 배경은 가장자리에 연결된 거의 흰 픽셀만 제거하여 눈과 옷 내부의 흰 부분을 보존한다. 새 그림을 생성하지 않았다. 크롭 좌표와 입력 파일은 `assets/art050/manifest.json`에 기록한다.

0.3.1의 선내 배경·사물·아이콘은 계속 사용한다. 구 인물 cast/heads/dots/scenes와 구 portrait 폴더는 새 실행 경로에서 참조하지 않으며 Windows 패키지에서 제외한다. 원본 소스 자산은 되돌릴 수 있도록 삭제하지 않았다.

검사: 8인 얼굴 정사각형, 인물별 fallback, 실제 알파 채널, 런타임 로딩, 1366×768/1920×1080 렌더. 원본 표정 셀의 해상도 차이 때문에 일부 보조 감정은 대표 초상보다 선명도가 낮다.
