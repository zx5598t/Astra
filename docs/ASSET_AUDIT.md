# 자산 감사 — 2026-09-21, 소스 0.5.7 기준

실제 실행: scenes/main.tscn → scripts/ui/app.gd. Godot 4.7.2.stable.official.ed1daf0bf.
Git 메타데이터 없음. 기존 Windows EXE 없음(build에는 logs만 존재). 이전 배포와 일치 여부 미확인.
인물 8명/전신 8/대표 초상 8/얼굴 8/표정 96개. 기존 사용자 원본은 수정하지 않음.
알 수 없는 ID가 미라 자산으로 연결되는 오류를 확인함. 신규 그림 누락과 구분하여 코드 수정 대상.
원본 표정은 작은 셀에서 추출됨. 새 그림을 주문하지 않고 인게임 최대 표시 크기를 제한한다.

| 자산 ID | 실제 파일 | 구분 | 연결 장면 | 정보 | 해상도·알파 | 우선순위 | 차단 | 대안 | 시각 검수 |
|---|---|---|---|---|---|---|---|---|---|
| daren/cast | `assets/art050/cast/daren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| jun/cast | `assets/art050/cast/jun.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| lucan/cast | `assets/art050/cast/lucan.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| maren/cast | `assets/art050/cast/maren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| mira/cast | `assets/art050/cast/mira.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| noa/cast | `assets/art050/cast/noa.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sena/cast | `assets/art050/cast/sena.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| soren/cast | `assets/art050/cast/soren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 683×1024, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/daren | `assets/art050/expressions/daren/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/daren | `assets/art050/expressions/daren/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/daren | `assets/art050/expressions/daren/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/daren | `assets/art050/expressions/daren/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/daren | `assets/art050/expressions/daren/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/daren | `assets/art050/expressions/daren/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/daren | `assets/art050/expressions/daren/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/daren | `assets/art050/expressions/daren/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/daren | `assets/art050/expressions/daren/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/daren | `assets/art050/expressions/daren/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/daren | `assets/art050/expressions/daren/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/daren | `assets/art050/expressions/daren/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/jun | `assets/art050/expressions/jun/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/jun | `assets/art050/expressions/jun/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/jun | `assets/art050/expressions/jun/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/jun | `assets/art050/expressions/jun/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/jun | `assets/art050/expressions/jun/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/jun | `assets/art050/expressions/jun/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/jun | `assets/art050/expressions/jun/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/jun | `assets/art050/expressions/jun/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/jun | `assets/art050/expressions/jun/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/jun | `assets/art050/expressions/jun/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/jun | `assets/art050/expressions/jun/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/jun | `assets/art050/expressions/jun/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/lucan | `assets/art050/expressions/lucan/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/lucan | `assets/art050/expressions/lucan/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/lucan | `assets/art050/expressions/lucan/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/lucan | `assets/art050/expressions/lucan/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/lucan | `assets/art050/expressions/lucan/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/lucan | `assets/art050/expressions/lucan/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/lucan | `assets/art050/expressions/lucan/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/lucan | `assets/art050/expressions/lucan/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/lucan | `assets/art050/expressions/lucan/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/lucan | `assets/art050/expressions/lucan/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/lucan | `assets/art050/expressions/lucan/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 492×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/lucan | `assets/art050/expressions/lucan/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/maren | `assets/art050/expressions/maren/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/maren | `assets/art050/expressions/maren/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/maren | `assets/art050/expressions/maren/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/maren | `assets/art050/expressions/maren/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/maren | `assets/art050/expressions/maren/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/maren | `assets/art050/expressions/maren/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/maren | `assets/art050/expressions/maren/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/maren | `assets/art050/expressions/maren/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/maren | `assets/art050/expressions/maren/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/maren | `assets/art050/expressions/maren/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/maren | `assets/art050/expressions/maren/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/maren | `assets/art050/expressions/maren/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 150×259, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/mira | `assets/art050/expressions/mira/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/mira | `assets/art050/expressions/mira/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/mira | `assets/art050/expressions/mira/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/mira | `assets/art050/expressions/mira/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/mira | `assets/art050/expressions/mira/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/mira | `assets/art050/expressions/mira/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/mira | `assets/art050/expressions/mira/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/mira | `assets/art050/expressions/mira/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/mira | `assets/art050/expressions/mira/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/mira | `assets/art050/expressions/mira/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/mira | `assets/art050/expressions/mira/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/mira | `assets/art050/expressions/mira/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/noa | `assets/art050/expressions/noa/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/noa | `assets/art050/expressions/noa/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/noa | `assets/art050/expressions/noa/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/noa | `assets/art050/expressions/noa/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/noa | `assets/art050/expressions/noa/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/noa | `assets/art050/expressions/noa/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/noa | `assets/art050/expressions/noa/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/noa | `assets/art050/expressions/noa/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/noa | `assets/art050/expressions/noa/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/noa | `assets/art050/expressions/noa/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/noa | `assets/art050/expressions/noa/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/noa | `assets/art050/expressions/noa/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 462×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/sena | `assets/art050/expressions/sena/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/sena | `assets/art050/expressions/sena/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/sena | `assets/art050/expressions/sena/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/sena | `assets/art050/expressions/sena/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/sena | `assets/art050/expressions/sena/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/sena | `assets/art050/expressions/sena/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/sena | `assets/art050/expressions/sena/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/sena | `assets/art050/expressions/sena/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/sena | `assets/art050/expressions/sena/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/sena | `assets/art050/expressions/sena/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/sena | `assets/art050/expressions/sena/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/sena | `assets/art050/expressions/sena/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 321×720, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| afraid/soren | `assets/art050/expressions/soren/afraid.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| angry/soren | `assets/art050/expressions/soren/angry.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| annoyed/soren | `assets/art050/expressions/soren/annoyed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| determined/soren | `assets/art050/expressions/soren/determined.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| embarrassed/soren | `assets/art050/expressions/soren/embarrassed.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| happy/soren | `assets/art050/expressions/soren/happy.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| neutral/soren | `assets/art050/expressions/soren/neutral.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sad/soren | `assets/art050/expressions/soren/sad.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| shocked/soren | `assets/art050/expressions/soren/shocked.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| smile/soren | `assets/art050/expressions/soren/smile.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| suspicious/soren | `assets/art050/expressions/soren/suspicious.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 342×495, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| tired/soren | `assets/art050/expressions/soren/tired.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 364×464, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| daren/heads | `assets/art050/heads/daren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| jun/heads | `assets/art050/heads/jun.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| lucan/heads | `assets/art050/heads/lucan.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| maren/heads | `assets/art050/heads/maren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| mira/heads | `assets/art050/heads/mira.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| noa/heads | `assets/art050/heads/noa.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sena/heads | `assets/art050/heads/sena.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| soren/heads | `assets/art050/heads/soren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 256×256, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| daren/portraits | `assets/art050/portraits/daren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| jun/portraits | `assets/art050/portraits/jun.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| lucan/portraits | `assets/art050/portraits/lucan.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| maren/portraits | `assets/art050/portraits/maren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| mira/portraits | `assets/art050/portraits/mira.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| noa/portraits | `assets/art050/portraits/noa.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| sena/portraits | `assets/art050/portraits/sena.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| soren/portraits | `assets/art050/portraits/soren.webp` | 재사용 | crew_catalog → 대화/명단 | 인물·감정 | 536×640, RGBA | P1 | 아니요 | 같은 인물 대표 초상 | 연락판 검수; 작은 표정 확대 주의 |
| medical | assets/art031/backgrounds/medical.webp | 재사용 | 각성/첫 조사 | 의료실·포드 | 기존 16:9 | P0 | 아니요 | UI 제어 패널 | 실제 화면 별도 QA |
| evidence_11 | assets/art031/items/evidence_11.webp | 재사용 | 잠금 이력 검토 | 기록 장치 | 기존 정사각 | P1 | 아니요 | 텍스트 기록 카드 | 증거 내용은 UI |
| abstain / unset / error | Godot Label/Panel | 신규 UI | 투표·개표 | 기권/미선택/오류 | 벡터·반응형 | P0 | 아니요 | 문장 | 얼굴 사용 금지 |

시각 연락판: build/qa/asset_contact_sheet.png. 이 문서는 파일 검사와 사용처 조사 결과이며 초보자 플레이 검증을 대신하지 않는다.
