class_name AstraInterludes
extends RefCounted

# Short playable scenes between the social rounds (0.8.0 campaign pass, see
# docs/CAMPAIGN_PACING_080.md). Each belongs to one Stage and one moment and
# is a story scene first: a small room, two or three people, one or two things
# to look at, at most one short hands-on task. Failing or skipping never
# blocks the Stage or erases evidence; it only changes what the explorer
# walks into the Day with and how one person feels about it (§16, §63, §64).
#
# Room layout is in tiles (TILE px). Props with "solid" block walking.
# Actors stand at tile coordinates (fractions allowed), feet at that point.

const TILE := 64

const INTERLUDES := {
    "echo_signal_trace": {
        "case_id": "ECHO_WARD",
        "day": 1,
        "title": "중계실 · 끊긴 신호",
        "caption": "STAGE 4 · 중계실",
        "size": [15, 9],
        "door": [6, 9],
        "floor": "relay",
        "props": [
            {"id": "relay_terminal", "rect": [5, 1, 5, 1], "kind": "console", "label": "중계 단말", "solid": true},
            {"id": "rack", "rect": [11, 1, 1, 1], "kind": "rack", "label": "헤드셋 거치대", "solid": true},
            {"id": "speaker", "rect": [13, 2, 1, 2], "kind": "speaker", "label": "스피커", "solid": true},
            {"id": "wall_clock", "rect": [2, 0, 1, 1], "kind": "clock", "label": "벽시계", "solid": false},
            {"id": "bench", "rect": [1, 5, 2, 1], "kind": "bench", "label": "", "solid": true},
            {"id": "cable", "rect": [9, 4, 4, 1], "kind": "cable", "label": "", "solid": false}
        ],
        "actors": [
            {"id": "vale", "at": [7.5, 2.3], "facing": "up", "idle": "work"},
            {"id": "eli", "at": [2.5, 2.1], "facing": "up", "idle": "watch"},
            {"id": "mira", "at": [4.2, 6.4], "facing": "right", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "생체 기록으로는 소렌이 {time} 내내 잠들어 있었어요. 호흡도, 심박도 수면 패턴이에요."],
                    ["mira", "그러니까 저 목소리가 소렌이라면… 설명이 안 돼요. 소렌한테 먼저 가 봐요. 저 혼자 두지 말고요."]]},
            {"id": "eli", "actor": "eli", "label": "루칸",
                "lines": [["eli", "중계실 시계가 내 시계보다 7초 느려."],
                    ["eli", "7초면 사람 하나가 단말 앞에 서기엔 충분해. …그냥 버릇이야. 시계부터 맞추는 거."]]},
            {"id": "wall_clock", "prop": "wall_clock", "label": "벽시계",
                "lines": [["", "초침이 한 칸씩 늦게 따라온다. 누가 손댄 흔적은 없다. 그냥, 늦다."]]},
            {"id": "rack", "prop": "rack", "label": "헤드셋 거치대",
                "lines": [["", "소렌의 예비 헤드셋. 한쪽 이어패드만 유난히 닳아 있다. 늘 한쪽 귀를 비워 두는 사람의 물건이다."]]},
            {"id": "vale", "actor": "vale", "label": "소렌", "task": "signal_trace",
                "lines": [["vale", "끊긴 신호가 세 조각이에요. 주파수가 조금씩 틀어져 있어서 서로 붙지 않아요."],
                    ["vale", "같이 맞춰 줄래요? 저는 듣고, 당신은 보는 쪽을 맡아 줘요."]]}
        ],
        "task": {"kind": "signal_trace", "pieces": ["호출음", "목소리", "승인 음"], "tolerance": 0.045},
        "results": {
            "success": {"lines": [["vale", "…붙었어요. 같이 들어 봐요."],
                    ["", "재조립된 신호. 잡음 사이로 소렌의 목소리, 그리고 짧고 높은 승인 음."],
                    ["vale", "저 승인 음은 단말 스피커에서 나는 소리예요. 원격으로 승인하면 이 소리가 안 나요. 누군가 {room}의 단말 앞에 서 있었어요."],
                    ["vale", "그리고 이 목소리… 제가 아직 하지 않은 말이에요."]],
                "trust": {"vale": 0.08, "eli": 0.02}, "grant": "EXPERT_INFERENCE",
                "note": "신호 추적 · 승인 음은 중계 단말에서 났다. 원격 승인이 아니다.",
                "hook": {"vale": "success"}, "memory_tag": "interlude:echo_clock_7s"},
            "partial": {"lines": [["vale", "…두 조각까지만 붙었어요. 승인 음이 든 마지막 조각이 자꾸 흘러내려요."],
                    ["vale", "괜찮아요. 제가 따로 더 들어 볼게요. 이야기할 때 다시 물어봐 줘요."]],
                "trust": {"vale": 0.03}, "note": "신호 추적 · 두 조각만 복원했다. 소렌에게 다시 물어볼 것.",
                "hook": {"vale": "partial"}, "memory_tag": "interlude:echo_clock_7s"},
            "skipped": {"lines": [["", "소렌이 혼자 헤드셋을 쓴다. 당신은 먼저 사람들 이야기를 듣기로 한다."]],
                "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {
            "vale": {"success": "아까 같이 붙인 신호요. 승인 음은 분명 단말 스피커 소리였어요. 그건 제가 장담할 수 있어요.",
                "partial": "아까 못 붙인 마지막 조각, 혼자 더 들어 봤어요. 승인 음은 단말 쪽 소리 같아요. 확신은… 아직이에요."}
        }
    },
    "dead_air_first_walk": {
        "case_id": "DEAD_AIR",
        "day": 1,
        "title": "통신실 앞 복도 · 처음 걷는 갑판",
        "caption": "STAGE 2 · 통신실",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "comms_console", "rect": [8, 1, 5, 1], "kind": "console", "label": "통신 콘솔", "solid": true},
            {"id": "doc_table", "rect": [3, 4, 3, 1], "kind": "table", "label": "목적지 문서", "solid": true},
            {"id": "door_panel", "rect": [1, 1, 1, 1], "kind": "panel", "label": "출입 패널", "solid": true},
            {"id": "bench", "rect": [11, 6, 2, 1], "kind": "bench", "label": "", "solid": true}
        ],
        "actors": [
            {"id": "sena", "at": [2.5, 2.6], "facing": "right", "idle": "pace", "pace": [1.6, 0]},
            {"id": "mira", "at": [4.5, 6.2], "facing": "up", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "sena", "actor": "sena", "label": "세나",
                "lines": [["sena", "잠깐. 문부터 확인하고. …됐어. 이쪽 패널은 누가 만진 흔적이 없어."],
                    ["sena", "깨자마자 이게 먼저 돼. 왜인지는 몰라. 문이 잠겨 있는 걸 봐야 숨이 쉬어져."]]},
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "세나는 원래 저래요. 먼저 확인하고, 그다음에 사람을 봐요."],
                    ["mira", "…저 두 장, 봤어요? 어느 쪽이 진짜인지 아무도 몰라요. 목적지가 둘인 배가 어디 있어요."]]},
            {"id": "doc_table", "prop": "doc_table", "label": "목적지 문서",
                "lines": [["", "탁자 위에 목적지 원본 두 장이 나란히 놓여 있다. 봉인 번호도, 서명도 둘 다 진짜처럼 보인다. 적힌 좌표만 다르다."],
                    ["", "당신은 둘 중 어느 쪽도 처음 보는 게 아니라는 느낌을 받는다. 이유는 모른다."]],
                "complete": "success"},
            {"id": "comms_console", "prop": "comms_console", "label": "통신 콘솔",
                "lines": [["", "외부 송신 채널 표시등이 꺼져 있다. 차단 시각 {time}. 누군가 여기서 직접 끊었다."]]}
        ],
        "results": {
            "success": {"lines": [["sena", "봤어? 그럼 됐어. 이제 사람들 얘기 들으러 가. 문은 내가 볼게."]],
                "trust": {"sena": 0.05, "mira": 0.03}, "note": "통신실 · 목적지 문서가 두 장. 봉인도 서명도 둘 다 진짜처럼 보인다.",
                "hook": {"sena": "success"}, "memory_tag": "interlude:dead_air_two_documents"},
            "partial": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"sena": {"success": "아까 복도에서 같이 봤지. 그 문서 두 장. …나 그거 보고 좀 무서웠어. 말 안 했지만."}}
    },
    "glass_power_route": {
        "case_id": "GLASS_GARDEN",
        "day": 1,
        "title": "보안 구역 분배반 · 끊긴 전력",
        "caption": "STAGE 3 · 보안 구역",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "breaker", "rect": [6, 1, 3, 1], "kind": "breaker", "label": "분배반", "solid": true},
            {"id": "inner_door", "rect": [12, 1, 2, 1], "kind": "door", "label": "안쪽 문", "solid": true},
            {"id": "locker", "rect": [1, 3, 1, 2], "kind": "rack", "label": "", "solid": true}
        ],
        "actors": [
            {"id": "rho", "at": [7.5, 2.3], "facing": "up", "idle": "work"},
            {"id": "sena", "at": [11.6, 3.0], "facing": "left", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "sena", "actor": "sena", "label": "세나",
                "lines": [["sena", "안쪽 문 봐. 잠금 기록이 이상해. 전력이 끊기기 전에 안쪽에서 먼저 열렸어."],
                    ["sena", "밖에서 누가 들어간 게 아니라, 안에서 누가 나온 거야. …준이랑 여기서 일한 날이 내 기록엔 있는데."]]},
            {"id": "inner_door", "prop": "inner_door", "label": "안쪽 문",
                "lines": [["", "안쪽 문 손잡이에 손때 자국이 있다. 문은 안쪽 패널로만 열린다. 표시등에는 ‘내부 개방’이 남아 있다."]]},
            {"id": "rho", "actor": "rho", "label": "준", "task": "power_route",
                "lines": [["rho", "레버가 네 개인데 순서가 꼬였어. 아무거나 올리면 보안 구역 대신 급수 펌프가 살아나."],
                    ["rho", "같이 해 보자. 내가 레버를 잡을게, 넌 경로를 짚어 줘. 선 따라가면 돼."]]}
        ],
        "task": {"kind": "power_route", "breakers": 4},
        "results": {
            "success": {"lines": [["rho", "…들어왔다! 보안 구역 불 켜졌어."],
                    ["rho", "봐, 이 레버들은 손으로 내려야 움직여. 자동 전환 기록은 없고. 누가 여기 서서 직접 내렸다는 거야."],
                    ["rho", "…근데 세나 말, 나 진짜 기억 안 나. 여기서 같이 일했다는 거."]],
                "trust": {"rho": 0.07, "sena": 0.02}, "grant": "EXPERT_INFERENCE",
                "note": "분배반 · 레버는 손으로 내려야 움직인다. 안쪽 문은 전력이 끊기기 전 안에서 먼저 열렸다.",
                "hook": {"rho": "success"}, "memory_tag": "interlude:glass_inner_door"},
            "partial": {"lines": [["rho", "…펌프만 살았네. 괜찮아, 이따 내가 다시 볼게. 너는 사람들 얘기부터 들어."]],
                "trust": {"rho": 0.02}, "note": "분배반 · 전력 경로를 다 잇지 못했다. 준에게 다시 물어볼 것.",
                "hook": {"rho": "partial"}, "memory_tag": "interlude:glass_inner_door"},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"rho": {"success": "아까 분배반 같이 봤잖아. 레버는 손으로 내려야 돼. 그건 내가 보증해.",
            "partial": "아까 못 이은 경로, 혼자 다시 봤어. 레버는 손으로만 움직여. 그건 확실해."}}
    },
    "red_shift_samples": {
        "case_id": "RED_SHIFT",
        "day": 1,
        "title": "생태 구역 · 날짜가 이상한 시료",
        "caption": "STAGE 6 · 생태 구역",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "sample_bench", "rect": [5, 1, 5, 1], "kind": "bench_lab", "label": "시료 작업대", "solid": true},
            {"id": "planter_a", "rect": [1, 2, 2, 2], "kind": "planter", "label": "", "solid": true},
            {"id": "planter_b", "rect": [12, 2, 2, 2], "kind": "planter", "label": "", "solid": true},
            {"id": "planter_c", "rect": [11, 6, 2, 1], "kind": "planter", "label": "", "solid": true}
        ],
        "actors": [
            {"id": "lyra", "at": [7.5, 2.3], "facing": "up", "idle": "work"},
            {"id": "mira", "at": [3.5, 5.6], "facing": "right", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "마렌이 밤새 저 시료들을 다시 봤대요. 눈 밑이 저래요."],
                    ["mira", "…저 사람, 폐기될 모종에도 물을 줘요. 그런 사람이에요."]]},
            {"id": "planter_a", "prop": "planter_a", "label": "모종",
                "lines": [["", "‘폐기 예정’ 딱지가 붙은 모종인데 흙이 젖어 있다. 누군가 오늘 아침에도 물을 줬다."]]},
            {"id": "lyra", "actor": "lyra", "label": "마렌", "task": "order",
                "lines": [["lyra", "재분류된 시료가 넷이에요. 채집 시각 태그가 섞여 버렸어요."],
                    ["lyra", "먼저 채집된 것부터 순서대로 놓아 줄래요? 태그를 보면 알 수 있어요."]]}
        ],
        "task": {"kind": "order", "title": "시료 채집 순서",
            "items": [["목적지 대기 시료 · 채집 D-212", 0], ["출항 전 검역 시료 · 채집 D-3", 1], ["출항 당일 시료 · 채집 D-0", 2], ["항해 3주차 시료 · 채집 D+21", 3]],
            "insight": "가장 오래된 시료가 목적지의 흙이다. 출항보다 212일 먼저."},
        "results": {
            "success": {"lines": [["lyra", "…이상해요. 순서대로 놓으면 목적지 시료가 제일 먼저예요. 출항보다 212일이나 먼저. 태그가 잘못 찍힌 거라면 좋겠는데."],
                    ["lyra", "태그가 맞다면, 우리가 가기도 전에 누군가 거기 흙을 담아 왔다는 뜻이에요."],
                    ["lyra", "표본 분류는 생태 단말에 직접 접속해야 바뀌어요. 자동으로 바뀌는 기능은 없어요."]],
                "trust": {"lyra": 0.07}, "grant": "EXPERT_INFERENCE",
                "note": "생태 구역 · 목적지 시료가 출항보다 212일 먼저 채집됐다. 재분류는 단말에 직접 접속해야 가능하다.",
                "hook": {"lyra": "success"}, "memory_tag": "interlude:red_shift_older_soil"},
            "partial": {"lines": [["lyra", "…괜찮아요. 제가 나중에 다시 정리할게요. 먼저 사람들 이야기를 들어요."]],
                "trust": {"lyra": 0.02}, "note": "생태 구역 · 시료 순서를 다 맞추지 못했다. 마렌에게 다시 물어볼 것.",
                "hook": {"lyra": "partial"}, "memory_tag": "interlude:red_shift_older_soil"},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"lyra": {"success": "아까 같이 놓아 본 시료요. 순서가 머리에서 안 떠나요. 목적지 흙이 제일 먼저라니.",
            "partial": "아까 못 맞춘 시료 순서, 다시 봤어요. 재분류는 단말에서 직접 해야 돼요. 그건 확실해요."}}
    },
    "second_watch_logs": {
        "case_id": "SECOND_WATCH",
        "day": 1,
        "title": "기록보관실 · 근무 일지",
        "caption": "STAGE 8 · 기록보관실",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "shelf_a", "rect": [1, 1, 4, 1], "kind": "shelf", "label": "", "solid": true},
            {"id": "shelf_b", "rect": [10, 1, 4, 1], "kind": "shelf", "label": "", "solid": true},
            {"id": "desk", "rect": [6, 3, 3, 1], "kind": "table", "label": "일지 더미", "solid": true}
        ],
        "actors": [
            {"id": "noa", "at": [7.5, 4.4], "facing": "up", "idle": "work"},
            {"id": "sena", "at": [12.5, 5.2], "facing": "left", "idle": "pace", "pace": [0, 1.4]}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "sena", "actor": "sena", "label": "세나",
                "lines": [["sena", "노아가 아까부터 저 필체만 보고 있어. 자기 약어래."],
                    ["sena", "…기록을 제일 믿는 애가 기록 앞에서 저러니까, 좀 무섭네."]]},
            {"id": "noa", "actor": "noa", "label": "노아", "task": "order",
                "lines": [["noa", "파기되고 남은 일지 네 장이에요. 날짜 칸이 찢겨서 순서를 모르겠어요."],
                    ["noa", "근무 내용을 보고 순서대로 놓아 줄래요? 저는… 지금 필체를 못 믿겠어요."]]}
        ],
        "task": {"kind": "order", "title": "근무 일지 순서",
            "items": [["도착 궤도 진입 · 전원 각성 대기", 0], ["도착 1일차 · 착륙 전 점검", 1], ["도착 12일차 · 정기 근무 · 식사표 교대", 2], ["도착 40일차 · 장기수면 준비", 3]],
            "insight": "도착한 뒤 40일을 살았다. 그리고 다시 잠들 준비를 했다."},
        "results": {
            "success": {"lines": [["noa", "…도착하고 40일. 우리가 정상 근무를 했어요. 식사표까지 돌렸어요."],
                    ["noa", "근데 아무도 기억 못 해요. 저도요. 이 약어는 제 건데."],
                    ["noa", "기록이 맞다면, 우리는 산 적이 있는 거예요. 도착한 그 뒤를."]],
                "trust": {"noa": 0.08}, "grant": "EXPERT_INFERENCE",
                "note": "기록보관실 · 도착 후 40일의 근무 일지. 우리는 도착 뒤를 살았다.",
                "hook": {"noa": "success"}, "memory_tag": "interlude:second_watch_forty_days"},
            "partial": {"lines": [["noa", "…순서가 안 맞아요. 제가 다시 볼게요. 적어 두는 건 제 일이니까요."]],
                "trust": {"noa": 0.02}, "note": "기록보관실 · 일지 순서를 다 맞추지 못했다. 노아에게 다시 물어볼 것.",
                "hook": {"noa": "partial"}, "memory_tag": "interlude:second_watch_forty_days"},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"noa": {"success": "아까 같이 놓은 일지요. 40일. …맥락 없는 기록도 진실의 절반이라는 거, 오늘 처음 알았어요.",
            "partial": "아까 못 맞춘 일지, 혼자 다시 봤어요. 삭제는 로컬 단말에서 됐어요. 그건 확실해요."}}
    },
    "blind_deck_door": {
        "case_id": "BLIND_DECK",
        "day": 1,
        "title": "통신실 앞 복도 · 여기가 원래 이랬나",
        "caption": "STAGE 10 · 통신실 앞 복도",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "comms_console", "rect": [8, 1, 5, 1], "kind": "console", "label": "통신 콘솔", "solid": true},
            {"id": "doc_table", "rect": [3, 4, 3, 1], "kind": "table", "label": "", "solid": true},
            {"id": "door_panel", "rect": [1, 1, 1, 1], "kind": "panel", "label": "", "solid": true},
            {"id": "new_door", "rect": [13, 4, 1, 2], "kind": "door_side", "label": "벽이던 곳", "solid": true}
        ],
        "actors": [
            {"id": "eli", "at": [12.2, 4.9], "facing": "right", "idle": "work"},
            {"id": "noa", "at": [9.5, 6.4], "facing": "up", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "new_door", "prop": "new_door", "label": "벽이던 곳",
                "lines": [["", "당신은 기억한다. 이 복도의 이쪽은 벽이었다. 처음 이 갑판을 걸었을 때도, 그 뒤에도."],
                    ["", "지금 거기에 좁은 정비 문이 있다. 닳은 손잡이. 오래 쓰인 문이다."]],
                "complete": "success"},
            {"id": "eli", "actor": "eli", "label": "루칸",
                "lines": [["eli", "지도에는 이 문이 없어. 좌표는 벽 너머로 이어지는데."],
                    ["eli", "…누가 지운 거야. 지도에서만. 문은 그대로 두고."]]},
            {"id": "noa", "actor": "noa", "label": "노아",
                "lines": [["noa", "지도 갱신 이력에 이 구역만 빠져 있어요. 실수로 빠진 게 아니에요. 한 번에 깨끗하게."]]}
        ],
        "results": {
            "success": {"lines": [["eli", "봤지. 없는 문이 아니야. 지워진 문이야."]],
                "trust": {"eli": 0.05, "noa": 0.02}, "note": "보이지 않는 갑판 · 지도에서만 지워진 정비 문. 벽 너머로 좌표가 이어진다.",
                "hook": {"eli": "success"}, "memory_tag": "interlude:blind_deck_door"},
            "partial": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"eli": {"success": "그 문. 아까 너도 봤지. 너, 거기가 벽이었던 걸 아는 얼굴이던데. …아니야. 됐어."}}
    },
    "three_alarms": {
        "case_id": "THREE_MINUTES_DARK",
        "day": 1,
        "title": "비상 복도 · 세 곳의 경보",
        "caption": "STAGE 11 · 비상 복도",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "alarm_reactor", "rect": [1, 1, 3, 1], "kind": "alarm", "label": "원자로 경보", "solid": true},
            {"id": "alarm_security", "rect": [6, 1, 3, 1], "kind": "alarm", "label": "보안 구역 경보", "solid": true},
            {"id": "alarm_medbay", "rect": [11, 1, 3, 1], "kind": "alarm", "label": "의료실 경보", "solid": true}
        ],
        "actors": [
            {"id": "vale", "at": [7.5, 5.4], "facing": "down", "idle": "alert"},
            {"id": "mira", "at": [4.0, 6.2], "facing": "right", "idle": "alert"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "vale", "actor": "vale", "label": "소렌",
                "lines": [["vale", "세 곳이 동시에 울렸어요. 한 곳만 직접 볼 수 있어요. 나머지는… 누가 전해 주는 말로 들어야 해요."],
                    ["vale", "말은 한 번 건널 때마다 조금씩 달라져요. 어디를 직접 볼지 골라요."]]},
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "의료실 쪽은 제가 가 볼 수도 있어요. 하지만 당신 눈으로 보는 것과는 다르겠죠."]]},
            {"id": "alarm_reactor", "prop": "alarm_reactor", "label": "원자로 경보", "complete": "choice:reactor",
                "lines": [["", "원자로 경보 패널. 경보는 {time}에 수동 스위치로 울렸다. 레버에 아직 온기가 있다."]]},
            {"id": "alarm_security", "prop": "alarm_security", "label": "보안 구역 경보", "complete": "choice:security",
                "lines": [["", "보안 구역 경보 패널. 센서는 정상이다. 경보는 누군가 테스트 버튼을 눌러서 울렸다."]]},
            {"id": "alarm_medbay", "prop": "alarm_medbay", "label": "의료실 경보", "complete": "choice:medbay",
                "lines": [["", "의료실 경보 패널. 경보음이 꺼져 있다. 누군가 울리자마자 음소거했다."]]}
        ],
        "results": {
            "success": {"lines": [["vale", "직접 본 곳은 이제 당신이 증인이에요. 나머지는 들은 말이에요. 그 차이를 잊지 마요."]],
                "trust": {"vale": 0.04}, "note": "비상 복도 · 세 경보 중 한 곳을 직접 봤다. 나머지 두 곳은 전언으로만 안다.",
                "hook": {"vale": "success"}, "memory_tag": "interlude:three_alarms"},
            "partial": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "choices": {
            "reactor": {"grant": "EXPERT_INFERENCE", "note": "비상 복도 · 원자로 경보를 직접 봤다. 수동 스위치, 레버에 온기. 나머지 두 곳은 전언으로만 안다."},
            "security": {"note": "비상 복도 · 보안 구역 경보를 직접 봤다. 테스트 버튼으로 울렸다. 나머지 두 곳은 전언으로만 안다."},
            "medbay": {"note": "비상 복도 · 의료실 경보를 직접 봤다. 울리자마자 음소거됐다. 나머지 두 곳은 전언으로만 안다."}
        },
        "hook_lines": {"vale": {"success": "아까 한 곳을 직접 봤죠. 거기 말고 다른 두 곳 얘기는, 누구한테서 들었는지까지 물어봐요."}}
    },
    "continuity_evening": {
        "case_id": "CONTINUITY",
        "day": 1,
        "title": "라운지 · 폭풍 전의 저녁",
        "caption": "STAGE 12 · 라운지",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "meal_table", "rect": [7, 0, 2, 1], "kind": "chart", "label": "식사표", "solid": false},
            {"id": "dining_table", "rect": [4, 4, 6, 1], "kind": "dining", "label": "", "solid": true, "front": true},
            {"id": "planter", "rect": [12, 2, 2, 2], "kind": "planter", "label": "화분", "solid": true},
            {"id": "window", "rect": [1, 0, 4, 1], "kind": "window", "label": "창", "solid": false}
        ],
        "actors": [
            {"id": "lyra", "at": [5.6, 4.15], "facing": "down", "idle": "sit"},
            {"id": "mira", "at": [7.6, 4.15], "facing": "down", "idle": "sit"},
            {"id": "rho", "at": [10.6, 4.7], "facing": "left", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "meal_table", "prop": "meal_table", "label": "식사표",
                "lines": [["", "벽에 붙은 식사표. 여덟 명의 이름이 요일마다 돌아간다. 필체는 모두 다르고, 모두 낯익다."],
                    ["", "당신의 칸도 있다. 당신이 쓴 적 없는 필체로."]], "complete": "success"},
            {"id": "lyra", "actor": "lyra", "label": "마렌",
                "lines": [["lyra", "물 주는 순서를 적어 둔 표가 있었는데, 오늘 보니 식사표랑 칸이 똑같이 생겼어요."],
                    ["lyra", "…우리 전에도 이렇게 살았을까요. 매일 같은 모양으로."]]},
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "오늘은 아무 일도 없었으면 좋겠어요. 그냥 평범하게 밥 먹고, 평범하게 자고."],
                    ["mira", "…이런 말 하면 꼭 무슨 일이 생기더라고요."]]},
            {"id": "rho", "actor": "rho", "label": "준",
                "lines": [["rho", "오늘 저녁은 내가 했어. 맛없으면 세나 탓이야. 걔가 불 세기 정했어."],
                    ["rho", "…농담 나오는 거 보니까 나 오늘 괜찮은가 봐."]]}
        ],
        "results": {
            "success": {"lines": [["mira", "이렇게 다 같이 있으니까 좋네요. …오래가면 좋겠다."]],
                "trust": {"mira": 0.04, "lyra": 0.04, "rho": 0.04}, "note": "라운지 · 식사표에 내 이름 칸이 있다. 내가 쓰지 않은 필체로.",
                "hook": {"lyra": "success"}, "memory_tag": "interlude:continuity_meal_table"},
            "partial": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"lyra": {"success": "어제 저녁 좋았죠. …그래서 오늘 이 일이 더 싫어요."}}
    },
    "threshold_final": {
        "case_id": "THRESHOLD",
        "day": 1,
        "title": "함교 · 마지막 공백",
        "caption": "STAGE 13 · 함교",
        "size": [15, 9],
        "door": [6, 9],
        "props": [
            {"id": "bridge_console", "rect": [4, 1, 7, 1], "kind": "console", "label": "함교 콘솔", "solid": true},
            {"id": "gap_display", "rect": [12, 1, 2, 2], "kind": "speaker", "label": "공백 표시", "solid": true},
            {"id": "window", "rect": [1, 0, 3, 1], "kind": "window", "label": "창", "solid": false}
        ],
        "actors": [
            {"id": "noa", "at": [5.5, 2.3], "facing": "up", "idle": "work"},
            {"id": "dax", "at": [9.5, 2.3], "facing": "up", "idle": "work"},
            {"id": "mira", "at": [7.5, 5.8], "facing": "up", "idle": "watch"}
        ],
        "spawn": [7.5, 8.2],
        "targets": [
            {"id": "mira", "actor": "mira", "label": "미라",
                "lines": [["mira", "여기까지 왔네요. 처음 의료실에서 당신이 눈을 떴을 때, 제가 제일 먼저 물었잖아요. 괜찮냐고."],
                    ["mira", "…지금 다시 물을게요. 괜찮아요?"]]},
            {"id": "gap_display", "prop": "gap_display", "label": "공백 표시",
                "lines": [["", "함교 화면 구석, 긴 공백 표시가 꺼지지 않는다. 식사 배급표 다음 줄에 한 문장이 있다: ‘장기수면 재개’."]]},
            {"id": "dax", "actor": "dax", "label": "다렌",
                "lines": [["dax", "이 명령은 한 번 입력된 게 아니야. 매 주기 다시 입력됐어. 같은 손으로."],
                    ["dax", "누가 우리를 다시 재우는지는 기록에 없어. 기록에 없다는 게, 이번엔 답이야."]]},
            {"id": "noa", "actor": "noa", "label": "노아", "task": "order",
                "lines": [["noa", "공백 앞뒤의 마지막 기록 네 줄이에요. 순서대로 놓으면 경계가 보여요."],
                    ["noa", "…같이 봐 줘요. 이번엔 제 기록이 아니라, 우리 기록이니까."]]}
        ],
        "task": {"kind": "order", "title": "공백의 경계",
            "items": [["도착 40일차 · 식사 배급표 갱신", 0], ["재수면 명령 입력 · 서명 없음", 1], ["전원 장기수면 진입", 2], ["각성 · 의료실 · 탐사요원 첫 기록", 3]],
            "insight": "살다가, 누군가의 명령으로 다시 잠들었다. 그리고 당신이 먼저 깨어났다."},
        "results": {
            "success": {"lines": [["noa", "…우리는 도착해서 살았어요. 그리고 누군가의 명령으로 다시 잠들었어요."],
                    ["noa", "그 다음 줄이 당신이에요. 탐사요원이 먼저 깨어났다는 기록."],
                    ["dax", "그럼 질문은 하나 남아. 왜 당신만 기억하느냐."]],
                "trust": {"noa": 0.05, "dax": 0.05, "mira": 0.05}, "grant": "EXPERT_INFERENCE",
                "note": "함교 · 도착 후 살다가 서명 없는 명령으로 다시 잠들었다. 그다음 기록이 나다.",
                "hook": {"noa": "success"}, "memory_tag": "interlude:threshold_boundary"},
            "partial": {"lines": [["noa", "…다 맞추지 못했어요. 괜찮아요. 끝나기 전에 다시 봐요."]],
                "trust": {"noa": 0.02}, "note": "함교 · 공백의 경계를 다 맞추지 못했다.",
                "hook": {"noa": "partial"}, "memory_tag": "interlude:threshold_boundary"},
            "skipped": {"lines": [], "trust": {}, "note": "", "hook": {}, "memory_tag": ""}
        },
        "hook_lines": {"noa": {"success": "아까 함교에서 같이 놓은 네 줄이요. 마지막 줄이 당신이었어요. …그게 계속 걸려요.",
            "partial": "아까 못 맞춘 네 줄, 혼자 다시 봤어요. 삭제는 로컬 단말에서 됐어요. 원격 흔적은 없어요."}}
    }
}

static func for_case(case_id: String, day: int) -> String:
    for id in INTERLUDES:
        var entry: Dictionary = INTERLUDES[id]
        if str(entry.get("case_id", "")) == case_id and int(entry.get("day", 1)) == day:
            return str(id)
    return ""

static func data(id: String) -> Dictionary:
    var result := Dictionary(INTERLUDES.get(id, {})).duplicate(true)
    if id == "blind_deck_door":
        # 1.0: the door is reached by planning the way back first.
        result["task"] = ROUTE_TASK.duplicate(true)
        for target in result["targets"]:
            if str(target.get("id", "")) == "new_door":
                target.erase("complete")
            if str(target.get("id", "")) == "eli":
                target["task"] = "safe_route"
                target["lines"].append(["eli", "문부터 열지 마. 여기서 돌아오는 길까지 짚고 가자. 산소는 왕복 분량으로 세고."])
    if str(result.get("task", {}).get("kind", "")) == "order":
        # 1.0 evidence timeline: order, then the boundary that does not fit,
        # then what it means (only the first reading follows from the cards).
        result["task"]["gap_after"] = int(TIMELINE_GAP.get(id, 0))
        result["task"]["conclusions"] = [str(result["task"]["insight"]), "기록의 순서만으로 누가 사건을 일으켰는지 알 수 있다.", "지금 기억과 다르니 기록 전체를 버려도 된다."]
    return result

# Where the authored records stop making sense, as "after rank N".
#   samples: the destination soil was taken before departure;
#   duty logs: a crew living normally after arrival prepares to sleep again;
#   the last boundary: normal life, then an unsigned order to sleep.
const TIMELINE_GAP := {"red_shift_samples": 0, "second_watch_logs": 2, "threshold_final": 0}
const ROUTE_TASK := {"kind": "safe_route", "title": "귀환 경로 · 지도에서 지워진 문", "helper": "루칸"}

static func all_ids() -> Array:
    return INTERLUDES.keys()
