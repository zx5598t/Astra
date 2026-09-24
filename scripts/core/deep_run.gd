class_name AstraDeepRun
extends RefCounted

# DEEP RECONSTRUCTION (심층 재구성): the endless mode that opens after the
# campaign (§37-§51 of the campaign brief). Same people, same rules, no story
# reveals. One life: dying, or the Nulls taking the vote, ends the run.
#
#   run file (RUN_PATH): run_seed, depth, protocol, ended, stats. Every depth is
#   generated from run_seed + depth, so a reload never re-rolls anything.
#   session file (SESSION_PATH): the depth in progress, for crash resume.
#   A lost depth closes the run at once (ended = true) and deletes the session
#   file, so an old autosave cannot bring a dead run back (§44).
#
# Difficulty rises with the roster, the second Null and one announced
# modifier per depth from depth 4 — never by hiding the fair evidence path.

const RUN_PATH := "user://astra_deep.run"
const SESSION_PATH := "user://astra_deep.session"
const VERSION := 1

# Depth 1-3: 4-5 awake, one Null. 4-6: 6-7 awake, one Null. 7+: all eight,
# two Nulls (the Part II rooms, cycling).
const DEPTH_CASES := ["CALIBRATION", "DEAD_AIR", "DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "ECHO_WARD"]
const LATE_CASES := ["SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT", "SECOND_WATCH", "BORROWED_DAYS", "BLIND_DECK", "THREE_MINUTES_DARK", "CONTINUITY", "THRESHOLD"]

const MODIFIERS := {
    "STATIC": {"name": "잡음", "text": "직접 본 사람들이 회의에서 먼저 말하지 않습니다. 목격은 물어서 들어야 합니다."},
    "BLACKOUT": {"name": "정전", "text": "기록 담당자들이 스스로 기록을 열어 보는 일이 드뭅니다. 같이 열지 않은 기록은 밤사이 지워질 수 있습니다."},
    "DIVIDED": {"name": "분열", "text": "사람들 사이의 호감과 반감이 크게 갈라져 있습니다. 감싸는 말도, 몰아가는 말도 늘어납니다."},
    "ECHO": {"name": "메아리", "text": "어제 한 말이 오늘 더 무겁습니다. 말을 바꾼 사람이 더 크게 눈에 띕니다."},
    "SILENT_DECK": {"name": "고요한 갑판", "text": "회의의 논쟁이 하나 줄어듭니다. 대화에서 무엇을 들었는지가 더 중요합니다."}
}

# Between depths: one short line from someone still standing (§49).
const BETWEEN_LINES := {
    "mira": ["이번 재구성은 너무 빨랐어요. …다들 괜찮죠?", "다음 아침도 제가 먼저 물을게요. 괜찮냐고.", "방금 그 사람… 전과 조금 달랐죠?"],
    "rho": ["한 판 더? 좋아. 공구는 챙겼어.", "이번엔 내가 좀 빨랐다. 인정.", "아까 그거, 나도 찝찝했어."],
    "dax": ["변수가 하나 더 늘 거야. 계산은 계속하자.", "이번 결론은 근거가 탄탄했어.", "다음 깊이도 같은 방식으로."],
    "noa": ["깊이 하나, 적어 둘게요.", "기록이 점점 겹쳐요. 그래도 읽을 수 있어요.", "방금 재구성, 시각이 조금 달랐어요."],
    "sena": ["문은 다시 잠겼어. 다음.", "이번엔 지켰다. 다음도 지킨다.", "쉬는 건 나중에."],
    "vale": ["…신호가 한 겹 더 깊어졌어요.", "방금 목소리들, 기억해 둘게요.", "다음엔 더 조용할 거예요. 그게 더 어려워요."],
    "eli": ["좌표 갱신. 다음 깊이.", "시계 맞춰. 다시 간다.", "동선이 점점 복잡해져."],
    "lyra": ["잎이 또 자랐어요. 여기서도요.", "다음 아침에도 물은 줄게요.", "…다들 조금 지쳐 보여요. 그래도요."]
}

static func case_for_depth(depth: int) -> String:
    var d := maxi(1, depth)
    if d <= DEPTH_CASES.size():
        return str(DEPTH_CASES[d - 1])
    return str(LATE_CASES[(d - DEPTH_CASES.size() - 1) % LATE_CASES.size()])

static func modifier_for(run_seed: int, depth: int) -> String:
    if depth < 4:
        return ""
    var keys: Array = MODIFIERS.keys()
    keys.sort()
    return str(keys[absi(hash("%d|%d|deep_mod" % [run_seed, depth])) % keys.size()])

static func depth_seed(run_seed: int, depth: int) -> int:
    return absi(hash("%d|%d|deep_depth" % [run_seed, depth])) % 2147483

static func new_run(protocol: String) -> Dictionary:
    return {"version": VERSION, "run_seed": AstraGameSession.fresh_seed(), "depth": 1, "protocol": protocol, "ended": false,
        "stats": {"contained": 0, "saved": 0, "votes_right": 0, "votes_total": 0, "contradictions": 0, "protects": 0},
        "started_at": Time.get_datetime_string_from_system()}

static func load_run(path: String = RUN_PATH) -> Dictionary:
    var cfg := ConfigFile.new()
    if cfg.load(path) != OK:
        return {}
    var run: Dictionary = cfg.get_value("deep", "run", {})
    if int(run.get("version", 0)) != VERSION:
        return {}
    return run

static func save_run(run: Dictionary, path: String = RUN_PATH) -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("deep", "run", run)
    return cfg.save(path) == OK

static func active_run(path: String = RUN_PATH) -> Dictionary:
    var run := load_run(path)
    if run.is_empty() or bool(run.get("ended", false)):
        return {}
    return run

static func accuracy(run: Dictionary) -> int:
    var stats: Dictionary = run.get("stats", {})
    return int(round(100.0 * float(stats.get("votes_right", 0)) / maxf(1.0, float(stats.get("votes_total", 0)))))

# Adds a finished depth's numbers to the run: Nulls contained, crew standing
# at the end, how often the explorer's own ballot named a Null.
static func record_depth(run: Dictionary, s: AstraGameSession) -> void:
    var stats: Dictionary = run.get("stats", {})
    var report := s.final_report
    stats["contained"] = int(stats.get("contained", 0)) + int(report.get("null_isolated", 0))
    stats["saved"] = int(stats.get("saved", 0)) + int(report.get("survivors", 0))
    for round in s.stage_state().get("vote_rounds", []):
        var ballot := str(Dictionary(round.get("ballots", {})).get("player", ""))
        if ballot == "" or not s.crew.has(ballot):
            continue
        stats["votes_total"] = int(stats.get("votes_total", 0)) + 1
        if s.crew[ballot].is_null():
            stats["votes_right"] = int(stats.get("votes_right", 0)) + 1
    stats["contradictions"] = int(stats.get("contradictions", 0)) + int(s.stats.get("public_contradictions", 0))
    stats["protects"] = int(stats.get("protects", 0)) + int(s.stats.get("protects", 0))
    run["stats"] = stats

static func between_line(npc_id: String, depth: int) -> String:
    var lines: Array = BETWEEN_LINES.get(npc_id, [])
    if lines.is_empty():
        return ""
    return str(lines[posmod(depth * 7 + npc_id.length(), lines.size())])
