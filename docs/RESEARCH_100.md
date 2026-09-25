# ASTRA 1.0.0 — 설계 조사 (2026-09-25)

웹 검색으로 실제로 확인한 자료만 적었습니다. 확인하지 못한 것은 "확인 못 함"으로 남겼습니다.
각 항목: 무엇이 작동하는가 / 불만이 생기는 곳 / ASTRA에 적용한 원칙 / 적용하지 않은 것.

## Gnosia (Petit Depotto)
출처: [Wikipedia](https://en.wikipedia.org/wiki/Gnosia), [scrmbl — How Gnosia makes single player social deduction work](https://scrmbl.com/post/gnosia-single-player-deduction),
[Medium — TakumaEN](https://medium.com/@takumaen/gnosia-a-solo-social-deduction-game-1a5c6fb2e441), [Steam 토론 "Actual bug"](https://steamcommunity.com/app/1608290/discussions/0/792200576013176217/), [RPG Site 리뷰](https://www.rpgsite.net/review/10872-gnosia-review)

- **작동**: 인물마다 판단 성향이 있고, 루프를 거듭하며 그 성향을 배우는 것이 곧 실력이 된다. 인물을 알게 될수록 투표가 읽힌다.
- **불만**: 스팀 토론에서 "투표가 논리보다 RNG로 나를 몰아낸다"는 불만이 나오고, 답글은 "특정 인물의 능력치가 모두를 움직인다"고 설명한다 — 이유가 보이지 않으면 규칙이 있어도 운처럼 느껴진다.
- **적용**: 투표 이유는 숨은 점수가 아니라 DecisionTrace에서 온 문장으로 보여 준다(0.8부터 유지, 1.0에서 회의 정리·마지막 말·연결 결과로 확장). 방이 판단을 바꿀 때 무엇 때문인지 말한다.
- **적용 안 함**: 능력치(카리스마 등) 성장. ASTRA의 탐사요원은 능력치가 없다.

## Overboard! (inkle)
출처: [Apple Developer — Behind the Design: Overboard!](https://developer.apple.com/news/?id=fkelkwzq), [inkle](https://www.inklestudios.com/overboard/), [Wikipedia](https://en.wikipedia.org/wiki/Overboard!_(2021_video_game))

- **작동**: 각 인물이 무엇을 알고 있는지를 따로 추적해, 누가 무엇을 봤는지에 따라 반응이 달라진다. 서로 부딪히도록 만든 인물 조합이 다시 할 이유가 된다. 반복 플레이는 장면을 짧게 잘라 지루하지 않게 한다.
- **불만**: 확인 못 함(개발 글에는 실패 사례가 없음).
- **적용**: KnowledgeModel(누가 무엇을 아는가)을 그대로 쓴다. 1.0의 "말해진 문제만 방이 따진다" 규칙과 "혼자 본 것은 투표에만, 공개 지목은 두 번째 출처나 탐사요원이 들은 뒤"라는 규칙은 이 원칙의 연장이다. 되감기 뒤의 기억 메모도 "플레이어만 안다"는 지식 분리를 지킨다.
- **적용 안 함**: 실시간 이동 시뮬레이션. ASTRA는 하루 단위.

## Ace Attorney 계열 — 증언과 증거의 모순
출처: [Geek Culture — Ace Attorney Investigations Collection 리뷰](https://geekculture.co/ace-attorney-investigations-collection-review/), [Steam 토론 — Case 1-5 contradiction](https://steamcommunity.com/app/787480/discussions/0/3113647550047733271/), [Kai's Game Dev Blog 리뷰](https://kaiwueest.com/reviews/ace-attorney/)

- **작동**: "이 증언의 이 문장"과 "이 증거"를 짝지어 모순을 직접 짚는 행동은 추리를 몸으로 하는 느낌을 준다.
- **불만**: 리뷰는 "정해진 한 줄기 논리에서 정확한 증거를 정확한 때 내야 한다", "비슷한 증거가 둘 이상일 때 무엇을 증명할지 알아도 어떻게 증명할지 모른다"고 지적한다 — 정답을 알고도 개발자가 정한 아이템을 못 골라 실패한다.
- **적용**: 1.0 연결 동사. 진술 하나 + 근거 하나(또는 서로 다른 사람의 근거 둘). 판정은 내용(장소·사람·시각·해명 방식)으로만 하므로 **같은 것을 보여 주는 근거는 모두 인정**된다(테스트: 같은 진술에 둘 이상의 근거가 성립한 경우 41건). 판정 결과는 7종으로 이유와 함께 보여 준다.
- **적용 안 함**: 틀리면 체력이 깎이는 게이지. 대신 억지 연결은 방의 신뢰가 조금 줄고 상대가 방어적으로 바뀐다.

## Pentiment (Obsidian) — 제한된 조사
출처: [TheGamer 인터뷰](https://www.thegamer.com/interview-obsidian-josh-sawyer-pentiment/), [SHARP News 인터뷰](https://sharpweb.org/sharpnews/2022/12/07/pentiment-an-interview-with-josh-sawyer/), [MMORPG.com 인터뷰](https://www.mmorpg.com/interviews/the-rpg-files-building-obsidians-pentiment-interview-with-game-director-josh-sawyer-2000126821)

- **작동**: 시간이 모자라 모든 단서를 볼 수 없게 한 것은 의도였다. 무엇을 확인할지가 선택이 되고, 입증의 부담보다 사람의 동기를 알아 가는 과정이 중심이 된다.
- **적용**: ASTRA의 하루 대화 2~3회, 회의 발언 3회·확인 질문 3회는 "무엇을 확인할 것인가"의 비용이다. 1.0에서 묻지 않은 사람의 기록은 회의에서 잘 나오지 않는다(무응답 공개 확률 0.13 × 성향). 물으면 0.9 이상으로 나온다 — 결과는 누구를 만났는지에 달려 있다.
- **적용 안 함**: 정답 없는 결말. ASTRA는 Stage마다 진실이 있다.

## 도트 보행 사이클
출처: [SLYNYRD Pixelblog 50 — Human Walk Cycle](https://www.slynyrd.com/blog/2024/5/24/pixelblog-50-human-walk-cycle), [Pixnote — 애니메이션 가이드](https://pixnote.net/en/learn/animation/), [Sprite-AI — 프레임 수](https://www.sprite-ai.art/blog/sprite-animation-frames)

- **작동**: 보행은 접지(contact) → 지나감(passing) → 반대 접지 → 지나감. 접지에서 몸이 가장 낮고 지나감에서 조금 높다. 4프레임은 핵심을 담고 6~8프레임이 더 부드럽다. 한 프레임 100~150ms, 반복 시작을 접지로.
- **ASTRA에서 확인한 것**: 사용자 원본 시트는 14명 모두 다리가 실제로 교대한다(테스트: 연속 프레임의 하체 영역이 40px 이상 달라짐, 전 방향). "다리가 안 움직이는 것처럼 보이던" 원인은 그림이 아니라 게임 쪽이었다 — 걷는 동안 셰이더가 상체만 따로 움직였고, 보폭이 시트와 맞지 않았고, 프레임을 발 위치로 정렬해 몸통이 좌우로 튀었다.
- **적용**: 걷기는 그려진 프레임만으로(상체 띠 이동 금지), 지나감 프레임에서 몸 전체 1px 상승(접지에서 낮게), 시트마다 측정한 보폭(56~112px)으로 거리 기반 진행, 몸통 기준 정렬(축 흔들림 ≤3px), 제자리 180° 회전과 걷는 중 방향 반전에 옆/정면 프레임을 거침, 흔들림 줄이기에서도 다리는 계속 걷는다.
- **적용 안 함**: 보간 프레임 생성(흐려짐), 새 그림 그리기.

## 서사에 녹아든 퍼즐
출처: [Intermittent Mechanism — Obra Dinn의 퍼즐과 서사](https://intermittentmechanism.blog/2024/05/20/the-interplay-of-puzzle-and-narrative-in-return-of-the-obra-dinn/), [EGM — The Rise of the Information Game](https://egmnow.com/the-rise-of-the-information-game/), [Goomba Stomp — Ludonarrative](https://goombastomp.com/when-mechanics-tell-the-story-games-that-master-ludonarrative/)

- **작동**: 퍼즐을 푸는 행위가 곧 이야기를 알아내는 행위일 때, 정보는 장식이 아니라 진행의 핵심이 된다.
- **적용**: 네 가지 작업 계열은 모두 배 안의 일이다(통신 채널 분석, 배전 회로 진단, 기록 타임라인, 귀환 경로). 보상은 "누가 Null"이 아니라 구체적인 관찰(신호가 배 안에서 나옴, 모듈을 손으로 뺀 흔적, 기록의 경계, 문이 안에서 잠김). 한 계열을 깊게: 여러 단계의 판단, 시드별 배치, 고정 정답 없음.
- **적용 안 함**: 반사신경, 시간 제한.

## 확인하지 못한 것
- "사회추리 게임이 랜덤 같다"는 Reddit 스레드 원문은 검색 결과에 나오지 않았다(스팀 토론으로 대신함).
- Overboard!의 사후 분석(postmortem) 원문은 찾지 못했다.

## 결론으로 삼은 원칙
1. NPC 판단은 복잡해도 되지만 이유는 문장으로 보여야 한다(DecisionTrace → 회의·투표·마지막 말).
2. 사람이 모르는 것은 쓰지 않는다. 방은 **말해진** 모순만 따진다.
3. 제한된 대화는 "무엇을 확인할지"의 비용이다. 묻지 않으면 기록은 대개 서랍 속에 남는다.
4. 특정 진술과 특정 근거를 잇는 행동이 추리의 중심이며, 같은 것을 보여 주는 근거는 모두 인정한다.
5. 미니게임은 배 안의 일이고, 한 계열을 깊게 만든다.
