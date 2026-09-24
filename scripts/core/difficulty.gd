class_name AstraDifficulty
extends RefCounted

# Difficulty is a set of named knobs, never "more junk to read".
#
# The 0.3.1 lever for difficulty was decoy_traces — clues whose timestamp falls
# outside the incident window and which therefore mean nothing. Adding more of
# those makes a case longer, not harder: the player still solves it the same
# way, just after more scrolling. 0.4.0 keeps decoys roughly flat and moves the
# difficulty into how people behave: how smoothly a Null lies, how often two
# people cover for each other, and how much help the game volunteers.

const MODES := {
    "STORY": {
        "name": "스토리",
        "summary": "처음 하는 사람을 위한 속도",
        "detail": "첫 Stage의 첫날 밤에는 비상 격벽이 한 번 선실을 지킵니다. Null은 탐사요원을 덜 노립니다.",
        "first_night_safe": true,
        "decoy_scale": 0.5,
        "mutual_alibi_scale": 0.4,
        "lie_polish": 0.35,
        "meeting_lines": 5,
        "recommend_rooms": true,
        "contradiction_recheck": true,
        "extra_talk_ap": 1,
        "player_target_scale": 0.5,
        "conviction_scale": 0.85,
        "bandwagon_scale": 0.8,
        "null_persistence": 0.3,
        "hint_level": 2
    },
    "STANDARD": {
        "name": "표준",
        "summary": "사회추리 게임에 익숙한 사람",
        "detail": "기본 균형입니다. 첫날 밤부터 누구든 위험합니다.",
        "first_night_safe": false,
        "decoy_scale": 1.0,
        "mutual_alibi_scale": 1.0,
        "lie_polish": 0.65,
        "meeting_lines": 7,
        "recommend_rooms": false,
        "contradiction_recheck": true,
        "extra_talk_ap": 0,
        "player_target_scale": 0.72,
        "conviction_scale": 1.0,
        "bandwagon_scale": 1.0,
        "null_persistence": 0.55,
        "hint_level": 1
    },
    "EXPERT": {
        "name": "전문가",
        "summary": "사람이 더 잘 속인다",
        "detail": "두 Null이 서로를 보증하는 일이 늘고, Null은 당신을 더 적극적으로 노립니다. 쓸모없는 단서를 늘려 어렵게 만들지는 않습니다.",
        "first_night_safe": false,
        "decoy_scale": 1.0,
        "mutual_alibi_scale": 1.45,
        "lie_polish": 0.92,
        "meeting_lines": 8,
        "recommend_rooms": false,
        "contradiction_recheck": false,
        "extra_talk_ap": 0,
        "player_target_scale": 0.9,
        "conviction_scale": 1.15,
        "bandwagon_scale": 1.15,
        "null_persistence": 0.75,
        "hint_level": 0
    }
}

const ORDER := ["STORY", "STANDARD", "EXPERT"]

static func has_mode(mode: String) -> bool:
    return MODES.has(mode)

static func get_mode(mode: String) -> Dictionary:
    return MODES.get(mode, MODES["STANDARD"])

static func value(mode: String, key: String, fallback = null):
    return get_mode(mode).get(key, fallback)

static func mode_name(mode: String) -> String:
    return str(get_mode(mode).get("name", mode))

static func flag(mode: String, key: String) -> bool:
    return bool(get_mode(mode).get(key, false))

static func number(mode: String, key: String, fallback: float = 1.0) -> float:
    return float(get_mode(mode).get(key, fallback))
