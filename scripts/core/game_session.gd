class_name AstraGameSession
extends RefCounted

# Single authoritative game model for one Stage (0.8.0 CONTAINMENT).
# UI reads state and calls the public methods; it never edits state directly.
#
# Stage = one containment game (a case_id). Day = one round inside it:
#   BRIEFING (아침) -> INTERROGATION (대화) -> MEETING (회의) -> VOTE (투표) -> NIGHT (밤)
# Every Day ends with exactly one isolation. The Stage ends CLEAR when every
# Null is contained, and FAIL when the explorer is killed or the Null side
# holds at least as many votes as the crew side (the explorer counts while
# alive). There is no normal TIMEOUT; MAX_DAYS is an internal safety net.
#
# Stage truth (who the Nulls are) is fixed at setup. Each Day gets its own
# Day Packet (AstraCaseGenerator.generate_day_packet), stored in the snapshot.
# INVESTIGATION and EXPLORE remain only as legacy phase names for old saves.

signal changed
signal phase_changed(phase: String)
signal notice(kind: String, payload: Dictionary)

const PHASES := ["EXPLORE", "BRIEFING", "INVESTIGATION", "INTERROGATION", "MEETING", "VOTE", "NIGHT", "RESULT"]
const PHASE_LABELS := {
    "EXPLORE": "대화",
    "BRIEFING": "아침", "INVESTIGATION": "대화", "INTERROGATION": "대화",
    "MEETING": "회의", "VOTE": "투표", "NIGHT": "밤", "RESULT": "결과"
}
const MAX_DAYS := AstraCaseCatalog.MAX_INTERNAL_DAYS
const PLAYER_VOTE_WEIGHT := 1
const CONFIDE_TRUST := 0.6
const SNAPSHOT_PATH := "user://astra_session.cfg"
const SNAPSHOT_VERSION := 4
# v1-v3 (0.3.1-0.7.4) snapshots are still read: they are migrated to a fresh
# Day 1 of the same Stage (see load_snapshot). Settings and the archive are
# untouched by that.
const SUPPORTED_SNAPSHOT_VERSIONS := [1, 2, 3, 4]
const FIELDS_ADDED_IN_040 := [
    "roster", "null_count", "max_days", "difficulty",
    "claim_ledger", "retractions", "dialogue_recent", "social_beats", "player_claims"
]
const SNAPSHOT_FIELDS := [
    "voyage",
    "case_id", "seed_value", "protocol", "roster", "null_count", "max_days", "difficulty",
    "claim_ledger", "retractions", "dialogue_recent", "social_beats", "player_claims", "truth", "clues", "day", "phase",
    "investigation_ap", "talk_ap", "meeting_actions_left", "selected_id", "marks",
    "known_claims", "public_claims", "manual_contradictions", "contradictions",
    "public_contradiction_keys", "transcripts", "meeting_feed", "journal", "isolations",
    "casualties", "morning_report", "pending_event", "events_seen", "theories", "vote_cast",
    "last_vote", "night_done", "night_plan", "night_result", "outcome", "stats", "flags",
    "disputes_done", "meeting_pushers", "accused_today", "final_report", "_found_counter"
]
const CREW_SNAPSHOT_FIELDS := [
    "role", "status", "trust", "stress", "suspicion", "affinity", "expression",
    "secret_revealed", "slipped", "audited", "questions_asked", "memories"
]

# Specialist protocols. Part I has none. Part II opens one per Stage from
# Stage 5 (GUARDIAN), 6 (ANALYST), 7 (EMPATH); one is equipped at a time. None
# of them ever says who is a Null.
const PROTOCOLS := {
    "NONE": {"name": "기본", "summary": "전문 프로토콜 없이 대화와 투표로 판단한다.", "detail": "", "stage": 1},
    "GUARDIAN": {"name": "가디언", "summary": "밤에 Aegis 차폐로 한 사람을 지킨다. Stage당 2회.",
        "detail": "자기 자신도 보호할 수 있다. 같은 대상을 이틀 밤 연속 보호할 수는 없다. 막아 내면 누가 공격받았는지만 알 수 있다.", "stage": 5},
    "ANALYST": {"name": "애널리스트", "summary": "하루 한 번, 두 진술이나 진술과 기록을 정밀 대조한다.",
        "detail": "결과는 일치 · 충돌 · 판단 불가 중 하나다. 누가 Null인지는 알려 주지 않는다.", "stage": 6},
    "EMPATH": {"name": "엠패스", "summary": "하루 한 번, 한 사람에게 한 걸음 더 묻거나 회의에 한 번 더 끼어든다.",
        "detail": "감정 반응과 방어하는 태도, 관계를 읽는다. 거짓말을 판정해 주지는 않는다.", "stage": 7}
}
# Legacy ids: AUDITOR revealed an isolated person's exact role and is removed.
# Old saves map it onto ANALYST (the nearest remaining logic protocol) when
# that protocol exists for the Stage, otherwise onto NONE.
const LEGACY_PROTOCOLS := {"AUDITOR": "ANALYST"}
const GUARDIAN_CHARGES := 2

const ISOLATED_LINES := {
    "mira": "…알겠어요. 제 기록이 끝까지 도움이 되길 바라요.",
    "rho": "공구는 문 앞에 둘게. 펌프 소리 달라지면 바로 멈춰.",
    "eli": "항로 사본은 남겼어. 좌표를 다시 확인해.",
    "sena": "알았어. 문은 닫을게. 밖에 있는 사람들 잘 봐 줘.",
    "vale": "탐사요원님… 이게 정말 맞는 선택이길 바라요.",
    "noa": "마지막 기록이에요. ‘나는 끝까지 말을 바꾸지 않았다.’",
    "lyra": "괜찮아요… 다들, 서로를 너무 미워하지는 마요.",
    "dax": "내 판단도 틀릴 수 있어. 그러니까 기록은 지우지 마."
}

var voyage: Dictionary = {}
var case_id: String = ""
var case_data: Dictionary = {}
var seed_value: int = 0
var protocol: String = "NONE"
var rng := RandomNumberGenerator.new()
var truth: Dictionary = {}
var crew: Dictionary = {}
var clues: Array = []

var roster: Array = []
var null_count: int = 1
var max_days: int = MAX_DAYS
var difficulty: String = "STANDARD"

# Unlocked feature ids, handed in by the app. Empty means "no gating", which is
# what the automated suites want.
var features: Array = []

var claim_ledger: Array = []
var retractions: Array = []
var dialogue_recent: Array = []
var social_beats: Array = []
var player_claims: Array = []

var day: int = 1
var phase: String = "BRIEFING"
var investigation_ap: int = 0
var talk_ap: int = 0
var meeting_actions_left: int = 0
var selected_id: String = ""
var marks: Dictionary = {}

var known_claims: Dictionary = {}
var public_claims: Dictionary = {}
var manual_contradictions: Array = []
var contradictions: Array = []
var public_contradiction_keys: Dictionary = {}
var transcripts: Dictionary = {}
var meeting_feed: Array = []
var journal: Array = []
var isolations: Array = []
var casualties: Array = []
var morning_report: Array = []
var pending_event: Dictionary = {}
var events_seen: Dictionary = {}
var theories: Array = []
var vote_cast: bool = false
var last_vote: Dictionary = {}
var night_done: bool = false
var night_plan: Dictionary = {}
var night_result: Dictionary = {}
var outcome: String = ""
var stats: Dictionary = {}
var flags: Dictionary = {}
var disputes_done: Dictionary = {}
var meeting_pushers: Dictionary = {}
var accused_today: Dictionary = {}
var final_report: Dictionary = {}
var _found_counter: int = 0

# ---------------------------------------------------------------- setup

func setup(case_id_in: String, seed_in: int, protocol_in: String = "NONE", difficulty_in: String = "STANDARD", history: Array = []) -> void:
    voyage.clear()
    case_id = case_id_in if AstraCaseCatalog.has_case(case_id_in) else AstraCaseCatalog.CALIBRATION
    seed_value = seed_in
    case_data = AstraCaseCatalog.resolve(case_id, seed_in)
    difficulty = difficulty_in if AstraDifficulty.has_mode(difficulty_in) else "STANDARD"
    roster = AstraCaseCatalog.roster(case_data)
    null_count = AstraCaseCatalog.null_count(case_data)
    max_days = MAX_DAYS
    rng.seed = seed_in * 7919 + 17
    # Stage truth. `history` is the archive's record of who has recently been
    # Null; the draw damps repeats without ever making a rotation.
    truth = AstraCaseGenerator.generate(case_id, seed_in, history, difficulty)
    truth["stage"] = stage_index()
    clues = []
    claim_ledger.clear()
    retractions.clear()
    dialogue_recent.clear()
    social_beats.clear()
    player_claims.clear()

    crew.clear()
    for npc_id in roster:
        var member := AstraCrewMember.new(npc_id)
        member.role = "NULL" if npc_id in truth.get("nulls", []) else "CREW"
        crew[npc_id] = member
    for a in roster:
        for b in roster:
            if a == b:
                continue
            var affinity := clampf(rng.randf_range(-0.2, 0.28) + AstraCrewCatalog.affinity_bias(a, b), -1.0, 1.0)
            crew[a].affinity[b] = affinity
            crew[a].suspicion[b] = clampf(0.2 + rng.randf_range(-0.06, 0.08) - affinity * 0.1, 0.0, 1.0)

    day = 1
    phase = "BRIEFING"
    investigation_ap = 0
    talk_ap = 0
    meeting_actions_left = 0
    selected_id = str(roster[0])
    marks.clear()
    known_claims.clear()
    public_claims.clear()
    manual_contradictions.clear()
    contradictions.clear()
    public_contradiction_keys.clear()
    transcripts.clear()
    meeting_feed.clear()
    journal.clear()
    isolations.clear()
    casualties.clear()
    morning_report.clear()
    pending_event.clear()
    events_seen.clear()
    theories.clear()
    vote_cast = false
    last_vote.clear()
    night_done = false
    night_plan.clear()
    night_result.clear()
    outcome = ""
    flags.clear()
    flags["knowledge_052"] = {"facts":{}, "propagation":[]}
    flags["decision_traces_052"] = []
    flags["vote_history_052"] = []
    flags["stage_080"] = _new_stage_state()
    protocol = normalize_protocol(protocol_in)
    disputes_done.clear()
    meeting_pushers.clear()
    accused_today.clear()
    final_report.clear()
    _found_counter = 0
    stats = {
        "public_contradictions": 0, "confessions": 0, "admissions": 0, "protects": 0,
        "accusations": 0, "defenses": 0, "presented": 0, "conversations": 0, "cross_exams": 0,
        "clues_found": 0, "slips": 0, "secrets": 0, "destroyed": 0
    }
    for npc_id in roster:
        transcripts[npc_id] = []
    for member in crew.values():
        member.refresh_expression()
    _install_day_packet(1)
    _assign_null_styles()
    _queue_morning(1)
    _log("STAGE %d · %s · DAY 1" % [stage_index(), str(case_data.get("title", ""))])
    changed.emit()

# ---------------------------------------------------------------- Deep Reconstruction

# One depth of DEEP RECONSTRUCTION: a Stage room without its story, the
# run's protocol at every depth, and the depth's announced modifier.
func setup_deep(case_in: String, seed_in: int, protocol_in: String, depth: int, modifier: String, difficulty_in: String = "STANDARD") -> void:
    setup(case_in, seed_in, "NONE", difficulty_in)
    flags["deep"] = {"depth": depth, "modifier": modifier}
    if protocol_in in ["GUARDIAN", "ANALYST", "EMPATH"]:
        protocol = protocol_in
        stage_state()["protocol_chosen"] = true
    if modifier == "DIVIDED":
        for a in roster:
            for b in roster:
                if a != b:
                    crew[a].affinity[b] = clampf(float(crew[a].affinity.get(b, 0.0)) * 1.8, -1.0, 1.0)
    # Re-read today with the modifier in force (who already opened their logs).
    stage_state()["unread"] = {}
    _install_day_packet(1)
    _queue_morning(1)
    _log("심층 재구성 · 깊이 %d%s" % [depth, (" · " + str(AstraDeepRun.MODIFIERS.get(modifier, {}).get("name", ""))) if modifier != "" else ""])
    changed.emit()

func is_deep() -> bool:
    return flags.has("deep")

func deep_depth() -> int:
    return int(Dictionary(flags.get("deep", {})).get("depth", 0))

func deep_modifier() -> String:
    return str(Dictionary(flags.get("deep", {})).get("modifier", ""))

# ---------------------------------------------------------------- Null play styles
# A Null keeps its own personality and adds one way of surviving (§64). The
# style is never shown and never changes how a line is worded; it decides whom
# a Null pushes, shields and votes for.
#   DEFLECTOR     : leans on someone else's real contradiction or lonely alibi
#   QUIET         : never leads, agrees late, votes with the room
#   ALLY          : has spent the wake cycle being easy to trust for one person
#   COUNTERATTACK : goes after whoever put evidence against it on the table
const NULL_STYLES := {
    "mira": ["ALLY", "QUIET", "DEFLECTOR"], "rho": ["ALLY", "DEFLECTOR", "COUNTERATTACK"],
    "dax": ["DEFLECTOR", "QUIET", "COUNTERATTACK"], "noa": ["DEFLECTOR", "QUIET"],
    "sena": ["COUNTERATTACK", "DEFLECTOR", "ALLY"], "vale": ["QUIET", "DEFLECTOR"],
    "eli": ["QUIET", "COUNTERATTACK", "DEFLECTOR"], "lyra": ["ALLY", "QUIET", "DEFLECTOR"]
}

func _assign_null_styles() -> void:
    var styles := {}
    var allies := {}
    var nulls: Array = truth.get("nulls", [])
    for null_id in nulls:
        var options: Array = NULL_STYLES.get(str(null_id), ["DEFLECTOR"])
        var style := str(options[int(_stable_noise("style:" + str(null_id)) * options.size()) % options.size()])
        styles[str(null_id)] = style
        if style != "ALLY":
            continue
        var best := ""
        var best_value := -9.0
        for other in roster:
            if str(other) == str(null_id) or str(other) in nulls or str(other) in allies.values():
                continue
            var value: float = crew[other].get_affinity(str(null_id)) + _stable_noise("ally:%s:%s" % [null_id, other]) * 0.2
            if value > best_value:
                best_value = value
                best = str(other)
        if best != "":
            allies[str(null_id)] = best
            crew[best].affinity[str(null_id)] = clampf(crew[best].get_affinity(str(null_id)) + 0.3, -1.0, 1.0)
    stage_state()["null_styles"] = styles
    stage_state()["null_allies"] = allies

func null_style(null_id: String) -> String:
    return str(stage_state().get("null_styles", {}).get(null_id, "DEFLECTOR"))

func null_ally(null_id: String) -> String:
    return str(stage_state().get("null_allies", {}).get(null_id, ""))

# How visibly `crew_id` has stood against `null_id` in front of everyone: a
# public accusation, a record or sighting of theirs put on the table.
func _stood_against(crew_id: String, null_id: String) -> float:
    var value := 0.0
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("speaker", "")) == crew_id and str(entry.get("target", "")) == null_id:
            value += 0.5 if int(entry.get("day", 0)) == day else 0.2
    for id in stage_state().get("public_presented", []):
        var item := fragment(str(id))
        if str(item.get("owner", "")) == crew_id and null_id in Array(item.get("points_to", [])):
            value += 0.6
    return value

func _public_conflicts_on(npc_id: String) -> int:
    var count := 0
    for entry in manual_contradictions:
        if int(entry.get("day", 0)) == day and npc_id in Array(entry.get("targets", [])):
            count += 1
    return count

func _new_stage_state() -> Dictionary:
    return {
        "version": 1, "stage": stage_index(), "part": part(),
        "player_alive": true,
        "packets": {},
        "conversations": {}, "record_checks": {}, "analyst_uses": {}, "empath_uses": {}, "interventions": {},
        "asked": {},
        "vote_stage": "BALLOT", "runoff": [], "vote_rounds": [],
        "guardian": {"charges": GUARDIAN_CHARGES, "last_target": "", "history": []},
        "night_log": [], "shield_used": false,
        "story_queue": [], "story_index": 0, "story_line": 0, "story_seen": [],
        "confessions": {}, "admissions": {}, "analyses": [],
        "public_accusations": [], "public_defenses": [], "public_presented": [], "public_log": [],
        # 0.8.2 runtime-only agency telemetry. It lives inside stage_state so snapshot v4
        # can carry it without a new schema field; old v4 snapshots hydrate lazily.
        "agency_contacts": {}, "agency_events": [], "agency_vote_changes": [],
        "player_confronted": {}, "outcome_reason": "", "result_story": false,
        "recovered": []
    }

func stage_state() -> Dictionary:
    if not flags.has("stage_080"):
        flags["stage_080"] = _new_stage_state()
    return flags["stage_080"]

func stage_index() -> int:
    return AstraCaseCatalog.stage_index(case_id)

func part() -> int:
    return AstraCaseCatalog.part_for(case_id)

func player_alive() -> bool:
    return bool(stage_state().get("player_alive", true))

# Protocols the explorer can equip in this Stage.
static func protocols_for_stage(stage: int) -> Array:
    var result: Array = []
    for id in ["GUARDIAN", "ANALYST", "EMPATH"]:
        if stage >= int(PROTOCOLS[id]["stage"]):
            result.append(id)
    return result

func available_protocols() -> Array:
    return protocols_for_stage(stage_index())

func normalize_protocol(requested: String) -> String:
    var id := str(LEGACY_PROTOCOLS.get(requested, requested))
    if id in available_protocols():
        return id
    return "NONE"

# Only at the very start of a Stage (Day 1 morning) can the protocol change.
func can_change_protocol() -> bool:
    return phase == "BRIEFING" and day == 1 and not available_protocols().is_empty() and outcome == ""

func set_protocol(requested: String) -> bool:
    if not can_change_protocol():
        return false
    var id := normalize_protocol(requested)
    if id != requested:
        return false
    protocol = id
    _log("전문 프로토콜 · " + protocol_name())
    changed.emit()
    return true

func protocol_name() -> String:
    return str(PROTOCOLS.get(protocol, PROTOCOLS["NONE"]).get("name", protocol))

# ---------------------------------------------------------------- snapshots

# Snapshots contain only whitelisted scalar/array/dictionary state, never Nodes
# or serialized objects. RNG state is preserved so resuming cannot reroll a vote.
func save_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    if case_id == "" or phase == "RESULT":
        return false
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "version", SNAPSHOT_VERSION)
    cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system())
    cfg.set_value("session", "rng_state", rng.state)
    for field in SNAPSHOT_FIELDS:
        cfg.set_value("session", field, get(field))
    for npc_id in roster:
        for field in CREW_SNAPSHOT_FIELDS:
            cfg.set_value("crew_" + npc_id, field, crew[npc_id].get(field))
    var temporary := path + ".tmp"
    if cfg.save(temporary) != OK:
        return false
    var absolute := ProjectSettings.globalize_path(path)
    if FileAccess.file_exists(path):
        if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
            return false
        if DirAccess.remove_absolute(absolute) != OK:
            return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) == OK

static func snapshot_info(path: String = SNAPSHOT_PATH) -> Dictionary:
    for candidate in [path, path + ".bak"]:
        var cfg := ConfigFile.new()
        if cfg.load(candidate) != OK or int(cfg.get_value("meta", "version", 0)) not in SUPPORTED_SNAPSHOT_VERSIONS:
            continue
        var saved_case := str(cfg.get_value("session", "case_id", ""))
        var saved_phase := str(cfg.get_value("session", "phase", ""))
        if not AstraCaseCatalog.has_case(saved_case) or saved_phase not in PHASES or saved_phase == "RESULT":
            continue
        var version := int(cfg.get_value("meta", "version", 0))
        return {"case_id": saved_case, "phase": saved_phase, "day": int(cfg.get_value("session", "day", 1)) if version >= 4 else 1,
            "stage": AstraCaseCatalog.stage_index(saved_case), "legacy": version < 4,
            "saved_at": str(cfg.get_value("meta", "saved_at", ""))}
    return {}

static var _seed_counter: int = 0

# A new reconstruction (new campaign, "이 Stage 다시", a Stage replay) always
# gets a new seed, never the one it replaces; loading a save restores the saved
# seed and Day Packets instead (RELOAD is not REROLL).
static func fresh_seed(previous: int = -1) -> int:
    _seed_counter += 1
    var value := absi(hash("%d|%d|%d" % [Time.get_ticks_usec(), int(Time.get_unix_time_from_system() * 1000.0), _seed_counter])) % 2147483
    if value == previous:
        value = (value + 7919) % 2147483
    return value

static func has_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    return not snapshot_info(path).is_empty()

static func delete_snapshot(path: String = SNAPSHOT_PATH) -> void:
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path + suffix):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func load_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    for candidate in [path, path + ".bak"]:
        var cfg := ConfigFile.new()
        if cfg.load(candidate) != OK:
            continue
        var version := int(cfg.get_value("meta", "version", 0))
        if version not in SUPPORTED_SNAPSHOT_VERSIONS:
            continue
        if version < 4:
            if _migrate_legacy_snapshot(cfg):
                return true
            continue
        if not _valid_snapshot(cfg):
            continue
        for field in SNAPSHOT_FIELDS:
            if cfg.has_section_key("session", field):
                set(field, cfg.get_value("session", field))
        case_data = AstraCaseCatalog.resolve(case_id, seed_value)
        if roster.is_empty():
            roster = AstraCaseCatalog.roster(case_data)
        if null_count <= 0:
            null_count = AstraCaseCatalog.null_count(case_data)
        max_days = MAX_DAYS
        if not AstraDifficulty.has_mode(difficulty):
            difficulty = "STANDARD"
        protocol = normalize_protocol(protocol)
        crew.clear()
        for npc_id in roster:
            var member := AstraCrewMember.new(npc_id)
            for field in CREW_SNAPSHOT_FIELDS:
                if field == "memories":
                    member.memories.assign(cfg.get_value("crew_" + npc_id, field))
                else:
                    member.set(field, cfg.get_value("crew_" + npc_id, field))
            crew[npc_id] = member
        if phase in ["INVESTIGATION", "EXPLORE"]:
            phase = "INTERROGATION"
        pending_event.clear()
        _hydrate_054_voyage_defaults()
        rng.seed = seed_value * 7919 + 17
        rng.state = int(cfg.get_value("session", "rng_state"))
        if current_packet().is_empty():
            _install_day_packet(day)
        phase_changed.emit(phase)
        changed.emit()
        return true
    return false

# A pre-0.8.0 snapshot describes a different game (investigation rooms, one
# stage-wide alibi, abstain votes). It is resumed as a safe fresh start of the
# same Stage: same case, same seed, same difficulty, Day 1 morning. Nothing in
# the archive or the settings is touched. Legacy protocols map through
# normalize_protocol (AUDITOR -> ANALYST or NONE).
func _migrate_legacy_snapshot(cfg: ConfigFile) -> bool:
    var saved_case := str(cfg.get_value("session", "case_id", ""))
    if not AstraCaseCatalog.has_case(saved_case):
        return false
    var saved_seed := int(cfg.get_value("session", "seed_value", 1))
    var saved_protocol := str(cfg.get_value("session", "protocol", "NONE"))
    var saved_difficulty := str(cfg.get_value("session", "difficulty", "STANDARD"))
    var saved_voyage: Variant = cfg.get_value("session", "voyage", {})
    setup(saved_case, saved_seed, saved_protocol, saved_difficulty)
    stage_state()["migrated_from"] = int(cfg.get_value("meta", "version", 1))
    if saved_voyage is Dictionary and not (saved_voyage as Dictionary).is_empty():
        voyage = (saved_voyage as Dictionary).duplicate(true)
        voyage["scene"] = {}
        _hydrate_054_voyage_defaults()
    _log("이전 버전 저장을 이 Stage의 첫날 아침으로 옮겼다.")
    phase_changed.emit(phase)
    changed.emit()
    return true

func _valid_snapshot(cfg: ConfigFile) -> bool:
    for field in SNAPSHOT_FIELDS:
        if not cfg.has_section_key("session", field):
            if field in FIELDS_ADDED_IN_040 or field == "voyage":
                continue
            return false
        if typeof(cfg.get_value("session", field)) != typeof(get(field)):
            return false
    var saved_case := str(cfg.get_value("session", "case_id"))
    var saved_phase := str(cfg.get_value("session", "phase"))
    if not AstraCaseCatalog.has_case(saved_case) or saved_phase not in PHASES or saved_phase == "RESULT":
        return false
    if int(cfg.get_value("session", "day")) not in range(1, MAX_DAYS + 1):
        return false
    if not cfg.has_section_key("session", "rng_state") or typeof(cfg.get_value("session", "rng_state")) != TYPE_INT:
        return false
    var saved_flags: Dictionary = cfg.get_value("session", "flags")
    if not saved_flags.get("stage_080", null) is Dictionary:
        return false
    var saved_truth: Dictionary = cfg.get_value("session", "truth")
    if not saved_truth.get("nulls", null) is Array:
        return false
    var saved_roster: Array = cfg.get_value("session", "roster", [])
    if saved_roster.is_empty():
        saved_roster = AstraCaseCatalog.roster(AstraCaseCatalog.get_case(saved_case))
    for npc_id in saved_roster:
        var member := AstraCrewMember.new(npc_id)
        for field in CREW_SNAPSHOT_FIELDS:
            if not cfg.has_section_key("crew_" + npc_id, field) or typeof(cfg.get_value("crew_" + npc_id, field)) != typeof(member.get(field)):
                return false
    return true

# ---------------------------------------------------------------- lookups

func npc_knows_fact(npc_id: String, fact_id: String) -> bool:
    return AstraKnowledgeModel.knows(flags, npc_id, fact_id)

func player_knows(fact_id: String) -> bool:
    return AstraKnowledgeModel.knows(flags, "player", fact_id)

func knowledge_debug_trace(npc_id: String, fact_id: String) -> String:
    return AstraKnowledgeModel.trace_text(flags, npc_id, fact_id)

func decision_trace_for(npc_id: String) -> Array:
    return AstraDecisionModel.recent(flags, npc_id)

func npc(npc_id: String) -> AstraCrewMember:
    return crew.get(npc_id, null)

func name_of(npc_id: String) -> String:
    if npc_id == "player":
        return "탐사요원"
    return AstraCrewCatalog.display_name(npc_id)

func names_of(ids: Array) -> String:
    var names: Array = []
    for npc_id in ids:
        names.append(name_of(str(npc_id)))
    return ", ".join(PackedStringArray(names))

func room_name(room_id: String) -> String:
    var packet := current_packet()
    var locations: Dictionary = packet.get("locations", {})
    if locations.has(room_id):
        return str(locations[room_id])
    var name := AstraCaseCatalog.room_name(case_data, room_id)
    return name if name != room_id else AstraStageStory.location_name(room_id)

func phase_label(phase_id: String = "") -> String:
    return str(PHASE_LABELS.get(phase_id if phase_id != "" else phase, phase))

func is_alive(npc_id: String) -> bool:
    if npc_id == "player":
        return player_alive()
    var member := npc(npc_id)
    return member != null and member.is_alive()

func living_ids() -> Array:
    return active_participants()

# "roster" is the awakened roster for this Stage; an active participant is in
# it and still ACTIVE. Everything that can speak, vote or be targeted builds on
# this one definition.
func active_participants() -> Array:
    var result: Array = []
    for npc_id in roster:
        if crew.has(npc_id) and crew[npc_id].status == AstraCrewMember.STATUS_ACTIVE:
            result.append(npc_id)
    return result

func eligible_voters() -> Array:
    return active_participants()

func eligible_vote_targets() -> Array:
    var runoff: Array = stage_state().get("runoff", [])
    if str(stage_state().get("vote_stage", "BALLOT")) in ["RUNOFF", "TIEBREAK"] and not runoff.is_empty():
        var result: Array = []
        for id in runoff:
            if str(id) in active_participants():
                result.append(str(id))
        return result
    return active_participants()

func can_vote_for(voter_id: String, target_id: String) -> bool:
    if voter_id == "" or target_id == "" or voter_id == target_id:
        return false
    if voter_id == "player":
        return player_alive() and target_id in eligible_vote_targets()
    return voter_id in eligible_voters() and target_id in eligible_vote_targets()

func _fallback_selected() -> void:
    if selected_id in active_participants():
        return
    var valid := active_participants()
    selected_id = str(valid[0]) if not valid.is_empty() else ""

func living_null_ids() -> Array:
    var result: Array = []
    for npc_id in living_ids():
        if crew[npc_id].is_null():
            result.append(npc_id)
    return result

func living_crew_ids() -> Array:
    var result: Array = []
    for npc_id in living_ids():
        if not crew[npc_id].is_null():
            result.append(npc_id)
    return result

# Crew-side voting bodies: every active innocent plus the explorer while alive.
func crew_side_votes() -> int:
    return living_crew_ids().size() + (1 if player_alive() else 0)

func has_feature(feature: String) -> bool:
    return features.is_empty() or feature in features

func set_mark(npc_id: String, mark: String) -> void:
    if not crew.has(npc_id):
        return
    if mark in ["null", "clear", "unsure"]:
        marks[npc_id] = mark
    else:
        marks.erase(npc_id)
    changed.emit()

func cycle_mark(npc_id: String) -> String:
    var current := str(marks.get(npc_id, ""))
    var next := ""
    match current:
        "": next = "null"
        "null": next = "clear"
        "clear": next = "unsure"
        _: next = ""
    set_mark(npc_id, next)
    return next

func marked_suspects() -> Array:
    var result: Array = []
    for npc_id in roster:
        if str(marks.get(npc_id, "")) == "null":
            result.append(npc_id)
    return result

func select(npc_id: String) -> void:
    if npc_id in active_participants():
        selected_id = npc_id
        changed.emit()
    else:
        _fallback_selected()

# ---------------------------------------------------------------- day packets

func current_packet() -> Dictionary:
    return packet_for(day)

func packet_for(day_index: int) -> Dictionary:
    return Dictionary(stage_state().get("packets", {}).get(str(day_index), {}))

func incident() -> Dictionary:
    return Dictionary(current_packet().get("incident", {}))

func incident_time() -> String:
    return str(current_packet().get("time", ""))

# How much the room is already looking at each person, from public acts only:
# meeting accusations and yesterday's ballots. A Null reads this to pick a
# scapegoat; it never reads hidden truth.
func _public_heat() -> Dictionary:
    var heat := {}
    for entry in stage_state().get("public_accusations", []):
        var target := str(entry.get("target", ""))
        heat[target] = float(heat.get(target, 0.0)) + 0.35
    for round in stage_state().get("vote_rounds", []):
        for voter in Dictionary(round.get("ballots", {})):
            var target := str(round["ballots"][voter])
            heat[target] = float(heat.get(target, 0.0)) + 0.15
    return heat

# How likely each keeper is to have opened their own logs before anyone asks.
const READS_LOGS := {"noa": 0.7, "dax": 0.6, "sena": 0.5, "eli": 0.5, "vale": 0.45, "mira": 0.35, "rho": 0.35, "lyra": 0.35}

func log_unread(fragment_id: String) -> bool:
    return bool(stage_state().get("unread", {}).get(fragment_id, false))

func _mark_read(fragment_id: String) -> void:
    var unread: Dictionary = stage_state().get("unread", {})
    if unread.erase(fragment_id):
        stage_state()["unread"] = unread
        var item := fragment(fragment_id)
        var holder := _current_holder(item)
        if holder != "":
            AstraKnowledgeModel.share_with(flags, fragment_id, holder, day, "opened")

func _install_day_packet(day_index: int) -> void:
    var state := stage_state()
    var packets: Dictionary = state.get("packets", {})
    var packet := AstraCaseGenerator.generate_day_packet(case_id, seed_value, day_index, active_participants(), living_null_ids(), difficulty, _public_heat())
    packets[str(day_index)] = packet
    state["packets"] = packets
    # Every fragment starts known only to the person who holds it. A log is
    # different from a memory: it sits in the system until someone opens it.
    # Whoever keeps it may already have looked (by habit), or may open it when
    # asked; either way, opening it is how it becomes anyone's knowledge (§4).
    var unread: Dictionary = state.get("unread", {})
    for fragment in packet.get("fragments", []):
        var fid := str(fragment.get("id", ""))
        var owner := str(fragment.get("owner", ""))
        if str(fragment.get("type", "")) in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
            var habit := float(READS_LOGS.get(owner, 0.4)) * (0.75 if day_index == 1 else 1.0) * (0.4 if deep_modifier() == "BLACKOUT" else 1.0)
            if _stable_noise("read:" + fid) >= habit:
                unread[fid] = true
                continue
        AstraKnowledgeModel.share_with(flags, fid, owner, day_index, "own_observation")
    state["unread"] = unread
    for fragment in packet.get("fragments", []):
        if str(fragment.get("type", "")) == "HEARSAY":
            AstraKnowledgeModel.share_with(flags, str(fragment.get("id", "")), str(fragment.get("via", "")), day_index, "own_observation")
    known_claims.clear()
    public_claims.clear()
    accused_today.clear()
    meeting_feed.clear()
    _fallback_selected()
    _recompute_contradictions()

# Condition B across nights: a record whose keeper is gone is recovered by the
# backup keeper the next morning, if that person is still here.
func _recover_orphan_records() -> Array:
    var notes: Array = []
    var packet := packet_for(day - 1)
    for fragment in packet.get("fragments", []):
        if str(fragment.get("type", "")) != "SYSTEM_RECORD":
            continue
        var id := str(fragment.get("id", ""))
        var owner := str(fragment.get("owner", ""))
        if is_alive(owner) or AstraKnowledgeModel.is_public(flags, id) or bool(stage_state().get("destroyed", {}).get(id, false)):
            continue
        var backup := str(fragment.get("backup", ""))
        if backup == "" or not is_alive(backup):
            for candidate in living_crew_ids():
                if str(AstraCrewCatalog.RECORD_BACKUP.get(str(fragment.get("record_type", "")), "")) == str(candidate):
                    backup = str(candidate)
        if backup == "" or not is_alive(backup):
            continue
        AstraKnowledgeModel.share_between(flags, id, owner, backup, day, "backup_recovery")
        if not AstraKnowledgeModel.knows(flags, backup, id):
            AstraKnowledgeModel.share_with(flags, id, backup, day, "backup_recovery")
        stage_state()["recovered"].append({"id": id, "by": backup, "day": day})
        notes.append({"id": id, "by": backup, "from": owner})
    return notes

func _fragment_day(id: String) -> int:
    for packet_key in stage_state().get("packets", {}):
        for item in stage_state()["packets"][packet_key].get("fragments", []):
            if str(item.get("id", "")) == id:
                return int(stage_state()["packets"][packet_key].get("day", 0))
    return 0

func fragment(id: String) -> Dictionary:
    for packet_key in stage_state().get("packets", {}):
        for item in stage_state()["packets"][packet_key].get("fragments", []):
            if str(item.get("id", "")) == id:
                return item
    return {}

# Today's claim by `npc_id` about today's incident. A confession or a partial
# admission replaces what they now stand by.
func current_claim(npc_id: String) -> Dictionary:
    var claims: Dictionary = current_packet().get("claims", {})
    var claim: Dictionary = Dictionary(claims.get(npc_id, {})).duplicate(true)
    var confessed: Dictionary = stage_state().get("confessions", {}).get(npc_id, {})
    if not confessed.is_empty() and int(confessed.get("day", 0)) == day:
        claim["position"] = str(confessed.get("position", claim.get("position", "")))
        claim["companions"] = []
        claim["lie"] = false
    var admitted: Dictionary = stage_state().get("admissions", {}).get(npc_id, {})
    if not admitted.is_empty() and int(admitted.get("day", 0)) == day:
        claim["position"] = str(admitted.get("position", claim.get("position", "")))
    return claim

func true_position(npc_id: String) -> String:
    return str(current_packet().get("positions", {}).get(npc_id, ""))

# ---------------------------------------------------------------- phase flow

func can_advance() -> bool:
    if outcome != "" and phase != "RESULT":
        return true
    match phase:
        "BRIEFING":
            return story_finished()
        "INTERROGATION", "MEETING":
            return true
        "VOTE":
            return vote_cast
        "NIGHT":
            return night_done
    return false

func advance_label() -> String:
    if outcome != "" and phase != "RESULT":
        return "결과 보기"
    match phase:
        "BRIEFING":
            return "대화 시작" if story_finished() else "장면을 끝까지 보세요"
        "INTERROGATION":
            return "회의 열기"
        "MEETING":
            return "투표로"
        "VOTE":
            if not vote_cast:
                return "투표할 사람을 먼저 고르세요"
            return "밤 · 보호할 사람 고르기" if night_needs_choice() else "밤을 보낸다"
        "NIGHT":
            return ("DAY %d 아침으로" % (day + 1)) if night_done else "보호할 사람을 고르세요"
    return ""

func advance() -> void:
    if not can_advance():
        return
    if outcome != "" and phase != "RESULT":
        _enter("RESULT")
        return
    match phase:
        "BRIEFING":
            _enter("INTERROGATION")
        "INTERROGATION":
            _enter("MEETING")
        "MEETING":
            _finish_meeting()
            _enter("VOTE")
        "VOTE":
            if night_needs_choice():
                _enter("NIGHT")
            else:
                # No night menu in Part I: the night resolves on its own and
                # its report opens the next morning.
                phase = "NIGHT"
                night_done = false
                night_plan.clear()
                night_result.clear()
                _resolve_night()
                night_done = true
                notice.emit("night", night_result)
                if outcome != "":
                    _enter("RESULT")
                else:
                    _start_next_day()
        "NIGHT":
            if outcome != "":
                _enter("RESULT")
            else:
                _start_next_day()

func _enter(next_phase: String) -> void:
    phase = next_phase
    match phase:
        "INTERROGATION":
            talk_ap = conversations_left()
        "MEETING":
            meeting_actions_left = interventions_max()
            accused_today.clear()
            _open_meeting()
        "VOTE":
            vote_cast = false
            last_vote.clear()
            stage_state()["vote_stage"] = "BALLOT"
            stage_state()["runoff"] = []
            flags.erase("ballot_choice")
        "NIGHT":
            night_done = false
            night_plan.clear()
            night_result.clear()
        "RESULT":
            _finalize()
            _queue_result_story()
    _log("— DAY %d · %s —" % [day, phase_label()])
    phase_changed.emit(phase)
    changed.emit()

func _start_next_day() -> void:
    if day >= MAX_DAYS:
        # Safety net only. Every Day isolates exactly one person, so a Stage
        # always ends long before this; reaching it is a rules bug.
        push_error("ASTRA invariant: Stage exceeded MAX_DAYS")
        outcome = "LOSE"
        stage_state()["outcome_reason"] = "null_control"
        _enter("RESULT")
        return
    day += 1
    _apply_next_day_consequences()
    for npc_id in living_ids():
        crew[npc_id].adjust_stress(0.04)
        crew[npc_id].refresh_expression()
    var recovered := _recover_orphan_records()
    _install_day_packet(day)
    vote_cast = false
    night_done = false
    last_vote.clear()
    stage_state()["vote_stage"] = "BALLOT"
    stage_state()["runoff"] = []
    phase = "BRIEFING"
    _queue_morning(day, recovered)
    _log("— DAY %d · %s —" % [day, phase_label()])
    phase_changed.emit(phase)
    changed.emit()

# Legacy entry points that 0.7.x UI and tests still call.
func tutorial_active() -> bool:
    return false

func set_tutorial(enabled: bool) -> void:
    flags["tutorial"] = enabled

func tutorial_blocked_reason() -> String:
    return ""

# ================================================================ conversation
#
# One conversation = one person's account of today's incident plus up to two
# follow-ups. A Day has 2 (Part I opening Stages) or 3 conversations, so the
# explorer never hears everyone and choosing whom to hear is the play.
# Follow-ups are contextual: at most three are offered, chosen from what the
# explorer actually knows (a claim that contradicts this person, a record they
# can open, a sighting to ask about, yesterday's words).

const STATEMENT_QUESTION := "{time}, 어디에 있었는지 말해 줄래요?"
# How readily each person volunteers what they saw or hold, before being asked.
const VOLUNTEER := {"sena":0.8, "rho":0.75, "lyra":0.7, "mira":0.6, "dax":0.55, "eli":0.5, "noa":0.5, "vale":0.35}
# How readily each person puts a record or sighting on the table in a meeting.
# What a keeper says in the meeting unasked, relative to their temperament.
# Once the explorer has heard it from them, they stand behind it (0.9+): what
# reaches the room depends on who the explorer talked to (1.0).
const UNASKED_SHARE := 0.13
const MEETING_SHARE := {"noa":0.85, "dax":0.8, "sena":0.85, "rho":0.72, "vale":0.55, "eli":0.65, "mira":0.65, "lyra":0.62}

func conversations_max() -> int:
    return AstraCaseCatalog.talk_budget(case_id)

func _day_key() -> String:
    return str(day)

func _conversation_book() -> Dictionary:
    var book: Dictionary = stage_state().get("conversations", {})
    if not book.has(_day_key()):
        book[_day_key()] = {}
        stage_state()["conversations"] = book
    return book[_day_key()]

func conversation_state(npc_id: String) -> Dictionary:
    return Dictionary(_conversation_book().get(npc_id, {}))

func conversation_open(npc_id: String) -> bool:
    return not conversation_state(npc_id).is_empty()

func conversations_used() -> int:
    return _conversation_book().size()

func conversations_left() -> int:
    return maxi(0, conversations_max() - conversations_used())

func followups_left(npc_id: String) -> int:
    return int(conversation_state(npc_id).get("followups", 0))

func record_checks_max() -> int:
    return 2 if case_id in ["SECOND_WATCH", "THREE_MINUTES_DARK"] else AstraCaseCatalog.RECORD_CHECKS_PER_DAY

func record_checks_left() -> int:
    return maxi(0, record_checks_max() - int(stage_state().get("record_checks", {}).get(_day_key(), 0)))

func _asked(npc_id: String) -> Array:
    var asked: Dictionary = stage_state().get("asked", {})
    var today: Dictionary = asked.get(_day_key(), {})
    return Array(today.get(npc_id, []))

func _mark_asked(npc_id: String, key: String) -> void:
    var asked: Dictionary = stage_state().get("asked", {})
    var today: Dictionary = asked.get(_day_key(), {})
    var list: Array = today.get(npc_id, [])
    if key not in list:
        list.append(key)
    today[npc_id] = list
    asked[_day_key()] = today
    stage_state()["asked"] = asked

func empath_available() -> bool:
    return protocol == "EMPATH" and int(stage_state().get("empath_uses", {}).get(_day_key(), 0)) == 0 and outcome == ""

func analyst_available() -> bool:
    return protocol == "ANALYST" and int(stage_state().get("analyst_uses", {}).get(_day_key(), 0)) == 0 and outcome == "" and phase in ["INTERROGATION", "MEETING"]

func _use_daily(key: String) -> void:
    var book: Dictionary = stage_state().get(key, {})
    book[_day_key()] = int(book.get(_day_key(), 0)) + 1
    stage_state()[key] = book

# ---------------------------------------------------------------- what the explorer knows

# Fragments the explorer has actually heard or seen, oldest first.
func known_fragments(day_filter: int = -1) -> Array:
    var result: Array = []
    for key in stage_state().get("packets", {}):
        if day_filter > 0 and int(key) != day_filter:
            continue
        for item in stage_state()["packets"][key].get("fragments", []):
            if player_knows(str(item.get("id", ""))):
                result.append(item)
    return result

func _owned_undisclosed(npc_id: String) -> Array:
    var result: Array = []
    for item in current_packet().get("fragments", []):
        if str(item.get("owner", "")) == npc_id and not player_knows(str(item.get("id", ""))) and not bool(stage_state().get("destroyed", {}).get(str(item.get("id", "")), false)):
            result.append(item)
    for note in stage_state().get("recovered", []):
        if str(note.get("by", "")) == npc_id:
            var recovered := fragment(str(note.get("id", "")))
            if not recovered.is_empty() and not player_knows(str(recovered.get("id", ""))):
                result.append(recovered)
    return result

# The role this person plays in today's incident, for the rules only. Never
# shown, never used by innocent AI.
func _day_role(npc_id: String) -> String:
    var packet := current_packet()
    if str(packet.get("actor", "")) == npc_id:
        return "actor"
    if str(packet.get("cover", "")) == npc_id and str(packet.get("cover_style", "")) == "mutual":
        return "cover"
    if npc(npc_id) != null and npc(npc_id).is_null():
        return "idle_null"
    if str(packet.get("benign", {}).get("npc", "")) == npc_id:
        return "benign"
    if str(packet.get("scapegoat", "")) == npc_id:
        return "scapegoat"
    return "honest"

func _disclose(item: Dictionary, member: AstraCrewMember, result: Dictionary, how: String = "told") -> void:
    var id := str(item.get("id", ""))
    if id == "" or player_knows(id):
        return
    AstraKnowledgeModel.share_with(flags, id, "player", day, member.id if member != null else how)
    _mark_read(id)
    var type := str(item.get("type", ""))
    var speaker := member.id if member != null else ""
    var line := ""
    var params := _fragment_params(item)
    match type:
        "DIRECT_WITNESS", "NULL_DECEPTION":
            line = AstraSocialLines.line(speaker, "saw_specific" if bool(item.get("specific", false)) else "saw_group", params, _pick(speaker + id))
        "HEARSAY":
            line = AstraSocialLines.line(speaker, "heard", params, _pick(speaker + id))
        "SYSTEM_RECORD", "ALIBI_SUPPORT":
            var own_domain := str(AstraCrewCatalog.RECORD_DOMAIN.get(speaker, "")) == str(item.get("record_type", ""))
            line = AstraSocialLines.line(speaker, "record_open" if own_domain else "record_open_other", params, _pick(speaker + id))
        "BENIGN_EXPOSURE", "COVER_EXPOSURE", "ROUTINE":
            line = AstraSocialLines.line(speaker, "saw_at", params, _pick(speaker + id))
        "EXPERT_INFERENCE":
            line = AstraSocialLines.line(speaker, "inference", params, _pick(speaker + id))
    if line != "" and member != null:
        _say_text(member, line, result, "fragment")
    if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
        _narrate_text(member, "기록 · " + str(item.get("text", "")), result)
    result["fragment"] = item.duplicate(true)
    notice.emit("fragment", {"fragment": item.duplicate(true), "from": speaker})

# A witness who fits their own description counts themselves in:
# "해당하는 건 저와 준이에요", never their own name in the third person.
func _witness_params(item: Dictionary, speaker: String) -> Dictionary:
    var params := _fragment_params(item)
    var members: Array = Dictionary(item.get("group", {})).get("members", [])
    if speaker in members:
        var names: Array = []
        for id in members:
            names.append(("나" if speaker in BANMAL_SPEAKERS else "저") if str(id) == speaker else name_of(str(id)))
        params["members"] = AstraJosa.join_names(names)
    return params

func _fragment_params(item: Dictionary) -> Dictionary:
    var subject := str(item.get("subject", ""))
    var group: Dictionary = item.get("group", {})
    return {
        "time": str(item.get("time", "")),
        "room": room_name(str(item.get("room", ""))),
        "pos": room_name(str(item.get("room", ""))),
        "target": name_of(subject) if subject != "" else "",
        "phrase": AstraCaseGenerator.witness_phrase(str(group.get("category", "")), str(group.get("group", ""))) if not group.is_empty() else "",
        "members": names_of(Array(group.get("members", []))),
        "device": str(item.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(item.get("record_type", "")), "기록"))),
        "via": name_of(str(item.get("via", ""))),
        "fact": str(item.get("text", "")),
        "record": str(item.get("text", ""))
    }

# ---------------------------------------------------------------- options

func question_options(npc_id: String) -> Array:
    var member := npc(npc_id)
    if member == null or not member.is_alive() or phase != "INTERROGATION" or outcome != "":
        return []
    if not conversation_open(npc_id):
        return [{"intent": "STATEMENT", "label": AstraExplorerCatalog.question(str(player_profile()["explorer_id"]), "STATEMENT", "이야기를 듣는다").replace("{time}", incident_time()), "hint": "%s에 어디 있었는지, 무엇을 봤는지 듣습니다. 대화 1회를 씁니다." % incident_time(),
            "enabled": conversations_left() > 0, "key": true}]
    var enabled := followups_left(npc_id) > 0
    var asked := _asked(npc_id)
    var candidates: Array = []
    for conflict in conflicts_player_can_raise(npc_id):
        if ("confront:" + str(conflict["ref"])) in asked:
            continue
        candidates.append({"intent": "CONFRONT", "ref": str(conflict["ref"]), "label": str(conflict["label"]),
            "hint": str(conflict["hint"]), "enabled": enabled, "key": true, "_p": 100.0 + float(conflict["strength"]) * 10.0})
    var record := _checkable_record(npc_id)
    if not record.is_empty() and "record" not in asked:
        candidates.append({"intent": "RECORD", "ref": str(record.get("id", "")),
            "label": _josa_inline("%s|eul 같이 열어 본다" % str(record.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(record.get("record_type", "")), "기록")))),
            "hint": "이 사람이 가진 기록을 바로 열어 봅니다. 하루 %d회." % record_checks_max(),
            "enabled": enabled and record_checks_left() > 0, "key": true, "_p": 90.0})
    if "seen" not in asked:
        candidates.append({"intent": "WITNESS", "label": "그 시간에 누구를 봤어요?", "hint": "목격한 사람이나 들은 말을 묻습니다.", "enabled": enabled, "_p": 60.0})
    if day > 1 and "yesterday" not in asked and not _yesterday_claim(npc_id).is_empty():
        candidates.append({"intent": "YESTERDAY", "label": "어제 한 말을 다시 확인한다", "hint": "어제의 진술을 다시 말하게 합니다. 말이 달라지면 기록에 남습니다.", "enabled": enabled, "_p": 55.0})
    if "opinion" not in asked:
        candidates.append({"intent": "SUSPECT", "label": "누가 가장 마음에 걸려요?", "hint": "이 사람의 판단과 이유를 듣습니다.", "enabled": enabled, "_p": 40.0})
    if "reassure" not in asked and (member.stress >= 0.45 or bool(conversation_state(npc_id).get("deflected", false))):
        candidates.append({"intent": "REASSURE", "label": "몰아세우려는 게 아니에요. 천천히 말해요.", "hint": "긴장을 낮추고 신뢰를 얻습니다. 숨긴 사정을 꺼낼 여지가 생깁니다.", "enabled": enabled, "_p": 70.0 if bool(conversation_state(npc_id).get("deflected", false)) else 35.0})
    if "pressure" not in asked and conversation_state(npc_id).get("confronted", false):
        candidates.append({"intent": "PRESSURE", "label": "지금 말하지 않으면 회의에서 말할 거예요.", "hint": "압박합니다. 무너지거나, 화를 내거나, 입을 닫을 수 있습니다.", "enabled": enabled, "_p": 50.0})
    candidates.sort_custom(func(a, b): return float(a["_p"]) > float(b["_p"]))
    # The same fact can be put two ways (§19): asked calmly, or used as a
    # threat. Calm keeps trust and lets an honest secret come out; pressure
    # shakes a liar faster but makes everyone guard themselves.
    if not candidates.is_empty() and str(candidates[0]["intent"]) == "CONFRONT":
        var top: Dictionary = candidates[0]
        var pressed := top.duplicate()
        pressed["ref"] = str(top["ref"]) + "|press"
        pressed["label"] = "몰아붙인다 · “이거, 회의에서 그대로 말할까요?”"
        pressed["hint"] = "같은 근거로 압박합니다. 거짓말하는 사람은 빨리 흔들리지만, 정직한 사람도 마음을 닫습니다."
        pressed["tone"] = "press"
        pressed["_p"] = float(top["_p"]) - 0.5
        top["tone"] = "calm"
        top["label"] = "차분히 묻는다 · " + str(top["label"])
        candidates.insert(1, pressed)
        candidates = candidates.filter(func(c): return str(c["intent"]) != "PRESSURE")
    var options: Array = candidates.slice(0, 3)
    if empath_available():
        options.append({"intent": "EMPATHY", "label": "표정을 읽는다 · 엠패스", "hint": "추가 질문 1회. 감정 반응과 방어 태도, 관계를 읽습니다. 거짓말 판정은 아닙니다.", "enabled": true, "_p": 0.0})
    for option in options:
        option.erase("_p")
        option["label"] = AstraExplorerCatalog.question(str(player_profile()["explorer_id"]), str(option["intent"]), str(option["label"])).replace("{time}", incident_time())
    return options

func _checkable_record(npc_id: String) -> Dictionary:
    for item in _owned_undisclosed(npc_id):
        if str(item.get("type", "")) in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
            return item
    return {}

# Everything the explorer can put in front of this person that does not fit
# what they said: a sighting, a record, another person's claim, their own
# earlier words. Built only from the explorer's own knowledge.
func conflicts_player_can_raise(npc_id: String) -> Array:
    var result: Array = []
    var claim: Dictionary = known_claims.get(npc_id, {})
    for item in known_fragments(day):
        var owner := str(item.get("owner", ""))
        if owner == npc_id:
            continue
        var type := str(item.get("type", ""))
        var points: Array = item.get("points_to", [])
        var hits := str(item.get("refutes", "")) == npc_id or (npc_id in points and type in ["DIRECT_WITNESS", "SYSTEM_RECORD", "HEARSAY", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"])
        if type == "EXPERT_INFERENCE":
            hits = str(item.get("refutes", "")) == npc_id and _used_excuse(npc_id)
        if type == "ALIBI_SUPPORT":
            hits = str(item.get("refutes", "")) == npc_id
        if not hits:
            continue
        if claim.is_empty() and type != "EXPERT_INFERENCE":
            continue
        result.append({"ref": str(item.get("id", "")), "strength": float(item.get("strength", 0.3)),
            "label": _confront_label(item, npc_id), "hint": str(item.get("text", ""))})
    if not claim.is_empty():
        for other in known_claims:
            if str(other) == npc_id:
                continue
            var kind := _claim_conflict_kind(npc_id, str(other))
            if kind == "":
                continue
            var other_claim: Dictionary = known_claims[other]
            var label := ""
            match kind:
                "they_vouch":
                    label = "%s|eun 같이 있었다던데요" % name_of(str(other))
                "you_vouch":
                    label = "%s|eun 다른 곳에 있었다던데요" % name_of(str(other))
                "one_sided":
                    if str(other) in Array(claim.get("companions", [])):
                        label = "%s|eun 혼자 있었다던데요" % name_of(str(other))
                    else:
                        label = "%s|eun 당신이랑 같이 있었다던데요" % name_of(str(other))
                _:
                    label = "%s도 %s에 있었다는데, 못 봤어요?" % [name_of(str(other)), room_name(str(other_claim.get("position", "")))]
            result.append({"ref": "claim:" + str(other), "strength": 0.34 if kind != "place" else 0.26,
                "label": _josa_inline(label), "hint": "%s의 진술: %s" % [name_of(str(other)), room_name(str(other_claim.get("position", "")))]})
    for conflict in AstraClaimLedger.self_conflicts(claim_ledger, npc_id):
        var a: Dictionary = conflict.get("a", {})
        var b: Dictionary = conflict.get("b", {})
        if str(a.get("speaker", "")) != npc_id:
            continue
        result.append({"ref": "self", "strength": 0.45, "label": "방금 한 말이 전에 한 말과 달라요",
            "hint": "DAY %d “%s” / “%s”" % [int(a.get("day", 1)), str(a.get("text", "")), str(b.get("text", ""))]})
        break
    result.sort_custom(func(x, y): return float(x["strength"]) > float(y["strength"]))
    return result.slice(0, 3)

func _confront_label(item: Dictionary, _npc_id: String) -> String:
    var owner := name_of(str(item.get("owner", "")))
    match str(item.get("type", "")):
        "SYSTEM_RECORD":
            return _josa_inline("%s|eul 보여 준다" % str(item.get("device", "기록")))
        "ALIBI_SUPPORT":
            return _josa_inline("기록상 %s|eun 다른 곳에 있었다고 말한다" % name_of(str(item.get("subject", ""))))
        "EXPERT_INFERENCE":
            return _josa_inline("%s|i 그 설명은 성립하지 않는대요" % owner)
        "HEARSAY":
            return _josa_inline("%s|i 전해 들은 말을 꺼낸다" % owner)
    return _josa_inline("%s의 증언을 제시한다" % owner)

func _claim_conflict_kind(a: String, b: String) -> String:
    if not known_claims.has(a) or not known_claims.has(b):
        return ""
    var ca: Dictionary = known_claims[a]
    var cb: Dictionary = known_claims[b]
    var same := str(ca.get("position", "")) == str(cb.get("position", ""))
    var a_mates: Array = ca.get("companions", [])
    var b_mates: Array = cb.get("companions", [])
    if a in b_mates and not same:
        return "they_vouch"
    if b in a_mates and not same:
        return "you_vouch"
    if same and a not in b_mates and b not in a_mates:
        return "place"
    # One of them says they were together, the other says they were alone.
    if same and ((b in a_mates) != (a in b_mates)):
        return "one_sided"
    return ""

func _used_excuse(npc_id: String) -> bool:
    return bool(stage_state().get("excuses", {}).get(_day_key(), {}).get(npc_id, false))

func _yesterday_claim(npc_id: String) -> Dictionary:
    for index in range(claim_ledger.size() - 1, -1, -1):
        var entry: Dictionary = claim_ledger[index]
        if str(entry.get("speaker", "")) == npc_id and str(entry.get("kind", "")) == AstraClaimLedger.KIND_POSITION and int(entry.get("about_day", entry.get("day", 1))) == day - 1 and not bool(entry.get("retracted", false)):
            return entry
    return {}

# ---------------------------------------------------------------- ask

func open_conversation(npc_id: String) -> Dictionary:
    return ask(npc_id, "STATEMENT")

func ask(npc_id: String, intent: String, ref: String = "") -> Dictionary:
    var member := npc(npc_id)
    if member == null or not member.is_alive() or phase != "INTERROGATION" or outcome != "":
        return {"ok": false}
    var mapped := _legacy_intent(npc_id, intent, ref)
    intent = str(mapped["intent"])
    ref = str(mapped["ref"])
    var result := {"ok": true, "npc_id": npc_id, "intent": intent, "response_family": intent, "lines": []}
    var book := _conversation_book()
    if not book.has(npc_id):
        if conversations_left() <= 0:
            return {"ok": false, "reason": "no_conversations"}
        book[npc_id] = {"followups": AstraCaseCatalog.FOLLOWUPS_PER_CONVERSATION}
        talk_ap = conversations_left()
        stats["conversations"] = int(stats.get("conversations", 0)) + 1
        _statement(member, result)
        if intent == "STATEMENT":
            _finish_ask(member, result)
            return result
    elif intent == "STATEMENT":
        return {"ok": false, "reason": "already_open"}
    var state: Dictionary = book[npc_id]
    if intent == "EMPATHY":
        if not empath_available():
            return {"ok": false, "reason": "empath_used"}
        _use_daily("empath_uses")
    else:
        if int(state.get("followups", 0)) <= 0:
            return {"ok": false, "reason": "no_followups"}
        state["followups"] = int(state.get("followups", 0)) - 1
    member.questions_asked += 1
    selected_id = npc_id
    match intent:
        "WITNESS": _ask_seen(member, result)
        "RECORD": _ask_record(member, ref, result)
        "CONFRONT": _cross_examine(member, ref, result)
        "YESTERDAY": _ask_yesterday(member, result)
        "SUSPECT": _ask_opinion(member, result)
        "REASSURE": _ask_reassure(member, result)
        "PRESSURE": _ask_pressure(member, result)
        "EMPATHY": _ask_empathy(member, result)
        _:
            _ask_seen(member, result)
    _finish_ask(member, result)
    return result

func _finish_ask(member: AstraCrewMember, result: Dictionary) -> void:
    _record_player_contact(member.id, str(result.get("intent", "")), str(result.get("fragment", {}).get("id", "")))
    talk_ap = conversations_left()
    member.refresh_expression()
    member.remember("DAY %d · 탐사요원과 대화 %s" % [day, str(result.get("intent", ""))])
    _recompute_contradictions()
    var reaction := _dialogue_reaction(member, str(result.get("intent", "")), result)
    if not reaction.is_empty():
        result["reaction"] = reaction
        _transcript(member.id, "narration", str(reaction.get("text", "")), "reaction")
        var mood := {"SHAKEN": "shocked", "RESISTED": "annoyed", "ANGERED": "angry", "CONVINCED": "sad", "UNCERTAIN": "suspicious"}
        member.expression = str(mood.get(str(reaction.get("code", "")), member.expression))
    changed.emit()

# Pre-0.8.0 intent names from old tests, bots and saves.
func _legacy_intent(npc_id: String, intent: String, ref: String) -> Dictionary:
    match intent:
        "ALIBI":
            return {"intent": "STATEMENT" if not conversation_open(npc_id) else "YESTERDAY", "ref": ""}
        "TIMELINE":
            return {"intent": "YESTERDAY" if day > 1 else "WITNESS", "ref": ""}
        "CONTRADICTION", "EVIDENCE":
            var conflicts := conflicts_player_can_raise(npc_id)
            var chosen := ref
            if chosen == "" or fragment(chosen).is_empty():
                chosen = str(conflicts[0]["ref"]) if not conflicts.is_empty() else ""
            return {"intent": "CONFRONT" if chosen != "" else "WITNESS", "ref": chosen}
        "TRUST", "PERSONAL":
            return {"intent": "REASSURE", "ref": ""}
        "CONFIDE":
            return {"intent": "SUSPECT", "ref": ""}
    return {"intent": intent, "ref": ref}

func _statement(member: AstraCrewMember, result: Dictionary) -> void:
    var claim := current_claim(member.id)
    var mates: Array = claim.get("companions", [])
    var params := {"time": incident_time(), "pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates)),
        "room": room_name(str(incident().get("room", "")))}
    # Who the explorer is shows first: their own opening on the first talk of
    # a Stage, and with some people a short exchange that sets the starting
    # tone between the two (AstraExplorerCatalog.FIRST_CONTACT, rotating by
    # Stage). Identity never changes case truth, evidence, RNG or action count.
    # The authored tone may apply only the bounded social-trust nudge below;
    # because trust affects social following, that influence is intentionally
    # indirect and documented rather than pretending votes are invariant.
    var identity := str(player_profile()["explorer_id"])
    var introduced: Dictionary = stage_state().get("explorer_introduced", {})
    if day == 1 and not introduced.has(member.id) and identity in AstraExplorerCatalog.ORDER:
        var contact := AstraExplorerCatalog.first_contact(identity, member.id, stage_index())
        if not contact.is_empty():
            _player_line(member, str(contact[1]), result, "explorer_contact")
            _say_text(member, str(contact[2]), result, "explorer_tone")
            # The starting tone is remembered (a small, bounded nudge).
            var tag := str(contact[0])
            if tag != "":
                var tones: Dictionary = stage_state().get("explorer_tones", {})
                tones[member.id] = tag
                stage_state()["explorer_tones"] = tones
                member.adjust_trust(AstraExplorerCatalog.TONE_NUDGE if AstraExplorerCatalog.tone_kind(tag) == "warm" else -AstraExplorerCatalog.TONE_NUDGE * 0.5)
        elif introduced.is_empty():
            _player_line(member, str(AstraExplorerCatalog.data(identity)["opening"]), result, "explorer_opening")
        introduced[member.id] = true
        stage_state()["explorer_introduced"] = introduced
    var opener := _conversation_opener(member)
    if opener == "" and day > 1:
        # The first exchange comes back once, the next day.
        var tones: Dictionary = stage_state().get("explorer_tones", {})
        var recalled: Dictionary = stage_state().get("tone_recalled", {})
        if tones.has(member.id) and not recalled.has(member.id):
            recalled[member.id] = day
            stage_state()["tone_recalled"] = recalled
            opener = str(AstraExplorerCatalog.TONE_CALLBACK.get(member.id, {}).get(AstraExplorerCatalog.tone_kind(str(tones[member.id])), ""))
    if opener != "":
        _say_text(member, opener, result, "opener")
    _player_line(member, STATEMENT_QUESTION.replace("{time}", incident_time()), result, "STATEMENT")
    var line := AstraSocialLines.line(member.id, "open_with" if not mates.is_empty() else "open_alone", params, _pick(member.id + "open"))
    _say_text(member, line, result, "STATEMENT")
    known_claims[member.id] = {"position": str(claim.get("position", "")), "companions": mates.duplicate(), "day": day}
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, line, {
        "position": str(claim.get("position", "")), "companions": mates, "about_day": day})
    _record_claim(member.id, AstraClaimLedger.KIND_COMPANION if not mates.is_empty() else AstraClaimLedger.KIND_ALONE,
        AstraClaimLedger.SCOPE_PRIVATE, line, {"position": str(claim.get("position", "")), "companions": mates, "about_day": day})
    AstraKnowledgeModel.share_with(flags, "claim:D%d:%s" % [day, member.id], "player", day, member.id)
    _log("진술 · %s — %s%s" % [member.display_name, room_name(str(claim.get("position", ""))), (" / 동행 " + names_of(mates)) if not mates.is_empty() else " / 혼자"])
    # What they bring up without being asked, by temperament. A Null always
    # wants its own "sighting" heard.
    var owned := _owned_undisclosed(member.id)
    var volunteered := false
    for item in owned:
        var type := str(item.get("type", ""))
        var roll := _pick(member.id + str(item.get("id", "")) + "vol")
        if type == "NULL_DECEPTION" and roll < 0.85:
            _disclose(item, member, result, "volunteered")
            _mark_asked(member.id, "seen")
            volunteered = true
            break
        if type in ["DIRECT_WITNESS", "HEARSAY", "BENIGN_EXPOSURE", "COVER_EXPOSURE"] and roll < float(VOLUNTEER.get(member.id, 0.5)):
            _disclose(item, member, result, "volunteered")
            _mark_asked(member.id, "seen")
            volunteered = true
            break
    if not volunteered:
        var record := _checkable_record(member.id)
        if not record.is_empty():
            var own_log := str(AstraCrewCatalog.RECORD_DOMAIN.get(member.id, "")) == str(record.get("record_type", ""))
            _say_text(member, AstraSocialLines.line(member.id, "hint_record" if own_log else "hint_record_other", _fragment_params(record), _pick(member.id + "hint")), result, "hint")
        elif _owns_type(member.id, ["DIRECT_WITNESS", "HEARSAY"]):
            _say_text(member, AstraSocialLines.line(member.id, "hint_saw", {}, _pick(member.id + "hintsaw")), result, "hint")
    if bool(claim.get("lie", false)) and _pick(member.id + "tell") < (0.4 if member.is_null() else 0.3):
        _tell(member, result, "tellpick")

# People remember what the explorer did to them yesterday (§22), and now and
# then a small habit shows before the questions start (§10). Once per person
# per Stage for habits, so it never turns into a tic.
func _conversation_opener(member: AstraCrewMember) -> String:
    var shared := _interlude_opener(member)
    if shared != "":
        return shared
    if day > 1:
        var night: Dictionary = stage_state().get("night_log", []).back() if not stage_state().get("night_log", []).is_empty() else {}
        var opened: Dictionary = stage_state().get("shield_openers", {})
        if bool(night.get("protected", false)) and str(night.get("attacked", "")) == member.id and not opened.has(member.id + str(day)):
            opened[member.id + str(day)] = true
            stage_state()["shield_openers"] = opened
            return AstraSocialLines.line(member.id, "open_after_shielded", {}, _pick(member.id + "oas"))
        var accused := false
        var defended := false
        for round in stage_state().get("vote_rounds", []):
            if int(round.get("day", 0)) == day - 1 and str(Dictionary(round.get("ballots", {})).get("player", "")) == member.id:
                accused = true
        for entry in stage_state().get("public_accusations", []):
            if int(entry.get("day", 0)) == day - 1 and str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == member.id:
                accused = true
        for entry in stage_state().get("public_defenses", []):
            if int(entry.get("day", 0)) == day - 1 and str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == member.id:
                defended = true
        if accused:
            return AstraSocialLines.line(member.id, "open_after_accused", {}, _pick(member.id + "oaa"))
        if defended:
            return AstraSocialLines.line(member.id, "open_after_defended", {}, _pick(member.id + "oad"))
    var shown: Dictionary = stage_state().get("habits_shown", {})
    if not shown.has(member.id) and _pick(member.id + "habit") < 0.45:
        shown[member.id] = day
        stage_state()["habits_shown"] = shown
        return AstraSocialLines.line(member.id, "habit", {}, _pick(member.id + "habitline"))
    return ""

# Who plausibly knows something about today's incident, from what anyone on
# board knows: whose job keeps the logs this kind of incident leaves, and who
# understands the equipment. Job knowledge only; never who actually holds a
# fragment. Shown as small tags so the first choice has a reason (§6, §53).
# The one social question of the Day (§6): it ties the conversations, the
# meeting and the vote together, and it grows out of yesterday (§7).
func day_question() -> String:
    var info := incident()
    var where := room_name(str(info.get("room", "")))
    if day > 1:
        var night: Dictionary = stage_state().get("night_log", []).back() if not stage_state().get("night_log", []).is_empty() else {}
        var victim := str(night.get("victim", ""))
        if victim != "" and victim != "player" and not bool(night.get("protected", false)):
            return _josa_inline("%s|eun 왜 노려졌을까? 무엇을 알고 있었을까? 그리고 %s, %s에는 누가 있었나?" % [name_of(victim), incident_time(), where])
        if bool(night.get("protected", false)) or bool(night.get("shield", false)):
            var target := str(night.get("attacked", ""))
            return _josa_inline("누가 %s|eul 노렸을까? %s, %s에는 누가 있었나?" % ["당신" if target == "player" else name_of(target), incident_time(), where])
        var rounds: Array = stage_state().get("vote_rounds", [])
        if not rounds.is_empty() and str(rounds.back().get("isolated", "")) != "":
            return _josa_inline("어제 %s|eul 보낸 판단은 맞았을까? 오늘 %s, %s에는 누가 있었나?" % [name_of(str(rounds.back().get("isolated", ""))), incident_time(), where])
    return "%s, %s. 그 시간 자기 위치를 거짓말하는 사람은 누구일까?" % [incident_time(), where]

const RECORD_SHORT := {"terminal": "단말 기록", "door": "출입 기록", "power": "분배반 기록", "comms": "통신 기록",
    "motion": "동선 센서", "vitals": "생체 기록", "environment": "대기 센서", "system": "감사 로그"}

func talk_leads() -> Dictionary:
    var leads := {}
    var info := incident()
    # Two tags at most, or the tag stops meaning anything: the keeper of the
    # first log this kind of incident leaves, and the person who knows the
    # equipment best.
    for record_type in info.get("records", []):
        var keeper := AstraCrewCatalog.record_owner(str(record_type))
        if keeper != "" and is_alive(keeper):
            leads[keeper] = "%s 담당" % str(RECORD_SHORT.get(str(record_type), "기록"))
            break
    var method := AstraStageStory.method(str(info.get("method", "")))
    for expert in method.get("experts", []):
        if is_alive(str(expert)) and not leads.has(str(expert)):
            leads[str(expert)] = "장비를 잘 앎"
            break
    # After a rewind, the people the explorer remembers hearing from.
    for id in stage_state().get("echo_leads", []):
        if is_alive(str(id)) and not leads.has(str(id)) and leads.size() < 4:
            leads[str(id)] = "지난번에 들은 말"
    return leads

# A small physical tell, at most once per conversation and never the same
# sentence twice in a Day for the same person (§61).
func _tell(member: AstraCrewMember, result: Dictionary, key: String) -> void:
    var book := _conversation_book()
    if not book.has(member.id):
        return
    var state: Dictionary = book[member.id]
    if bool(state.get("tell_shown", false)):
        return
    var shown: Array = state.get("tells", [])
    var text := ""
    for attempt in range(6):
        var candidate := AstraDialogue.tell(true, member.display_name, int(_pick(member.id + key + str(attempt)) * 10.0) + attempt)
        if candidate not in shown:
            text = candidate
            break
    if text == "":
        return
    shown.append(text)
    state["tells"] = shown
    state["tell_shown"] = true
    book[member.id] = state
    _narrate_text(member, text, result)
    result["tell"] = true

func _owns_type(npc_id: String, types: Array) -> bool:
    for item in _owned_undisclosed(npc_id):
        if str(item.get("type", "")) in types:
            return true
    return false

func _ask_seen(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "seen")
    _player_line(member, "그 시간쯤 누구를 봤어요? 지나가는 사람이라도요.", result, "WITNESS")
    for item in _owned_undisclosed(member.id):
        if str(item.get("type", "")) in ["DIRECT_WITNESS", "HEARSAY", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
            _disclose(item, member, result, "asked")
            return
    for item in _owned_undisclosed(member.id):
        if str(item.get("type", "")) == "ROUTINE":
            _disclose(item, member, result, "asked")
            return
    for item in _owned_undisclosed(member.id):
        if str(item.get("type", "")) == "EXPERT_INFERENCE":
            _say_text(member, AstraSocialLines.line(member.id, "saw_none", {}, _pick(member.id + "none")), result, "WITNESS")
            _disclose(item, member, result, "asked")
            return
    _say_text(member, AstraSocialLines.line(member.id, "saw_none", {}, _pick(member.id + "none")), result, "WITNESS")

func _ask_record(member: AstraCrewMember, ref: String, result: Dictionary) -> void:
    _mark_asked(member.id, "record")
    var item := fragment(ref) if ref != "" else _checkable_record(member.id)
    if item.is_empty() or str(item.get("owner", "")) != member.id and not _owned_undisclosed(member.id).has(item):
        item = _checkable_record(member.id)
    if item.is_empty() or record_checks_left() <= 0:
        _say_text(member, AstraSocialLines.line(member.id, "saw_none", {}, _pick(member.id + "norec")), result, "RECORD")
        return
    _use_daily("record_checks")
    _player_line(member, "그 기록, 지금 같이 열어 볼 수 있어요?", result, "RECORD")
    _disclose(item, member, result, "record_check")
    var meaning_key := "record_support" if str(item.get("type", "")) == "ALIBI_SUPPORT" else ("record_meaning_specific" if bool(item.get("specific", false)) else "record_meaning_group")
    if str(AstraCrewCatalog.RECORD_DOMAIN.get(member.id, "")) != str(item.get("record_type", "")):
        if meaning_key == "record_meaning_group":
            meaning_key = "record_meaning_other"
        elif meaning_key == "record_meaning_specific":
            meaning_key = "record_meaning_specific_other"
    _say_text(member, AstraSocialLines.line(member.id, meaning_key, _fragment_params(item), _pick(member.id + "meaning")), result, "RECORD")
    result["record"] = item.duplicate(true)

func _ask_yesterday(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "yesterday")
    var before := _yesterday_claim(member.id)
    if before.is_empty():
        _say_text(member, AstraSocialLines.line(member.id, "saw_none", {}, 0.1), result, "YESTERDAY")
        return
    var old_pos := str(before.get("position", ""))
    var old_packet := packet_for(day - 1)
    _player_line(member, "어제 그 시간엔 %s에 있었다고 했죠. 다시 말해 줄래요?" % _packet_room(old_packet, old_pos), result, "YESTERDAY")
    var drift := false
    var new_pos := old_pos
    if member.is_null():
        var chance := 0.18 + member.stress * 0.35 + (0.18 if str(old_packet.get("actor", "")) == member.id else 0.0)
        if _pick(member.id + "drift") < chance:
            var options: Array = []
            for loc in Dictionary(old_packet.get("locations", {})):
                # Nobody "misremembers" being in someone else's cabin.
                if str(loc).begins_with("cabin:") and str(loc) != "cabin:" + member.id:
                    continue
                if str(loc) != old_pos and str(loc) != str(old_packet.get("incident", {}).get("room", "")):
                    options.append(str(loc))
            if not options.is_empty():
                new_pos = str(options[int(_pick(member.id + "driftpos") * options.size()) % options.size()])
                drift = true
    var params := {"pos": _packet_room(old_packet, new_pos), "old": _packet_room(old_packet, old_pos)}
    var line := AstraSocialLines.line(member.id, "yesterday_changed" if drift else "yesterday_same", params, _pick(member.id + "yday"))
    _say_text(member, line, result, "YESTERDAY")
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, line, {"position": new_pos, "about_day": day - 1})
    if drift:
        result["changed_story"] = true
        stats["admissions"] = int(stats.get("admissions", 0)) + 1

func _packet_room(packet: Dictionary, room_id: String) -> String:
    return str(Dictionary(packet.get("locations", {})).get(room_id, AstraStageStory.location_name(room_id)))

func _ask_opinion(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "opinion")
    _player_line(member, "지금 누가 가장 마음에 걸려요? 이유도요.", result, "SUSPECT")
    var top := top_suspect_of(member.id)
    var target := str(top.get("target", ""))
    if target == "" or float(top.get("value", 0.0)) < 0.12:
        _say_text(member, AstraSocialLines.line(member.id, "opinion_none", {}, _pick(member.id + "opn")), result, "SUSPECT")
        return
    _say_text(member, AstraSocialLines.line(member.id, "opinion", {"target": name_of(target), "reason": str(top.get("reason_text", ""))}, _pick(member.id + "op")), result, "SUSPECT")
    result["target"] = target
    AstraDecisionModel.append_trace(flags, AstraDecisionModel.trace(member.id, "opinion", target, Array(top.get("reasons", [])), day))

func _ask_reassure(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "reassure")
    _player_line(member, "몰아세우려는 게 아니에요. 천천히 말해도 돼요.", result, "REASSURE")
    member.adjust_trust(0.1)
    member.adjust_stress(-0.1)
    var book := _conversation_book()
    var state: Dictionary = book.get(member.id, {})
    state["deflected"] = false
    state["reassured"] = true
    book[member.id] = state
    _say_text(member, AstraSocialLines.line(member.id, "reassure", {}, _pick(member.id + "rs")), result, "REASSURE")
    # Someone hiding a harmless reason may now say it without being cornered.
    if _day_role(member.id) == "benign" and not _confessed_today(member.id) and member.trust >= 0.5:
        _confess(member, result, false)

func _ask_pressure(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "pressure")
    _player_line(member, "지금 말하지 않으면 회의에서 제가 말할 거예요.", result, "PRESSURE")
    member.adjust_stress(0.16)
    member.adjust_trust(-0.06)
    var role := _day_role(member.id)
    if role in ["actor", "cover"] and member.stress >= 0.62 and _pick(member.id + "prs") < 0.45:
        _partial_admit(member, result)
        return
    if role == "benign" and not _confessed_today(member.id) and _pick(member.id + "prs") < 0.5:
        _confess(member, result, true)
        return
    _say_text(member, AstraSocialLines.line(member.id, "pressure_null" if member.is_null() else "pressure_crew", {}, _pick(member.id + "prsl")), result, "PRESSURE")

# ---------------------------------------------------------------- cross-examination

func _cross_examine(member: AstraCrewMember, ref: String, result: Dictionary) -> void:
    var pressed := ref.ends_with("|press")
    ref = ref.trim_suffix("|press")
    _mark_asked(member.id, "confront:" + ref)
    result["tone"] = "press" if pressed else "calm"
    if pressed:
        member.adjust_stress(0.14)
        member.adjust_trust(-0.06)
        var book_p := _conversation_book()
        var state_p: Dictionary = book_p.get(member.id, {})
        state_p["pressed"] = true
        book_p[member.id] = state_p
    var book := _conversation_book()
    var state: Dictionary = book.get(member.id, {})
    state["confronted"] = true
    book[member.id] = state
    stats["cross_exams"] = int(stats.get("cross_exams", 0)) + 1
    var confronted: Dictionary = stage_state().get("player_confronted", {})
    confronted[member.id] = int(confronted.get(member.id, 0)) + 1
    stage_state()["player_confronted"] = confronted
    var confront_log: Array = stage_state().get("player_confront_log", [])
    confront_log.append({"npc": member.id, "day": day})
    stage_state()["player_confront_log"] = confront_log
    var source := _conflict_source(member.id, ref)
    result["source"] = source
    _player_line(member, str(source.get("question", "말이 맞지 않는 부분이 있어요.")), result, "CONFRONT")
    member.adjust_stress(0.08 + float(source.get("strength", 0.3)) * 0.15)
    match _day_role(member.id):
        "actor":
            _cross_actor(member, source, result)
        "cover":
            _cross_cover(member, source, result)
        "idle_null":
            if _pick(member.id + ref + "idle") < 0.5:
                _counterattack(member, source, result)
            else:
                _say_text(member, AstraSocialLines.line(member.id, "deny", _source_params(source), _pick(member.id + "deny")), result, "CONFRONT")
        "benign":
            _cross_benign(member, source, result)
        _:
            _cross_honest(member, source, result)

func _conflict_source(npc_id: String, ref: String) -> Dictionary:
    var claim: Dictionary = known_claims.get(npc_id, current_claim(npc_id))
    # Said to their face, their own cabin is just "선실".
    var own_pos := "선실" if str(claim.get("position", "")) == "cabin:" + npc_id else room_name(str(claim.get("position", "")))
    if ref.begins_with("claim:"):
        var other := ref.trim_prefix("claim:")
        var other_claim: Dictionary = known_claims.get(other, {})
        var kind := _claim_conflict_kind(npc_id, other)
        var question := ""
        match kind:
            "they_vouch":
                question = "%s|eun %s에서 당신이랑 같이 있었다고 했어요. 당신은 %s에 있었다면서요." % [name_of(other), room_name(str(other_claim.get("position", ""))), own_pos]
            "you_vouch":
                question = "당신은 %s|wa 같이 있었다고 했죠. 그런데 %s|eun %s에 있었다고 해요." % [name_of(other), name_of(other), room_name(str(other_claim.get("position", "")))]
            "one_sided":
                if other in Array(claim.get("companions", [])):
                    question = "당신은 %s|wa 같이 있었다고 했죠. 그런데 %s|eun 그 시간 혼자였다고 해요." % [name_of(other), name_of(other)]
                else:
                    question = "%s|eun 그 시간 %s에서 당신이랑 같이 있었다고 했어요. 당신은 혼자였다면서요." % [name_of(other), own_pos]
            _:
                question = "%s도 그 시간 %s에 있었대요. 그런데 서로 못 봤다고요?" % [name_of(other), own_pos]
        return {"kind": "claim", "other": other, "strength": 0.34 if kind != "place" else 0.26, "question": _josa_inline(question), "room": str(claim.get("position", ""))}
    if ref == "self":
        return {"kind": "self", "strength": 0.45, "question": "방금 한 말이 아까 한 말과 달라요. 어느 쪽이 맞아요?"}
    var item := fragment(ref)
    if item.is_empty():
        return {"kind": "none", "strength": 0.2, "question": "말이 맞지 않는 부분이 있어요."}
    var owner := name_of(str(item.get("owner", "")))
    var question := ""
    match str(item.get("type", "")):
        "SYSTEM_RECORD":
            # The gist, not the log line read out word for word.
            var device := str(item.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(item.get("record_type", "")), "기록")))
            if bool(item.get("specific", false)):
                question = "%s에 %s, %s에서 당신 인증이 찍혀 있어요. 당신은 %s에 있었다고 했죠." % [device, str(item.get("time", "")), room_name(str(item.get("room", ""))), own_pos]
            else:
                var others: Array = []
                for id in item.get("points_to", []):
                    if str(id) != npc_id:
                        others.append(str(id))
                question = "%s|eul 보면 %s, %s에 들어간 건 당신이나 %s 중 한 사람이에요. 당신은 %s에 있었다고 했죠." % [device, str(item.get("time", "")), room_name(str(item.get("room", ""))), names_of(others), own_pos]
        "ALIBI_SUPPORT":
            question = "당신은 %s|i %s 쪽으로 가는 걸 봤다고 했죠. 기록상 그 시간 %s|eun %s에 있었어요." % [name_of(str(item.get("subject", ""))), room_name(str(incident().get("room", ""))), name_of(str(item.get("subject", ""))), room_name(str(item.get("room", "")))]
        "EXPERT_INFERENCE":
            question = "%s 말로는 ‘%s’ 그러니까 당신 설명은 맞지 않아요." % [owner, str(item.get("text", ""))]
        "HEARSAY":
            question = "%s|eun %s|i 그 시간쯤 누군가를 봤다고 들었대요. 당신 이야기예요." % [owner, name_of(str(item.get("via", "")))]
        _:
            question = "%s|eun %s쯤 당신을 %s 쪽에서 봤다고 했어요. 당신은 %s에 있었다면서요." % [owner, str(item.get("time", "")), room_name(str(item.get("room", ""))), own_pos]
            if not bool(item.get("specific", false)):
                question = "%s|i 본 사람은 %s. 당신도 거기 해당돼요. 그때 정말 %s에 있었어요?" % [owner, AstraCaseGenerator.witness_phrase(str(item.get("group", {}).get("category", "")), str(item.get("group", {}).get("group", ""))).trim_suffix("가").trim_suffix("이"), own_pos]
    return {"kind": "fragment", "fragment": item, "type": str(item.get("type", "")), "owner": str(item.get("owner", "")),
        "strength": float(item.get("strength", 0.3)), "question": _josa_inline(question)}

func _source_params(source: Dictionary) -> Dictionary:
    var item: Dictionary = source.get("fragment", {})
    return {"source": name_of(str(source.get("owner", source.get("other", "")))), "room": room_name(str(incident().get("room", ""))),
        "pos": room_name(str(current_claim(str(item.get("subject", ""))).get("position", ""))) if not item.is_empty() else "",
        "time": incident_time()}

# Evidence the explorer holds against this person today, summed.
func _player_pressure_on(npc_id: String) -> float:
    var total := 0.0
    for item in known_fragments(day):
        if bool(item.get("false", false)) and str(item.get("owner", "")) == npc_id:
            continue
        if npc_id in Array(item.get("points_to", [])) and str(item.get("owner", "")) != npc_id:
            total += float(item.get("strength", 0.3)) * (1.0 if bool(item.get("specific", false)) else 0.6)
    for other in known_claims:
        if str(other) != npc_id and _claim_conflict_kind(npc_id, str(other)) != "":
            total += 0.2
    return total

func _cross_actor(member: AstraCrewMember, source: Dictionary, result: Dictionary) -> void:
    var pressure := _player_pressure_on(member.id) + float(source.get("strength", 0.3))
    var type := str(source.get("type", ""))
    var excuse_key := str(AstraStageStory.method(str(incident().get("method", ""))).get("excuse", "remote"))
    if type == "EXPERT_INFERENCE":
        # The excuse just broke. Most people give ground here.
        if _pick(member.id + "inf") < 0.55 + member.stress * 0.3:
            _partial_admit(member, result)
        else:
            _counterattack(member, source, result)
        return
    if type == "SYSTEM_RECORD" and not _used_excuse(member.id) and _pick(member.id + "exc") < 0.7:
        var excuses: Dictionary = stage_state().get("excuses", {})
        var today: Dictionary = excuses.get(_day_key(), {})
        today[member.id] = true
        excuses[_day_key()] = today
        stage_state()["excuses"] = excuses
        var line := AstraSocialLines.line(member.id, "excuse_" + excuse_key, _source_params(source), _pick(member.id + "excl"))
        _say_text(member, line, result, "CONFRONT")
        _record_claim(member.id, AstraClaimLedger.KIND_DENY, AstraClaimLedger.SCOPE_PRIVATE, line, {"about_day": day, "target": member.id})
        result["excuse"] = excuse_key
        return
    if pressure >= 0.95 or member.stress >= 0.72:
        if _pick(member.id + "admit") < 0.5:
            _partial_admit(member, result)
            return
    if _pick(member.id + "ctr") < 0.4:
        _counterattack(member, source, result)
        return
    var line := AstraSocialLines.line(member.id, "deny", _source_params(source), _pick(member.id + "deny"))
    _say_text(member, line, result, "CONFRONT")
    _record_claim(member.id, AstraClaimLedger.KIND_DENY, AstraClaimLedger.SCOPE_PRIVATE, line, {"about_day": day, "target": member.id})
    if _pick(member.id + "dtell") < 0.45:
        _tell(member, result, "dt")

func _cross_cover(member: AstraCrewMember, source: Dictionary, result: Dictionary) -> void:
    if member.stress >= 0.6 and _pick(member.id + "cadmit") < 0.45:
        _partial_admit(member, result)
        return
    var partner := str(current_packet().get("actor", ""))
    var line := AstraSocialLines.line(member.id, "vouch_hold", {"target": name_of(partner), "pos": room_name(str(current_claim(member.id).get("position", "")))}, _pick(member.id + "cv"))
    _say_text(member, line, result, "CONFRONT")
    _record_claim(member.id, AstraClaimLedger.KIND_DEFEND, AstraClaimLedger.SCOPE_PRIVATE, line, {"about_day": day, "target": partner})

func _cross_benign(member: AstraCrewMember, source: Dictionary, result: Dictionary) -> void:
    if _confessed_today(member.id):
        _say_text(member, AstraSocialLines.line(member.id, "already_told", {}, _pick(member.id + "told")), result, "CONFRONT")
        return
    var benign: Dictionary = current_packet().get("benign", {})
    if bool(benign.get("misremembered", false)):
        _confess(member, result, false)
        return
    var strength := float(source.get("strength", 0.3))
    var reassured := bool(_conversation_book().get(member.id, {}).get("reassured", false))
    if str(result.get("tone", "")) == "press" and not reassured:
        # Cornered, an honest person with something to hide mostly shuts down;
        # only real fear pushes it out.
        if member.stress >= 0.62:
            _confess(member, result, true)
            return
    elif member.trust >= 0.5 or (strength >= 0.33 and member.stress >= 0.42) or reassured:
        _confess(member, result, false)
        return
    var book := _conversation_book()
    var state: Dictionary = book.get(member.id, {})
    state["deflected"] = true
    book[member.id] = state
    member.adjust_stress(0.1)
    member.adjust_trust(-0.02)
    _say_text(member, AstraSocialLines.line(member.id, "deflect", {}, _pick(member.id + "defl")), result, "CONFRONT")
    result["deflected"] = true

func _cross_honest(member: AstraCrewMember, source: Dictionary, result: Dictionary) -> void:
    var claim := current_claim(member.id)
    var mates: Array = claim.get("companions", [])
    var params := {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates)),
        "mate": name_of(str(mates[0])) if not mates.is_empty() else "", "source": name_of(str(source.get("owner", source.get("other", ""))))}
    params.merge(_source_params(source), false)
    var seen_room := str(Dictionary(source.get("fragment", {})).get("room", ""))
    if seen_room != "":
        params["room"] = room_name(seen_room)
    _say_text(member, AstraSocialLines.line(member.id, "explain_with" if not mates.is_empty() else "explain_alone", params, _pick(member.id + "exp")), result, "CONFRONT")
    member.adjust_trust(-0.01)
    if str(result.get("tone", "")) == "press":
        _say_text(member, AstraSocialLines.line(member.id, "pressure_crew", {}, _pick(member.id + "prc")), result, "CONFRONT")
    if str(source.get("type", "")) == "NULL_DECEPTION" or str(source.get("kind", "")) == "claim":
        var accuser := str(source.get("owner", source.get("other", "")))
        if accuser != "" and crew.has(accuser):
            member.add_suspicion(accuser, 0.12)
            if _pick(member.id + "hc") < 0.5:
                _say_text(member, AstraSocialLines.line(member.id, "counter_soft", {"target": name_of(accuser)}, _pick(member.id + "hcs")), result, "CONFRONT")
    result["explained"] = true

func _counterattack(member: AstraCrewMember, source: Dictionary, result: Dictionary) -> void:
    var target := str(source.get("owner", source.get("other", "")))
    if target == "" or not is_alive(target) or target == member.id:
        target = scapegoat_for(member.id)
    if target == "":
        _say_text(member, AstraSocialLines.line(member.id, "deny", _source_params(source), _pick(member.id + "d2")), result, "CONFRONT")
        return
    var line := AstraSocialLines.line(member.id, "counter", {"target": name_of(target), "room": room_name(str(incident().get("room", "")))}, _pick(member.id + "ctrl"))
    _say_text(member, line, result, "CONFRONT")
    _record_claim(member.id, AstraClaimLedger.KIND_ACCUSE, AstraClaimLedger.SCOPE_PRIVATE, line, {"about_day": day, "target": target})
    result["counter"] = target

func _partial_admit(member: AstraCrewMember, result: Dictionary) -> void:
    var room := str(incident().get("room", ""))
    var admissions: Dictionary = stage_state().get("admissions", {})
    admissions[member.id] = {"day": day, "position": room}
    stage_state()["admissions"] = admissions
    var line := AstraSocialLines.line(member.id, "partial_admit", {"room": room_name(room), "pos": room_name(str(current_packet().get("claims", {}).get(member.id, {}).get("position", "")))}, _pick(member.id + "pa"))
    _say_text(member, line, result, "CONFRONT")
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, line, {"position": room, "about_day": day})
    known_claims[member.id] = {"position": room, "companions": [], "day": day, "revised": true}
    stats["admissions"] = int(stats.get("admissions", 0)) + 1
    result["admitted"] = true
    result["changed_story"] = true
    _log("말 바꿈 · %s — %s 앞까지 갔다고 인정" % [member.display_name, room_name(room)])
    notice.emit("admission", {"npc_id": member.id})

func _confessed_today(npc_id: String) -> bool:
    var entry: Dictionary = stage_state().get("confessions", {}).get(npc_id, {})
    return not entry.is_empty() and int(entry.get("day", 0)) == day

func _confess(member: AstraCrewMember, result: Dictionary, pressured: bool) -> void:
    var benign: Dictionary = current_packet().get("benign", {})
    var true_pos := str(benign.get("true_position", current_claim(member.id).get("position", "")))
    var reason := str(benign.get("reason", "PERSONAL_SECRET"))
    var confessions: Dictionary = stage_state().get("confessions", {})
    confessions[member.id] = {"day": day, "position": true_pos, "reason": reason, "public": false}
    stage_state()["confessions"] = confessions
    if reason == "MISREMEMBERED":
        _say_text(member, AstraSocialLines.line(member.id, "misremember", {"pos": room_name(true_pos)}, _pick(member.id + "mis")), result, "CONFRONT")
    else:
        _say_text(member, AstraSocialLines.line(member.id, "confess_pressed" if pressured else "confess", {"pos": room_name(true_pos)}, _pick(member.id + "cf")), result, "CONFRONT")
        _say_text(member, AstraSocialLines.secret(member.id, reason, room_name(true_pos)), result, "CONFRONT")
        stats["secrets"] = int(stats.get("secrets", 0)) + 1
    member.secret_revealed = true
    member.adjust_trust(0.06 if not pressured else -0.02)
    member.adjust_stress(-0.12)
    var mates: Array = []
    for other in active_participants():
        if str(other) != member.id and true_position(str(other)) == true_pos:
            mates.append(str(other))
    known_claims[member.id] = {"position": true_pos, "companions": mates, "day": day, "revised": true}
    for entry in claim_ledger:
        if str(entry.get("speaker", "")) == member.id and int(entry.get("about_day", entry.get("day", 1))) == day and str(entry.get("kind", "")) in [AstraClaimLedger.KIND_POSITION, AstraClaimLedger.KIND_ALONE, AstraClaimLedger.KIND_COMPANION]:
            entry["retracted"] = true
            entry["retracted_day"] = day
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, "(정정) " + room_name(true_pos), {"position": true_pos, "companions": mates, "about_day": day})
    stats["confessions"] = int(stats.get("confessions", 0)) + 1
    result["secret"] = reason != "MISREMEMBERED"
    result["misremembered"] = reason == "MISREMEMBERED"
    result["innocent_reason"] = reason
    _log("%s · %s|i 진술을 정정했다: 실제로는 %s." % ["기억 정정" if reason == "MISREMEMBERED" else "숨긴 사정", member.display_name, room_name(true_pos)])
    notice.emit("secret", {"npc_id": member.id, "reason": reason, "misremembered": reason == "MISREMEMBERED"})

func innocent_discrepancy_text(reason: String) -> String:
    return str({
        "EMBARRASSMENT":"창피해서 사실과 다른 말을 했다.",
        "PROTECT_OTHER":"다른 사람을 감싸려고 일부 사실을 숨겼다.",
        "HIDE_MISTAKE":"자기 실수를 감추려고 진술을 바꿨다.",
        "KEEP_PROMISE":"누군가와 한 약속을 지키려고 일부 사실을 숨겼다.",
        "PERSONAL_SECRET":"사건과 무관한 개인 사정을 숨기려고 진술을 바꿨다.",
        "FEAR":"두려움 때문에 사실대로 말하지 못했다.",
        "MISREMEMBERED":"거짓말이 아니라 장소 순서를 잘못 기억하고 있었다."
    }.get(reason, "사건과 무관한 사정으로 진술이 어긋났다."))

# ---------------------------------------------------------------- protocols

# EMPATH: body language and relationships, never a verdict. A liar shows a
# defensive read most of the time, not always; a frightened honest person can
# look defensive too.
func _ask_empathy(member: AstraCrewMember, result: Dictionary) -> void:
    _mark_asked(member.id, "empathy")
    var role := _day_role(member.id)
    var lying := role in ["actor", "cover"] or (role == "benign" and not _confessed_today(member.id))
    var roll := _pick(member.id + "emp%d" % day)
    var defensive := roll < 0.7 if lying else roll < (0.2 + member.stress * 0.25)
    var code := "SHAKEN" if defensive else "UNCERTAIN"
    _narrate_text(member, "엠패스 · " + _josa_inline(_reaction_action_text(member.id, code)), result)
    _narrate_text(member, "엠패스 · " + ("대답은 매끄럽지만, 특정 장소 이야기가 나오면 말이 짧아진다. 방어하는 쪽에 가깝다." if defensive else "긴장은 있지만 숨을 고르며 되묻는다. 방어보다는 확인하려는 태도에 가깝다."), result)
    var rel := relations_of(member.id)
    var leaning: Array = rel.get("leaning", [])
    var watching: Array = rel.get("watching", [])
    if not leaning.is_empty():
        _narrate_text(member, "엠패스 · %s 이야기가 나오자 목소리가 누그러진다. (%s)" % [name_of(str(leaning[0]["id"])), str(leaning[0]["reason"])], result)
    elif not watching.is_empty():
        _narrate_text(member, "엠패스 · %s 이름에 짧게 시선이 굳는다." % name_of(str(watching[0]["id"])), result)
    result["empath_read"] = "defensive" if defensive else "open"

# ANALYST: compares two things the explorer can see — two claims, or a claim
# and a record the explorer holds. CONSISTENT / CONFLICT / INSUFFICIENT only.
func analyst_candidates() -> Array:
    var items: Array = []
    for id in known_claims:
        items.append({"ref": "claim:" + str(id), "label": "%s의 진술 · %s" % [name_of(str(id)), room_name(str(known_claims[id].get("position", "")))]})
    for item in known_fragments(day):
        if str(item.get("type", "")) in ["SYSTEM_RECORD", "ALIBI_SUPPORT", "DIRECT_WITNESS", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
            items.append({"ref": str(item.get("id", "")), "label": str(item.get("text", ""))})
    return items

func analyst_compare(ref_a: String, ref_b: String) -> Dictionary:
    if not analyst_available() or ref_a == ref_b:
        return {"ok": false}
    var a := _analyst_fact(ref_a)
    var b := _analyst_fact(ref_b)
    if a.is_empty() or b.is_empty():
        return {"ok": false}
    _use_daily("analyst_uses")
    var verdict := "INSUFFICIENT"
    var shared: Array = []
    for id in Array(a.get("people", [])):
        if id in Array(b.get("people", [])):
            shared.append(id)
    if shared.size() == 1:
        var who := str(shared[0])
        var place_a := str(Dictionary(a.get("places", {})).get(who, ""))
        var place_b := str(Dictionary(b.get("places", {})).get(who, ""))
        if place_a != "" and place_b != "":
            verdict = "CONSISTENT" if place_a == place_b else "CONFLICT"
    elif shared.is_empty():
        # Two different people: they conflict only if one names the other as a
        # companion somewhere the other does not say.
        for who in Dictionary(a.get("vouches", {})):
            if who in Array(b.get("people", [])):
                verdict = "CONSISTENT" if str(a["vouches"][who]) == str(Dictionary(b.get("places", {})).get(who, "")) else "CONFLICT"
        for who in Dictionary(b.get("vouches", {})):
            if who in Array(a.get("people", [])):
                verdict = "CONSISTENT" if str(b["vouches"][who]) == str(Dictionary(a.get("places", {})).get(who, "")) else "CONFLICT"
    var text: String = {"CONSISTENT": "일치 · 두 내용은 같은 시각, 같은 위치를 말한다.", "CONFLICT": "충돌 · 두 내용은 동시에 참일 수 없다.", "INSUFFICIENT": "판단 불가 · 두 내용만으로는 같은 사람의 같은 시각을 비교할 수 없다."}[verdict]
    var entry := {"day": day, "a": ref_a, "b": ref_b, "result": verdict, "text": text}
    # The person whose own words were compared reacts (§68).
    var reaction := {}
    if verdict != "INSUFFICIENT":
        for ref in [ref_a, ref_b]:
            if str(ref).begins_with("claim:") and is_alive(str(ref).trim_prefix("claim:")):
                var who := str(ref).trim_prefix("claim:")
                reaction = {"speaker": who, "text": AstraSocialLines.line(who, "analyst_conflict" if verdict == "CONFLICT" else "analyst_consistent", {}, _pick(who + "anr"))}
                crew[who].adjust_stress(0.08 if verdict == "CONFLICT" else -0.04)
                break
    entry["reaction"] = reaction
    stage_state()["analyses"].append(entry)
    _log("정밀 대조 · " + text)
    changed.emit()
    return {"ok": true, "result": verdict, "text": text, "reaction": reaction}

func _analyst_fact(ref: String) -> Dictionary:
    if ref.begins_with("claim:"):
        var who := ref.trim_prefix("claim:")
        if not known_claims.has(who):
            return {}
        var claim: Dictionary = known_claims[who]
        var vouches := {}
        for mate in Array(claim.get("companions", [])):
            vouches[str(mate)] = str(claim.get("position", ""))
        return {"people": [who], "places": {who: str(claim.get("position", ""))}, "vouches": vouches}
    var item := fragment(ref)
    if item.is_empty() or not player_knows(ref):
        return {}
    var subject := str(item.get("subject", ""))
    if subject == "":
        return {"people": Array(item.get("points_to", [])), "places": {}, "vouches": {}}
    return {"people": [subject], "places": {subject: str(item.get("room", ""))}, "vouches": {}}

# ---------------------------------------------------------------- speech helpers

func _pick(key: String) -> float:
    return _stable_noise("%s:%d" % [key, day])

# The explorer's own public wording for a meeting move (same placeholders).
func _voice(key: String, fallback: String) -> String:
    return AstraExplorerCatalog.meeting_line(str(player_profile()["explorer_id"]), key, fallback)

func _player_line(member: AstraCrewMember, text: String, result: Dictionary, intent: String) -> void:
    text = AstraExplorerCatalog.spoken(str(player_profile()["explorer_id"]), intent, text).replace("{time}", incident_time())
    _transcript(member.id, "player", text, intent)
    result["lines"].append({"speaker": "player", "text": _josa_inline(text), "intent": intent})

func _say_text(member: AstraCrewMember, text: String, result: Dictionary, intent: String) -> void:
    if text == "":
        return
    text = _self_refs(member.id, text)
    _transcript(member.id, member.id, text, intent)
    result["lines"].append({"speaker": member.id, "text": _josa_inline(text), "intent": intent})

# People call their own cabin "my cabin", not "Mira's cabin".
const BANMAL_SPEAKERS := ["rho", "dax", "sena", "eli"]
func _self_refs(speaker_id: String, text: String) -> String:
    if not crew.has(speaker_id):
        return text
    var own := name_of(speaker_id) + "의 선실"
    if own in text:
        text = text.replace(own, ("내" if speaker_id in BANMAL_SPEAKERS else "제") + " 선실")
    # "다렌은 다렌의 선실에" → "다렌은 자기 선실에".
    for other in crew:
        var name := name_of(str(other))
        if not (name + "의 선실") in text:
            continue
        for mark in [AstraJosa.eun(name), AstraJosa.i(name)]:
            text = text.replace(mark + " " + name + "의 선실", mark + " 자기 선실")
    return text

func _narrate_text(member: AstraCrewMember, text: String, result: Dictionary) -> void:
    if member != null:
        _transcript(member.id, "narration", text, str(result.get("intent", "")))
    result["lines"].append({"speaker": "narration", "text": _josa_inline(text), "intent": str(result.get("intent", ""))})

func _reaction_action_text(npc_id: String, code: String) -> String:
    var actions := {
        "mira": {"CONVINCED":"미라가 굳어 있던 손을 풀고 기록을 다시 펼친다.", "SHAKEN":"미라가 대답 대신 생체 기록을 한 번 더 확인한다.", "RESISTED":"미라가 잠시 입을 다물고 시선을 피한다.", "UNCERTAIN":"미라가 기록과 당신을 번갈아 본다.", "ANGERED":"미라가 의료 단말을 닫고 한 걸음 물러선다."},
        "rho": {"CONVINCED":"준이 고개를 끄덕이며 공구를 내려놓는다.", "SHAKEN":"준이 대답하려다 입을 다물고 패널 쪽을 본다.", "RESISTED":"준이 팔짱을 끼고 같은 설명을 되풀이한다.", "UNCERTAIN":"준이 턱을 긁으며 기억을 다시 더듬는다.", "ANGERED":"준이 짧게 숨을 내쉬고 더는 대꾸하지 않는다."},
        "noa": {"CONVINCED":"노아가 기록을 다시 내려다보고 문장 하나를 고친다.", "SHAKEN":"노아의 손이 같은 시각 위에서 멈춘다.", "RESISTED":"노아가 메모를 덮고 답을 미룬다.", "UNCERTAIN":"노아가 두 기록을 나란히 놓고 다시 읽는다.", "ANGERED":"노아가 노트를 닫고 한동안 말을 하지 않는다."},
        "dax": {"CONVINCED":"다렌이 계산 한 줄을 지우고 순서를 다시 적는다.", "SHAKEN":"다렌이 방금 계산을 지우고 처음부터 다시 본다.", "RESISTED":"다렌이 화면을 돌려 놓고 같은 결론을 유지한다.", "UNCERTAIN":"다렌이 숫자 두 개 사이에 물음표를 적는다.", "ANGERED":"다렌이 단말을 잠그고 대화를 끝낸다."},
        "sena": {"CONVINCED":"세나가 팔짱을 풀고 출입 기록 쪽으로 몸을 돌린다.", "SHAKEN":"세나가 문 쪽을 보다가 다시 당신을 본다.", "RESISTED":"세나가 자세를 굳힌 채 답을 바꾸지 않는다.", "UNCERTAIN":"세나가 출입카드를 만지작거리며 생각한다.", "ANGERED":"세나가 턱을 굳히고 대화를 끊는다."},
        "vale": {"CONVINCED":"소렌이 이어폰 한쪽을 빼고 기록을 다시 듣는다.", "SHAKEN":"소렌이 파형을 멈추고 같은 구간을 되감는다.", "RESISTED":"소렌이 볼륨을 낮추고 고개를 젓는다.", "UNCERTAIN":"소렌이 소리 없는 구간을 한 번 더 재생한다.", "ANGERED":"소렌이 이어폰을 다시 끼고 말을 멈춘다."},
        "eli": {"CONVINCED":"루칸이 항로 화면을 확대해 당신이 짚은 시각을 표시한다.", "SHAKEN":"루칸의 손이 좌표 위에서 잠시 멈춘다.", "RESISTED":"루칸이 시선을 창밖으로 돌린 채 결론을 바꾸지 않는다.", "UNCERTAIN":"루칸이 별 위치와 기록 시각을 다시 맞춘다.", "ANGERED":"루칸이 화면을 닫고 자리에서 일어난다."},
        "lyra": {"CONVINCED":"마렌이 장갑을 벗고 기록 옆에 새 메모를 놓는다.", "SHAKEN":"마렌이 손에 들고 있던 표본을 천천히 내려놓는다.", "RESISTED":"마렌이 대답 대신 표본 라벨을 다시 확인한다.", "UNCERTAIN":"마렌이 두 표본을 나란히 놓고 비교한다.", "ANGERED":"마렌이 작업대를 정리하며 대화를 끝낸다."}
    }
    var by_npc: Dictionary = actions.get(npc_id, {})
    return str(by_npc.get(code, "%s|eun 잠시 생각에 잠긴다." % name_of(npc_id)))

func _dialogue_reaction(member: AstraCrewMember, intent: String, result: Dictionary) -> Dictionary:
    var code := ""
    if bool(result.get("admitted", false)):
        code = "SHAKEN"
    elif bool(result.get("secret", false)) or bool(result.get("misremembered", false)) or intent == "REASSURE":
        code = "CONVINCED"
    elif bool(result.get("deflected", false)):
        code = "RESISTED"
    elif intent == "PRESSURE":
        code = "ANGERED" if member.trust < 0.35 else "SHAKEN"
    elif intent == "CONFRONT":
        code = "UNCERTAIN" if bool(result.get("explained", false)) else ("RESISTED" if result.has("excuse") or result.has("counter") else "SHAKEN")
    if code == "":
        return {}
    return {"code": code, "text": _josa_inline(_reaction_action_text(member.id, code))}

# Who this person would name, from what they know. Innocent crew use only
# their own knowledge (AstraKnowledgeModel); a Null names a scapegoat.
func top_suspect_of(observer_id: String) -> Dictionary:
    var member := npc(observer_id)
    if member == null:
        return {}
    if member.is_null():
        var target := scapegoat_for(observer_id)
        var public_view := suspicion_breakdown(observer_id, target, true)
        return {"target": target, "value": maxf(0.3, float(public_view.get("score", 0.0))), "reasons": public_view.get("reasons", []),
            "reason_text": _reason_text_for(observer_id, public_view.get("reasons", []))}
    var best := ""
    var best_value := -99.0
    var best_reasons: Array = []
    for other in living_ids():
        if other == observer_id:
            continue
        var view := suspicion_breakdown(observer_id, str(other))
        var value := float(view.get("score", 0.0)) + _stable_noise("opinion:%s:%s" % [observer_id, other]) * 0.03
        if value > best_value:
            best_value = value
            best = str(other)
            best_reasons = view.get("reasons", [])
    return {"target": best, "value": best_value, "reasons": best_reasons, "reason_text": _reason_text_for(observer_id, best_reasons)}

# The strongest reason in this person's own words; "제가 직접 본 것" when the
# evidence is their own sighting or the log they opened.
func _reason_text_for(speaker: String, reasons: Array) -> String:
    for item in reasons:
        if float(item.get("weight", 0.0)) <= 0.0:
            continue
        var code := str(item.get("code", ""))
        var source_id := str(item.get("source", ""))
        var src := fragment(source_id)
        if not src.is_empty():
            var phrase := _provenance_phrase(speaker, code, src)
            if phrase != "":
                return phrase
        if source_id == "claim:" + speaker:
            return "내 말과 어긋나는 점" if speaker in BANMAL_SPEAKERS else "제 말과 어긋나는 점"
        return AstraDecisionModel.reason_noun(code, speaker)
    return "설명하기 어려운 위화감"

# Where a reason came from decides how it is said (§8): what the speaker saw,
# a log they opened, what someone told them, what an expert explained, what
# someone else saw. Never "I saw it" for a record or a retold sighting.
func _provenance_phrase(speaker: String, code: String, src: Dictionary) -> String:
    var type := str(src.get("type", ""))
    var owner := str(src.get("owner", ""))
    var mine := owner == speaker
    var me := "내가" if speaker in BANMAL_SPEAKERS else "제가"
    var when := ""
    if mine:
        var from_day := _fragment_day(str(src.get("id", "")))
        when = "" if from_day >= day or from_day <= 0 else ("어제 " if from_day == day - 1 else "전에 ")
    match type:
        "DIRECT_WITNESS":
            if mine:
                return when + me + " 직접 본 것"
            return _josa_inline("%s|i 봤다는 것" % name_of(owner))
        "HEARSAY":
            if mine:
                return me + " 전해 들은 말"
            return _josa_inline("%s|i 전한 말" % name_of(owner))
        "SYSTEM_RECORD":
            if mine:
                return when + me + " 확인한 기록"
            return str(src.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(src.get("record_type", "")), "기록")))
        "BENIGN_EXPOSURE", "COVER_EXPOSURE":
            if mine:
                return when + me + " 본 것과 말이 다른 점"
            return _josa_inline("%s|i 본 것과 말이 다른 점" % name_of(owner))
        "EXPERT_INFERENCE":
            if mine:
                return me + " 아는 장비 구조"
            return _josa_inline("%s|i 설명한 장비 구조" % name_of(owner))
        "NULL_DECEPTION":
            return AstraDecisionModel.reason_noun("FALSE_SIGHTING", speaker)
    return ""

func _reason_phrase(reasons: Array) -> String:
    for item in reasons:
        if float(item.get("weight", 0.0)) > 0.0:
            return AstraDecisionModel.reason_noun(str(item.get("code", "")))
    return "설명하기 어려운 위화감"

# A Null's pick for who to push: whoever the room already looks at, among the
# innocent. Public heat and suspicion only; a Null knows who its partner is.
func scapegoat_for(null_id: String) -> String:
    var heat := _public_heat()
    var style := null_style(null_id)
    var ally := null_ally(null_id)
    var best := ""
    var best_value := -99.0
    for other in living_ids():
        if other == null_id or crew[other].is_null() or other == ally:
            continue
        var value := float(heat.get(other, 0.0)) + crowd_suspicion(other) + _stable_noise(null_id + other) * 0.05
        match style:
            "COUNTERATTACK":
                value += 0.7 * _stood_against(str(other), null_id)
            "DEFLECTOR":
                value += 0.35 * float(_public_conflicts_on(str(other)))
                var claim := _claim_visible(null_id, str(other))
                if not claim.is_empty() and Array(claim.get("companions", [])).is_empty():
                    value += 0.12
        if value > best_value:
            best_value = value
            best = str(other)
    return best

func crowd_suspicion(target_id: String) -> float:
    var total := 0.0
    var count := 0
    for npc_id in living_ids():
        if npc_id == target_id or crew[npc_id].is_null():
            continue
        total += crew[npc_id].get_suspicion(target_id)
        count += 1
    return total / float(count) if count > 0 else 0.0

# ================================================================ judgement
#
# suspicion_breakdown(observer, target) is the one place where a person's
# opinion of another person is formed. It reads only:
#   * fragments the observer holds, was told, or heard in public
#   * claims made in public today, and the observer's own whereabouts
#   * public acts in meetings and votes
#   * the observer's relationship with the target
# It never reads truth["nulls"], hidden claims, or the explorer's private notes.
# Nulls call it with public_only = true to know what an innocent would say.

func _obs_knows(observer_id: String, fact_id: String, public_only: bool) -> bool:
    if public_only:
        return AstraKnowledgeModel.is_public(flags, fact_id)
    return AstraKnowledgeModel.knows(flags, observer_id, fact_id)

func _claim_visible(observer_id: String, npc_id: String) -> Dictionary:
    if observer_id == "player":
        return Dictionary(known_claims.get(npc_id, {}))
    if public_claims.has(npc_id) or observer_id == npc_id:
        var claim := current_claim(npc_id)
        return {"position": str(claim.get("position", "")), "companions": Array(claim.get("companions", [])).duplicate()}
    return {}

func _confession_visible(observer_id: String, npc_id: String) -> bool:
    var entry: Dictionary = stage_state().get("confessions", {}).get(npc_id, {})
    if entry.is_empty():
        return false
    return bool(entry.get("public", false)) or observer_id == "player"

func _admission_visible(observer_id: String, npc_id: String) -> bool:
    var entry: Dictionary = stage_state().get("admissions", {}).get(npc_id, {})
    if entry.is_empty():
        return false
    return bool(entry.get("public", false)) or observer_id == "player"

# A false sighting is exposed when the person it names is placed elsewhere by
# something this observer can see: a companion's public claim, an alibi
# record, or the observer's own memory of being with them.
func _deception_refuted(item: Dictionary, observer_id: String, public_only: bool) -> bool:
    var subject := str(item.get("subject", ""))
    var fday := int(item.get("day", day))
    if fday != day:
        return bool(stage_state().get("refuted_frames", {}).get(str(item.get("id", "")), false))
    if observer_id != "player" and not public_only and observer_id != subject and npc(observer_id) != null and not npc(observer_id).is_null():
        if true_position(observer_id) == true_position(subject) and _day_role(observer_id) == "honest" and _day_role(subject) != "actor":
            return true
    var subject_claim := _claim_visible(observer_id, subject)
    if subject_claim.is_empty():
        return false
    for mate in Array(subject_claim.get("companions", [])):
        var mate_claim := _claim_visible(observer_id, str(mate))
        if not mate_claim.is_empty() and subject in Array(mate_claim.get("companions", [])) and str(mate_claim.get("position", "")) == str(subject_claim.get("position", "")):
            return true
    for other in current_packet().get("fragments", []):
        if str(other.get("type", "")) == "ALIBI_SUPPORT" and str(other.get("supports", "")) == subject and _obs_knows(observer_id, str(other.get("id", "")), public_only):
            # Holding a log that happens to place someone elsewhere is not the
            # same as noticing it answers today's sighting. Methodical people
            # connect it on their own; others need someone to point it out.
            if public_only or AstraKnowledgeModel.is_public(flags, str(other.get("id", ""))) or observer_id == "player":
                return true
            if _stable_noise("connect:%s:%s" % [observer_id, str(other.get("id", ""))]) < float(CONNECTS.get(observer_id, 0.4)):
                return true
    return false

# How readily someone links what they hold to what was said in the room.
const CONNECTS := {"noa": 0.75, "dax": 0.7, "eli": 0.65, "vale": 0.5, "mira": 0.45, "sena": 0.35, "lyra": 0.35, "rho": 0.3}

func suspicion_breakdown(observer_id: String, target_id: String, public_only: bool = false) -> Dictionary:
    var items: Array = []
    var observer := npc(observer_id)
    var honest_observer := observer != null and not observer.is_null() and not public_only
    for key in stage_state().get("packets", {}):
        var fday := int(key)
        var decay := 1.0 if fday == day else 0.5
        for item in stage_state()["packets"][key].get("fragments", []):
            var id := str(item.get("id", ""))
            if not _obs_knows(observer_id, id, public_only):
                continue
            var type := str(item.get("type", ""))
            # Someone who heard the witness themselves no longer leans on the
            # retold version (it may have changed on the way).
            if type == "HEARSAY":
                var source := _hearsay_source(item)
                if not source.is_empty() and _obs_knows(observer_id, str(source.get("id", "")), public_only):
                    continue
            var owner := str(item.get("owner", ""))
            var points: Array = item.get("points_to", [])
            var cred := 1.0
            if owner == observer_id:
                cred = 1.15
            elif observer != null and crew.has(owner):
                cred = clampf(0.9 + observer.get_affinity(owner) * 0.35, 0.6, 1.2)
            # The word of someone the room is already accusing counts for less.
            if owner != observer_id and type in TESTIMONY_TYPES and crew.has(owner):
                cred *= clampf(1.0 - 0.35 * _accusation_weight_on(owner, observer_id), 0.55, 1.0)
            if type in ["DIRECT_WITNESS", "SYSTEM_RECORD", "HEARSAY", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"] and target_id in points and owner != target_id:
                if type == "NULL_DECEPTION" and _deception_refuted(item, observer_id, public_only):
                    continue
                if type == "BENIGN_EXPOSURE" and _confession_visible(observer_id, target_id):
                    items.append({"category": "EXPLAINED", "strength": -0.2, "source": id})
                    continue
                var alive_members := 0
                for member_id in points:
                    if is_alive(str(member_id)) or str(member_id) == target_id:
                        alive_members += 1
                var share := 1.0 if bool(item.get("specific", false)) else clampf(1.05 / float(maxi(1, alive_members)), 0.25, 0.6)
                # One person's word is not proof (§3): someone else's sighting
                # carries half its weight until a second, independent source
                # points the same way. A log is hard, but an unanswered excuse
                # takes the edge off it.
                var standing := 1.0
                if owner != observer_id:
                    if type in TESTIMONY_TYPES and not _corroborated(item, target_id, observer_id, public_only):
                        standing = 0.5
                    elif type == "SYSTEM_RECORD" and _excuse_stands(target_id, observer_id):
                        standing = 0.6
                items.append({"category": str(item.get("category", "DIRECT_WITNESS")), "strength": float(item.get("strength", 0.3)) * share * cred * decay * standing, "source": id, "text": str(item.get("text", ""))})
            if type == "NULL_DECEPTION" and owner == target_id and _deception_refuted(item, observer_id, public_only):
                items.append({"category": "FALSE_SIGHTING", "strength": 0.5 * decay, "source": id})
            if type == "ALIBI_SUPPORT":
                if str(item.get("supports", "")) == target_id:
                    items.append({"category": "CORROBORATED", "strength": -0.3 * decay, "source": id})
            if type == "ROUTINE" and str(item.get("supports", "")) == target_id:
                items.append({"category": "CORROBORATED", "strength": -0.1 * decay, "source": id})
            if type == "EXPERT_INFERENCE" and str(item.get("refutes", "")) == target_id and fday == day and _excuse_visible(observer_id, target_id):
                # A second excuse leaves the room unsure until someone makes
                # the expert say it plainly.
                var contest := contested_state(id)
                var expert_strength := 0.4 * (0.45 if contest == "open" else (1.25 if contest == "settled" else 1.0))
                items.append({"category": "EXPERT_INFERENCE", "strength": expert_strength, "source": id, "text": str(item.get("text", ""))})
    # Today's claims that do not fit together.
    var target_claim := _claim_visible(observer_id, target_id)
    if not target_claim.is_empty():
        for other in living_ids():
            if other == target_id:
                continue
            var other_claim := _claim_visible(observer_id, str(other))
            if other_claim.is_empty():
                continue
            var kind := _visible_conflict(target_id, target_claim, str(other), other_claim)
            if kind == "":
                continue
            var strength := 0.3 if kind != "place" else 0.16
            if honest_observer and str(other) == observer_id:
                # The observer knows their own side is true.
                strength = 0.55 if kind != "place" else 0.42
            elif observer_id != "player" and not _conflict_raised(target_id, str(other)):
                # Two alibis on the board that cannot both be true only weigh
                # with the room once someone has said so aloud (1.0).
                continue
            if _explained_publicly(target_id) or _explained_publicly(str(other)):
                # One of the two already said why their words did not fit.
                continue
            items.append({"category": "CONTRADICTION", "strength": strength, "source": "claim:" + str(other)})
        if Array(target_claim.get("companions", [])).is_empty():
            items.append({"category": "RISK", "strength": 0.05, "source": "alone"})
    if honest_observer and observer_id != target_id and true_position(observer_id) != "" and true_position(observer_id) == true_position(target_id):
        items.append({"category": "CORROBORATED", "strength": -0.6, "source": "own_eyes"})
    if _confession_visible(observer_id, target_id):
        items.append({"category": "EXPLAINED", "strength": -0.15, "source": "confession"})
    if _admission_visible(observer_id, target_id):
        items.append({"category": "CHANGED_STORY", "strength": 0.55, "source": "admission"})
    for conflict in AstraClaimLedger.self_conflicts(claim_ledger, target_id):
        var a: Dictionary = conflict.get("a", {})
        var b: Dictionary = conflict.get("b", {})
        var seen := observer_id == "player" or (str(a.get("scope", "")) == AstraClaimLedger.SCOPE_PUBLIC and str(b.get("scope", "")) == AstraClaimLedger.SCOPE_PUBLIC)
        if seen and not _confession_visible(observer_id, target_id):
            items.append({"category": "CHANGED_STORY", "strength": 0.4, "source": "ledger"})
            break
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("target", "")) != target_id or str(entry.get("speaker", "")) == observer_id:
            continue
        var accuser := str(entry.get("speaker", ""))
        var trust_in := 0.6
        if observer != null and crew.has(accuser):
            trust_in = clampf(0.6 + observer.get_affinity(accuser) * 0.5, 0.2, 1.0)
        elif accuser == "player" and observer != null:
            trust_in = clampf(observer.trust, 0.2, 1.0)
        items.append({"category": "SOCIAL_BEHAVIOR", "strength": 0.1 * trust_in * float(entry.get("weight", 1.0)) * (1.0 if int(entry.get("day", day)) == day else 0.6), "source": "accuse:" + accuser})
    # Pushing someone without a reason, once it is exposed, is itself a tell.
    for entry in stage_state().get("thin_accusations", []):
        if str(entry.get("speaker", "")) == target_id and int(entry.get("day", 0)) == day and observer_id != target_id:
            items.append({"category": "SOCIAL_BEHAVIOR", "strength": 0.3, "source": "thin:" + str(entry.get("target", ""))})
    if int(stage_state().get("held_firm", {}).get(target_id, 0)) == day:
        items.append({"category": "EXPLAINED", "strength": -0.1, "source": "held_firm"})
    if observer != null:
        var affinity := observer.get_affinity(target_id)
        if absf(affinity) > 0.05:
            items.append({"category": "RELATIONSHIP", "strength": -affinity * 0.3, "source": "affinity"})
    var evaluated := AstraDecisionModel.evaluate(observer_id if observer_id != "" else "player", items)
    evaluated["target"] = target_id
    return evaluated

const TESTIMONY_TYPES := ["DIRECT_WITNESS", "HEARSAY", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]

func _accusation_weight_on(target_id: String, exclude: String) -> float:
    var total := 0.0
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("target", "")) == target_id and int(entry.get("day", 0)) == day and str(entry.get("speaker", "")) != exclude:
            total += float(entry.get("weight", 1.0))
    return total

# Another source the observer can see that points at the same person: a log,
# another person's sighting (not hearsay of the same one), an expert's word
# against their excuse, or their own public slip.
func _corroborated(item: Dictionary, target_id: String, observer_id: String, public_only: bool) -> bool:
    var owner := str(item.get("owner", ""))
    var via := str(item.get("via", ""))
    for key in stage_state().get("packets", {}):
        for other in stage_state()["packets"][key].get("fragments", []):
            if str(other.get("id", "")) == str(item.get("id", "")):
                continue
            var other_owner := str(other.get("owner", ""))
            if other_owner == owner or other_owner == via or str(other.get("via", "")) == owner:
                continue
            if not _obs_knows(observer_id, str(other.get("id", "")), public_only):
                continue
            var type := str(other.get("type", ""))
            if type in ["SYSTEM_RECORD", "DIRECT_WITNESS", "HEARSAY", "BENIGN_EXPOSURE", "COVER_EXPOSURE"] and target_id in Array(other.get("points_to", [])):
                return true
            if type == "EXPERT_INFERENCE" and str(other.get("refutes", "")) == target_id and _excuse_visible(observer_id, target_id):
                return true
    if _admission_visible(observer_id, target_id):
        return true
    return false

# The named person answered a log with an excuse in public and nobody who
# knows the equipment has answered it (or the answer is still contested).
func _excuse_stands(target_id: String, observer_id: String) -> bool:
    if not _excuse_visible(observer_id, target_id):
        return false
    for other in current_packet().get("fragments", []):
        if str(other.get("type", "")) == "EXPERT_INFERENCE" and str(other.get("refutes", "")) == target_id and AstraKnowledgeModel.is_public(flags, str(other.get("id", ""))):
            return contested_state(str(other.get("id", ""))) == "open"
    return true

func _excuse_visible(observer_id: String, target_id: String) -> bool:
    var public_excuse := bool(stage_state().get("public_excuses", {}).get(_day_key(), {}).get(target_id, false))
    return public_excuse or (observer_id == "player" and _used_excuse(target_id))

func _visible_conflict(a: String, ca: Dictionary, b: String, cb: Dictionary) -> String:
    var same := str(ca.get("position", "")) == str(cb.get("position", ""))
    var a_mates: Array = ca.get("companions", [])
    var b_mates: Array = cb.get("companions", [])
    if a in b_mates and not same:
        return "they_vouch"
    if b in a_mates and not same:
        return "you_vouch"
    if same and a not in b_mates and b not in a_mates:
        return "place"
    if same and ((b in a_mates) != (a in b_mates)):
        return "one_sided"
    return ""

func suspicion_score(observer_id: String, target_id: String) -> float:
    return float(suspicion_breakdown(observer_id, target_id).get("score", 0.0))

# Keep the legacy suspicion floats (used by relation UI) in step with judgement.
func _refresh_npc_suspicion() -> void:
    for observer_id in living_ids():
        var member: AstraCrewMember = crew[observer_id]
        for target_id in living_ids():
            if target_id == observer_id:
                continue
            var score := float(suspicion_breakdown(observer_id, target_id, member.is_null()).get("score", 0.0))
            member.suspicion[target_id] = clampf(0.2 + score * 0.55, 0.0, 1.0)
        member.refresh_expression()

# ================================================================ meeting
#
# The meeting is the Day's climax. Every current alibi goes on the board, then
# two to four connected arguments play out: someone puts a record or sighting
# down, the named person answers, a third person weighs in. Nobody recites in
# a queue. The explorer gets one intervention (two with EMPATH once a Day).

func interventions_max() -> int:
    return AstraCaseCatalog.MEETING_INTERVENTIONS + (1 if empath_available() else 0)

func meeting_thread_budget() -> int:
    var budget := (2 if day <= 1 else 3) if part() == 1 else (3 if day <= 1 else 4)
    if deep_modifier() == "SILENT_DECK":
        budget = maxi(1, budget - 1)
    return budget

func _make_claims_public() -> void:
    for npc_id in living_ids():
        if public_claims.has(npc_id):
            continue
        var claim := current_claim(npc_id)
        var companions: Array = claim.get("companions", [])
        var key := "m_alibi_with" if not companions.is_empty() else "m_alibi_alone"
        var params := {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(companions))}
        _record_claim(npc_id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PUBLIC, AstraDialogue.line(npc_id, key, params, 0),
            {"position": claim.get("position", ""), "companions": companions, "about_day": day})
        public_claims[npc_id] = true
        AstraKnowledgeModel.make_public(flags, "claim:D%d:%s" % [day, npc_id], active_participants(), day, "meeting_board")
        known_claims[npc_id] = {"position": str(claim.get("position", "")), "companions": companions.duplicate(), "day": day}
    # A confession made to the explorer stays private until someone says it aloud.

func _open_meeting() -> void:
    meeting_feed.clear()
    var state := stage_state()
    state["meeting_plan"] = []
    state["meeting_played"] = 0
    state["meeting_moment"] = {}
    state["meeting_over"] = false
    state["meeting_day"] = day
    state["clarifications_left"] = 3
    state["meeting_arcs"] = []
    var mood := meeting_temperature()
    if mood == "grief":
        var last: Dictionary = casualties[casualties.size() - 1]
        var victim_id := str(last.get("id", ""))
        _feed_narration("%s의 자리가 비어 있다. 한동안 아무도 먼저 입을 열지 않는다." % name_of(victim_id))
        var mourner := _most_affine(victim_id)
        if mourner != "":
            _feed_npc(mourner, "m_mourn", {"victim": name_of(victim_id)}, "mourn", victim_id)
    _make_claims_public()
    match mood:
        "low":
            _feed_narration("모두가 %s에 있던 곳을 말한다. 아직은 다들 조심스럽게 서로의 얼굴을 살핀다." % incident_time())
        "high":
            _feed_narration("모두가 %s에 있던 곳을 말한다. 이제 누구도 돌려 말하지 않는다." % incident_time())
        _:
            _feed_narration("모두가 %s에 있던 곳을 말한다. 목소리가 조금씩 높아진다." % incident_time())
    state["meeting_plan"] = _plan_threads()
    meeting_continue()

# How the room feels today (§26): quiet grief after a death, careful on the
# first day of an early Stage, sharp once stories have started to change.
func meeting_temperature() -> String:
    if not casualties.is_empty():
        var last: Dictionary = casualties[casualties.size() - 1]
        if int(last.get("day", 0)) == day - 1 and str(last.get("id", "")) != "player":
            return "grief"
    if day == 1 and stage_index() <= 2:
        return "low"
    var tension := 0
    for entry in manual_contradictions:
        if int(entry.get("day", 0)) >= day - 1:
            tension += 1
    if day >= 3 or tension >= 2:
        return "high"
    return "mid"

# Who has something to raise, and how badly they want to (§25). The order is
# not a script: it comes from what is unsaid today and who holds it.
func _plan_threads() -> Array:
    var scored: Array = []
    var seen := {}
    for item in current_packet().get("fragments", []) + _recovered_today():
        var id := str(item.get("id", ""))
        if AstraKnowledgeModel.is_public(flags, id):
            continue
        var kind := ""
        var base := 0.0
        match str(item.get("type", "")):
            "SYSTEM_RECORD":
                kind = "record"
                base = 0.5
            "DIRECT_WITNESS":
                kind = "witness"
                base = 0.45
            "NULL_DECEPTION":
                # A false sighting is rarely the room's opening move: a Null
                # lets others speak first (§12, "the first accuser is the Null").
                kind = "frame"
                base = 0.34
            "HEARSAY":
                # Retold sightings come up in the room (Stage 3's theme, and
                # later mixed in): a second voice, or a changed detail.
                kind = "hearsay"
                base = 0.42 + float(AstraCaseGenerator.STAGE_THEMES.get(case_id, {}).get("hearsay_distort", 0.0)) * 0.4
        if kind == "" or seen.has(kind):
            continue
        seen[kind] = true
        # Player contact should make a thread more likely to enter the room; an
        # untouched private fact must not receive the same agenda priority.
        scored.append({"kind": kind, "p": base + (0.55 if player_knows(id) else -0.12) + _pick("plan:" + kind) * 0.28})
    if not Dictionary(current_packet().get("benign", {})).is_empty():
        scored.append({"kind": "benign", "p": 0.42 + _pick("plan:benign") * 0.35})
    if day > 1:
        scored.append({"kind": "callback", "p": 0.5 + _pick("plan:callback") * 0.3 + (0.3 if deep_modifier() == "ECHO" else 0.0)})
        var last_night: Dictionary = stage_state().get("night_log", []).back() if not stage_state().get("night_log", []).is_empty() else {}
        if bool(last_night.get("protected", false)) and str(last_night.get("attacked", "")) not in ["", "player"]:
            scored.append({"kind": "shield", "p": 0.75 + _pick("plan:shield") * 0.2})
    scored.append({"kind": "claims", "p": 0.36 + _pick("plan:claims") * 0.3})
    scored.append({"kind": "accuse", "p": 0.38 + _pick("plan:accuse") * 0.3})
    scored.append({"kind": "accuse", "p": 0.2 + _pick("plan:accuse2") * 0.2})
    scored.sort_custom(func(a, b): return float(a["p"]) > float(b["p"]))
    var plan: Array = []
    for entry in scored:
        plan.append(str(entry["kind"]))
    return plan

func meeting_over() -> bool:
    return bool(stage_state().get("meeting_over", false)) or phase != "MEETING"

func meeting_moment() -> Dictionary:
    return Dictionary(stage_state().get("meeting_moment", {})).duplicate(true)

# Plays the next argument in the room and pauses after it, so the explorer can
# step in where it matters. Returns the lines it added.
func meeting_continue() -> Array:
    var state := stage_state()
    if phase != "MEETING" or bool(state.get("meeting_over", false)):
        return []
    var start := meeting_feed.size()
    _close_argument()
    var plan: Array = state.get("meeting_plan", [])
    state["meeting_moment"] = {}
    var played := false
    while not plan.is_empty() and int(state.get("meeting_played", 0)) < meeting_thread_budget():
        var kind := str(plan.pop_front())
        state["meeting_plan"] = plan
        if _play_thread(kind):
            state["meeting_played"] = int(state.get("meeting_played", 0)) + 1
            _begin_argument(start)
            played = true
            break
    state["meeting_plan"] = plan
    if not played:
        state["meeting_over"] = true
        state["meeting_moment"] = {}
        _meeting_closing()
    _refresh_npc_suspicion()
    _recompute_contradictions()
    changed.emit()
    return meeting_feed.slice(start)

# Everything left unsaid is said before the vote (bots, advance()).
func _finish_meeting() -> void:
    var guard := 0
    while not meeting_over() and guard < 12:
        guard += 1
        meeting_continue()

func _set_moment(kind: String, data: Dictionary) -> void:
    var moment := data.duplicate(true)
    moment["kind"] = kind
    stage_state()["meeting_moment"] = moment

func _begin_argument(start: int) -> void:
    var state := stage_state()
    var arcs: Array = state.get("meeting_arcs", [])
    var moment := meeting_moment()
    if moment.is_empty():
        return
    arcs.append({"day": day, "start": start, "subject": str(moment.get("subject", "")),
        "ref": str(moment.get("ref", "")), "kind": str(moment.get("kind", "")), "status": "unresolved", "closed": false})
    state["meeting_arcs"] = arcs

func _close_argument() -> void:
    var arcs: Array = stage_state().get("meeting_arcs", [])
    if arcs.is_empty() or bool(arcs.back().get("closed", false)):
        return
    var arc: Dictionary = arcs.back()
    arc["end"] = meeting_feed.size()
    arc["closed"] = true
    var ref := str(arc.get("ref", ""))
    var subject := str(arc.get("subject", ""))
    var status := "unresolved"
    if bool(stage_state().get("refuted_frames", {}).get(ref, false)):
        status = "contradicted"
    for item in current_packet().get("fragments", []):
        if str(item.get("refutes", "")) == subject and contested_state(str(item.get("id", ""))) == "settled":
            status = "contradicted"
    if bool(stage_state().get("confessions", {}).get(subject, {}).get("public", false)):
        status = "weakened"
    arc["status"] = status
    # The concrete unresolved statements stay in the feed. No suspicion score.

# Short questions about the point on the table (1.0): where a record came
# from, what exactly a witness saw, when, who told whom, whether the people
# someone names agree. They add no weight of their own; they make the room say
# what it knows aloud, which is what lets a problem count. Three per Day.
func clarification_options() -> Array:
    if phase != "MEETING" or meeting_over() or outcome != "" or int(stage_state().get("clarifications_left", 3)) <= 0:
        return []
    var moment := meeting_moment()
    if moment.is_empty() or bool(moment.get("clarified", false)):
        return []
    var options: Array = []
    var ref := str(moment.get("ref", ""))
    var item := fragment(ref)
    var owner := str(item.get("owner", ""))
    if not item.is_empty() and AstraKnowledgeModel.is_public(flags, ref) and is_alive(owner):
        match str(item.get("type", "")):
            "SYSTEM_RECORD":
                options.append({"ref": "source:" + ref, "label": _josa_inline("%s에게 그 기록을 누가 처음 열어 봤는지 묻는다" % name_of(owner))})
                options.append({"ref": "time:" + ref, "label": "기록의 시각과 사건 시각을 나란히 놓아 본다"})
            "DIRECT_WITNESS", "NULL_DECEPTION":
                options.append({"ref": "seen:" + ref, "label": _josa_inline("%s에게 정확히 무엇을 봤는지 묻는다 — 얼굴인지, 옷이나 태그인지" % name_of(owner))})
                options.append({"ref": "time:" + ref, "label": "본 시각과 사건 시각을 맞춰 본다"})
            "HEARSAY":
                options.append({"ref": "via:" + ref, "label": _josa_inline("%s에게 누구에게서 들은 말인지 묻는다" % name_of(owner))})
    var subject := str(moment.get("subject", ""))
    var members: Array = moment.get("members", [])
    if subject == "" and members.size() >= 2:
        subject = str(members[0])
    if is_alive(subject) and public_claims.has(subject):
        var mates: Array = []
        for mate in current_claim(subject).get("companions", []):
            if is_alive(str(mate)):
                mates.append(str(mate))
        if not mates.is_empty():
            options.append({"ref": "mates:" + subject, "label": _josa_inline("%s|i 함께 있었다는 %s에게 직접 확인한다" % [name_of(subject), names_of(mates)])})
        else:
            options.append({"ref": "claim:" + subject, "label": _josa_inline("%s의 설명과 남은 의문을 짚는다" % name_of(subject))})
    if str(moment.get("kind", "")) == "benign" and is_alive(subject):
        options.append({"ref": "motive:" + subject, "label": _josa_inline("%s에게 그 일이 사건과 관계있는지만 묻는다" % name_of(subject))})
    for option in options:
        option["kind"] = "clarify"
        option["tone"] = "calm"
    return options.slice(0, 3)

func _clarify_argument(ref: String) -> Dictionary:
    var legal := false
    for option in clarification_options():
        legal = legal or str(option["ref"]) == ref
    if not legal:
        return {"ok": false}
    var start := meeting_feed.size()
    var moment := meeting_moment()
    var subject := str(moment.get("subject", ""))
    var topic := "review:" + ref
    var mode := ref.get_slice(":", 0)
    var arg := ref.substr(mode.length() + 1)
    _feed_line("player", subject, _voice("clarify", "잠깐, 확인된 말과 아직 추측인 부분을 나눠 볼게요."), "player", "clarify", topic)
    var banmal := func(id: String) -> bool: return id in BANMAL_SPEAKERS
    match mode:
        "source":
            var item := fragment(arg)
            var owner := str(item.get("owner", ""))
            _feed_line(owner, subject, ("내가 직접 연 원본이야. “%s”" if banmal.call(owner) else "제가 직접 연 원본이에요. “%s”") % str(item.get("text", "")), "record", "clarify", topic)
            var backup := str(item.get("backup", ""))
            if backup != "" and backup != owner and is_alive(backup):
                _feed_line(backup, subject, "사본도 같아. 고친 흔적은 없어." if banmal.call(backup) else "사본도 같아요. 고친 흔적은 없어요.", "record", "support", topic)
                var sourced: Dictionary = stage_state().get("sourced", {})
                sourced[arg] = day
                stage_state()["sourced"] = sourced
        "time":
            var item := fragment(arg)
            var at := str(item.get("time", ""))
            var gap := absi(_minutes(at) - _minutes(incident_time()))
            _feed_narration("%s의 시각은 %s, 사건은 %s. %s" % [_evidence_name(item), at, incident_time(),
                "같은 시각이다." if gap <= 1 else ("%d분 차이. 그 사이에 자리를 옮길 수 있었는지가 남는다." % gap)])
        "seen":
            var item := fragment(arg)
            var owner := str(item.get("owner", ""))
            var specific := bool(item.get("specific", false))
            var who := str(item.get("subject", ""))
            if specific and who != "":
                _feed_line(owner, who, ("%s어. 얼굴까지 봤어." if banmal.call(owner) else "%s어요. 얼굴까지 봤어요.") % AstraJosa.ieot(name_of(who)), "dispute", "response", topic)
            else:
                _feed_line(owner, "", "얼굴은 못 봤어. 옷하고 태그만." if banmal.call(owner) else "얼굴은 못 봤어요. 옷하고 태그만요.", "record", "response", topic)
        "via":
            var item := fragment(arg)
            var owner := str(item.get("owner", ""))
            var via := str(item.get("via", ""))
            _feed_line(owner, via, _josa_inline(("%s한테 들은 거야. 내가 본 건 아니야." if banmal.call(owner) else "%s에게 들은 거예요. 제가 본 건 아니에요.") % name_of(via)), "record", "response", topic)
        "mates":
            subject = arg
            var claim := current_claim(subject)
            for mate in claim.get("companions", []):
                if not is_alive(str(mate)):
                    continue
                var mate_claim := current_claim(str(mate))
                var params := {"pos": room_name(str(mate_claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mate_claim.get("companions", [])))}
                _feed_npc(str(mate), "m_alibi_with" if not Array(mate_claim.get("companions", [])).is_empty() else "m_alibi_alone", params, "alibi", "", "response", topic)
                if _visible_conflict(subject, _claim_visible("", subject), str(mate), _claim_visible("", str(mate))) != "":
                    _raise_pair(subject, str(mate))
                    _mark_public_conflict("contrast:%s:%s" % [subject, mate], [subject, str(mate)], "%s|wa %s의 진술은 동시에 맞을 수 없다." % [name_of(subject), name_of(str(mate))])
                else:
                    var held: Dictionary = stage_state().get("held_firm", {})
                    held[subject] = day
                    stage_state()["held_firm"] = held
        "motive":
            subject = arg
            _feed_social(subject, "m_deflect", {}, "defense", subject, "response", topic)
        _:
            subject = arg
            var claim := current_claim(subject)
            var mates: Array = claim.get("companions", [])
            var alibi := AstraDialogue.line(subject, "m_alibi_with" if not mates.is_empty() else "m_alibi_alone",
                {"pos": room_name(str(claim.get("position", ""))), "mates": names_of(mates)}, 0)
            _feed_line(subject, subject, alibi, "defense", "response", topic)
            if mates.is_empty():
                _feed_line(subject, subject, AstraSocialLines.review_line(subject, 1), "defense", "response", topic)
    # One listener states their own knowledge-based reservation, not a global
    # answer. suspicion_breakdown(public_only) prevents private evidence leaks.
    var listener := _first_active(["noa", "dax", "vale", "mira", "eli", "rho", "sena", "lyra"], [subject])
    if listener != "" and subject != "":
        var view := suspicion_breakdown(listener, subject, true)
        var reason := _reason_text_for(listener, view.get("reasons", []))
        if reason != "":
            _feed_social(listener, "m_basis", {"target": name_of(subject), "reason": reason}, "react", subject, "close", topic)
    stage_state()["meeting_moment"]["clarified"] = true
    stage_state()["clarifications_left"] = int(stage_state().get("clarifications_left", 3)) - 1
    var arcs: Array = stage_state().get("meeting_arcs", [])
    if not arcs.is_empty():
        arcs.back()["clarified"] = true
        arcs.back()["review_subject"] = subject
    _recompute_contradictions()
    changed.emit()
    return {"ok": true, "lines": meeting_feed.slice(start), "shifts": []}

func _minutes(clock: String) -> int:
    var parts := clock.split(":")
    if parts.size() < 2:
        return 0
    return int(parts[0]) * 60 + int(parts[1])

# Where each person stands on the board today, in words (1.0 meeting board):
# never a score, only what has been said and shown.
func board_status(npc_id: String) -> Dictionary:
    var confession: Dictionary = stage_state().get("confessions", {}).get(npc_id, {})
    if bool(confession.get("public", false)) and int(confession.get("day", 0)) == day:
        return {"text": "사정이 설명됨", "tone": "explained"}
    for entry in manual_contradictions:
        if int(entry.get("day", 0)) == day and npc_id in Array(entry.get("targets", [])):
            return {"text": "진술이 부딪힘", "tone": "conflict"}
    var pointed := ""
    var supported := false
    for item in current_packet().get("fragments", []):
        var id := str(item.get("id", ""))
        if not AstraKnowledgeModel.is_public(flags, id):
            continue
        var type := str(item.get("type", ""))
        if type in ["ALIBI_SUPPORT", "ROUTINE"] and str(item.get("supports", "")) == npc_id:
            supported = true
        if npc_id in Array(item.get("points_to", [])):
            var group := Array(item.get("points_to", [])).size()
            if type == "SYSTEM_RECORD":
                pointed = "기록이 가리킴" if group == 1 else "기록의 후보 %d명 중" % group
            elif type == "HEARSAY" and pointed == "":
                pointed = "전언에 나옴"
            elif pointed == "":
                pointed = "목격에 나옴" if group == 1 else "목격의 후보 %d명 중" % group
    if pointed != "":
        return {"text": pointed, "tone": "pointed"}
    if supported:
        return {"text": "기록이 뒷받침", "tone": "supported"}
    if int(stage_state().get("held_firm", {}).get(npc_id, 0)) == day:
        return {"text": "다시 물어도 같음", "tone": "supported"}
    return {"text": "아직 확인 전", "tone": "open"}

# What the room carries into the vote, said plainly: what fits, what was
# explained, what is still open, and where people actually split.
func meeting_summary() -> Array:
    var lines: Array = []
    var said := 0
    for conflict in manual_contradictions:
        if int(conflict.get("day", 0)) == day and str(conflict.get("kind", "")) == "public":
            lines.append("부딪힌 말 · " + _josa_inline(str(conflict.get("detail", ""))))
            said += 1
            if said == 2:
                break
    for npc_id in living_ids():
        var confession: Dictionary = stage_state().get("confessions", {}).get(str(npc_id), {})
        if bool(confession.get("public", false)) and int(confession.get("day", 0)) == day:
            lines.append(_josa_inline("설명된 것 · %s의 엇갈린 말은 사건과 다른 사정 때문이었다." % name_of(str(npc_id))))
    for item in current_packet().get("fragments", []):
        var points: Array = Array(item.get("points_to", [])).filter(func(x): return is_alive(str(x)))
        if AstraKnowledgeModel.is_public(flags, str(item.get("id", ""))) and points.size() >= 2 and str(item.get("type", "")) in ["SYSTEM_RECORD", "DIRECT_WITNESS"]:
            lines.append(_josa_inline("아직 열린 것 · %s|i 가리키는 사람은 %s. 한 사람으로 좁혀지지 않았다." % [_evidence_name(item), names_of(points)]))
            break
    if said == 0 and lines.is_empty():
        lines.append("아직 누구의 말도 서로 부딪히지 않았다. 확인된 것보다 짐작이 더 많다.")
    var tally := {}
    var pool := eligible_vote_targets()
    for voter in eligible_voters():
        var target := str(_vote_target_for(str(voter), pool).get("target", ""))
        if target != "":
            tally[target] = int(tally.get(target, 0)) + 1
    var ranked: Array = tally.keys()
    ranked.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
    if ranked.size() >= 2 and int(tally[ranked[1]]) >= 2:
        lines.append(_josa_inline("갈리는 곳 · 방은 %s|wa %s 사이에서 나뉘어 있다." % [name_of(str(ranked[0])), name_of(str(ranked[1]))]))
    elif not ranked.is_empty():
        lines.append(_josa_inline("기우는 곳 · 방은 %s 쪽으로 기울어 있다. 확신이라기보다는 흐름이다." % name_of(str(ranked[0]))))
    return lines

func _meeting_closing() -> void:
    for line in meeting_summary():
        _feed_narration(str(line))
    _feed_narration("여기까지 확인한 말로 판단해야 한다. 지목받은 사람들의 마지막 말을 듣고, 오늘 격리할 한 사람을 정한다.")

# The explorer's own reason for a ballot (1.0): chosen from what they actually
# know, or plain instinct. Stored with the Day; never graded.
func ballot_reasons(target: String) -> Array:
    var reasons: Array = []
    for entry in stage_state().get("links", []):
        if int(entry.get("day", 0)) == day and str(entry.get("result", "")) == "CONTRADICTION" and target in Array(entry.get("targets", [])):
            reasons.append({"code": "link", "text": str(entry.get("why", ""))})
    for conflict in contradictions:
        if target in Array(conflict.get("targets", [])) and reasons.size() < 3:
            reasons.append({"code": "conflict", "text": str(conflict.get("detail", ""))})
    var view := suspicion_breakdown("player", target)
    for reason in view.get("reasons", []):
        if reasons.size() >= 4:
            break
        var item := fragment(str(reason.get("source", "")))
        if float(reason.get("weight", 0.0)) > 0.05 and not item.is_empty():
            var text := "%s: %s" % [_evidence_name(item), _short_text(str(item.get("text", "")))]
            var dup := false
            for existing in reasons:
                dup = dup or str(existing["text"]) == text
            if not dup:
                reasons.append({"code": "evidence", "text": _josa_inline(text)})
    reasons.append({"code": "instinct", "text": "아직 강한 근거는 없다. 직감에 가깝다."})
    return reasons

func set_ballot_reason(target: String, index: int) -> bool:
    var options := ballot_reasons(target)
    if index < 0 or index >= options.size():
        return false
    var reasons: Dictionary = stage_state().get("ballot_reasons", {})
    reasons[str(day)] = {"target": target, "code": str(options[index]["code"]), "text": str(options[index]["text"])}
    stage_state()["ballot_reasons"] = reasons
    AstraDecisionModel.append_trace(flags, AstraDecisionModel.trace("player", "ballot_reason", target,
        [AstraDecisionModel.reason(str(options[index]["code"]), 1.0, str(options[index]["text"]))], day))
    changed.emit()
    return true

func ballot_reason(day_index: int = -1) -> Dictionary:
    return Dictionary(stage_state().get("ballot_reasons", {}).get(str(day if day_index < 0 else day_index), {}))

func _add_accusation(speaker: String, target: String, weight: float = 1.0) -> void:
    var entry := {"day": day, "speaker": speaker, "target": target, "weight": weight}
    if speaker == "player":
        entry["player_derived"] = true
        # Retain only fragment ids that actually contribute positive evidence to
        # this target. This avoids treating unrelated facts the explorer happens
        # to know as the basis for an accusation.
        var known_ids := {}
        for item in known_fragments():
            known_ids[str(item.get("id", ""))] = true
        var basis_facts: Array = []
        var view := suspicion_breakdown("player", target)
        for reason in view.get("reasons", []):
            if float(reason.get("weight", 0.0)) <= 0.0:
                continue
            var source := str(reason.get("source", ""))
            if known_ids.has(source) and source not in basis_facts:
                basis_facts.append(source)
        entry["basis_facts"] = basis_facts
    stage_state()["public_accusations"].append(entry)

func _add_defense(speaker: String, target: String) -> void:
    stage_state()["public_defenses"].append({"day": day, "speaker": speaker, "target": target})

func _play_thread(kind: String) -> bool:
    match kind:
        "record": return _thread_record()
        "witness": return _thread_witness()
        "frame": return _thread_frame()
        "benign": return _thread_benign()
        "callback": return _thread_callback()
        "accuse": return _thread_accusation()
        "hearsay": return _thread_hearsay()
        "shield": return _thread_shield()
        "claims": return _thread_claims()
    return false

# The shield turned an attack away last night (§39). The one who was targeted
# asks why; someone may doubt what the shield really caught: a Null that
# deflects likes that doubt, a sceptic may voice it too. A saved life is a
# new question for the room, not a free answer.
func _thread_shield() -> bool:
    if int(stage_state().get("shield_thread_day", 0)) == day:
        return false
    var night: Dictionary = stage_state().get("night_log", []).back() if not stage_state().get("night_log", []).is_empty() else {}
    var attacked := str(night.get("attacked", ""))
    if not bool(night.get("protected", false)) or attacked in ["", "player"] or not is_alive(attacked):
        return false
    stage_state()["shield_thread_day"] = day
    var topic := "shield:" + attacked
    _feed_social(attacked, "m_why_me", {}, "react", attacked, "anchor", topic)
    var doubter := ""
    for null_id in living_null_ids():
        if str(null_id) != attacked and null_style(str(null_id)) in ["DEFLECTOR", "COUNTERATTACK"] and _pick("doubtshield:%s:%d" % [null_id, day]) < 0.5:
            doubter = str(null_id)
            break
    if doubter == "" and _pick("doubtshield:sceptic:%d" % day) < 0.2:
        doubter = _first_active(["dax", "sena", "eli"], [attacked])
    if doubter != "":
        _feed_social(doubter, "m_doubt_shield", {}, "dispute", attacked, "challenge", topic)
        _add_accusation(doubter, attacked, 0.3)
        _vouch_on_character(attacked, [doubter], topic)
    _set_moment("shield", {"subject": attacked, "speaker": doubter})
    return true

# Someone retells what another person saw. The one who actually saw it may be
# in the room: they confirm it, correct a detail that changed on the way, or
# say nothing. Asking the source directly is the explorer's move (§8, §73).
const SOURCE_SPEAKS := {"sena": 0.7, "rho": 0.65, "lyra": 0.6, "mira": 0.55, "dax": 0.5, "eli": 0.45, "noa": 0.45, "vale": 0.35}

func _thread_hearsay() -> bool:
    for item in current_packet().get("fragments", []):
        var id := str(item.get("id", ""))
        if str(item.get("type", "")) != "HEARSAY" or AstraKnowledgeModel.is_public(flags, id):
            continue
        var owner := str(item.get("owner", ""))
        if not is_alive(owner) or crew[owner].is_null():
            continue
        var original := _hearsay_source(item)
        if not original.is_empty() and AstraKnowledgeModel.is_public(flags, str(original.get("id", ""))) and not bool(item.get("distorted", false)):
            continue
        var told := player_knows(id)
        var chance := 0.92 if told else float(MEETING_SHARE.get(owner, 0.6)) * UNASKED_SHARE * 1.6
        if _pick("heard:" + id) >= chance:
            continue
        _publish_fragment(item, owner)
        var specific := bool(item.get("specific", false))
        _feed_social(owner, "m_heard_named" if specific else "m_heard", _fragment_params(item), "dispute", str(item.get("subject", "")), "anchor", "hearsay:" + id)
        var via := str(item.get("via", ""))
        var members: Array = []
        for member_id in item.get("points_to", []):
            if is_alive(str(member_id)):
                members.append(str(member_id))
        if not original.is_empty() and is_alive(via):
            var already := AstraKnowledgeModel.is_public(flags, str(original.get("id", "")))
            # Unasked, a witness rarely notices their words came back changed;
            # asked directly (the explorer's move), they always answer.
            var speak := 0.9 if already else float(SOURCE_SPEAKS.get(via, 0.5)) * 0.45
            if _pick("source:" + id) < speak:
                _source_answers(item, original, via)
        _set_moment("hearsay", {"ref": id, "via": via, "owner": owner, "subject": str(item.get("subject", "")), "members": members})
        return true
    return false

# The sighting a retold one came from: the same Day, the same witness.
func _hearsay_source(item: Dictionary) -> Dictionary:
    var via := str(item.get("via", ""))
    var packet: Dictionary = stage_state().get("packets", {}).get(str(item.get("day", day)), {})
    for other in packet.get("fragments", []):
        if str(other.get("type", "")) == "DIRECT_WITNESS" and str(other.get("owner", "")) == via:
            return other
    return {}

func _source_answers(item: Dictionary, original: Dictionary, via: String) -> void:
    var topic := "hearsay:" + str(item.get("id", ""))
    _publish_fragment(original, via)
    if bool(item.get("distorted", false)):
        _feed_social(via, "m_source_correct", _witness_params(original, via), "record", "", "challenge", topic)
        var noter := _first_active(["noa", "vale", "dax", "mira"], [via, str(item.get("owner", ""))])
        if noter != "":
            _feed_social(noter, "m_note_relay", {"a": name_of(str(item.get("owner", ""))), "b": name_of(via)}, "react", "", "followup", topic)
        stats["relay_corrections"] = int(stats.get("relay_corrections", 0)) + 1
    else:
        _feed_social(via, "m_source_confirm", {}, "record", str(original.get("subject", "")), "support", topic)

func _share_roll(npc_id: String, key: String, base: Dictionary) -> bool:
    var chance := float(base.get(npc_id, 0.6))
    return _pick("share:%s:%s" % [npc_id, key]) < chance

func _thread_record() -> bool:
    for item in current_packet().get("fragments", []) + _recovered_today():
        var id := str(item.get("id", ""))
        if str(item.get("type", "")) != "SYSTEM_RECORD" or AstraKnowledgeModel.is_public(flags, id):
            continue
        var owner := _current_holder(item)
        if owner == "" or not is_alive(owner) or crew[owner].is_null() or log_unread(id):
            continue
        # What the explorer never drew out mostly stays with its keeper; what
        # they already heard, the keeper is ready to stand behind in public.
        var told := player_knows(id)
        var share_chance := 0.94 if told else float(MEETING_SHARE.get(owner, 0.6)) * UNASKED_SHARE
        if _pick("share:%s:%s" % [owner, id]) >= share_chance:
            continue
        _publish_fragment(item, owner)
        var params := _fragment_params(item)
        _feed_social(owner, _record_key(owner, item), params, "record", str(item.get("subject", "")), "anchor", "record:" + id)
        var subject := str(item.get("subject", ""))
        var members: Array = []
        if subject != "" and is_alive(subject):
            _respond_to_evidence(subject, item, "record:" + id)
        elif subject == "":
            for member_id in item.get("points_to", []):
                if is_alive(str(member_id)):
                    members.append(str(member_id))
            if not members.is_empty():
                var speaker := str(members[int(_pick(id + "grp") * members.size()) % members.size()])
                _feed_social(speaker, "m_group_answer", {"members": names_of(members)}, "defense", speaker, "response", "record:" + id)
            var cautioner := _first_active(["mira", "lyra", "vale", "dax"], [owner] + members)
            if cautioner != "":
                _feed_social(cautioner, "m_caution", {"target": names_of(members)}, "react", "", "clarify", "record:" + id)
        _set_moment("record", {"ref": id, "subject": subject, "members": members, "owner": owner})
        return true
    return false

func _recovered_today() -> Array:
    var result: Array = []
    for note in stage_state().get("recovered", []):
        if int(note.get("day", 0)) == day:
            var item := fragment(str(note.get("id", "")))
            if not item.is_empty():
                result.append(item)
    return result

func _current_holder(item: Dictionary) -> String:
    var owner := str(item.get("owner", ""))
    if is_alive(owner):
        return owner
    for note in stage_state().get("recovered", []):
        if str(note.get("id", "")) == str(item.get("id", "")) and is_alive(str(note.get("by", ""))):
            return str(note.get("by", ""))
    return ""

func _thread_witness() -> bool:
    for item in current_packet().get("fragments", []):
        var id := str(item.get("id", ""))
        if str(item.get("type", "")) != "DIRECT_WITNESS" or AstraKnowledgeModel.is_public(flags, id):
            continue
        var owner := str(item.get("owner", ""))
        if not is_alive(owner):
            continue
        var told := player_knows(id)
        var chance := 0.94 if told else float({"sena":0.85, "rho":0.8, "lyra":0.75, "mira":0.65, "dax":0.55, "eli":0.55, "noa":0.45, "vale":0.4}.get(owner, 0.6)) * UNASKED_SHARE * (0.5 if deep_modifier() == "STATIC" else 1.0)
        if _pick("witness:" + id) >= chance:
            continue
        _publish_fragment(item, owner)
        var params := _fragment_params(item)
        var specific := bool(item.get("specific", false))
        _feed_social(owner, "m_saw" if specific else "m_saw_group", _witness_params(item, owner), "dispute", str(item.get("subject", "")), "anchor", "witness:" + id)
        var subject := str(item.get("subject", ""))
        var members: Array = []
        if subject != "" and is_alive(subject):
            _respond_to_evidence(subject, item, "witness:" + id)
        else:
            for member_id in item.get("points_to", []):
                if is_alive(str(member_id)):
                    members.append(str(member_id))
        _set_moment("witness", {"ref": id, "subject": subject, "members": members, "owner": owner})
        return true
    return false

func _thread_frame() -> bool:
    for item in current_packet().get("fragments", []):
        var id := str(item.get("id", ""))
        if str(item.get("type", "")) != "NULL_DECEPTION" or AstraKnowledgeModel.is_public(flags, id):
            continue
        var framer := str(item.get("owner", ""))
        var scapegoat := str(item.get("subject", ""))
        if not is_alive(framer) or not is_alive(scapegoat):
            continue
        # 1.0's generic record/witness threads already make unasked sharing
        # rare, but frames accidentally bypassed that rule at a flat 85%.
        # ECHO_WARD therefore surfaced its most decisive accusation even when
        # the explorer never spoke to the witness. Keep the testimony eager
        # once the explorer has heard it; otherwise use the same temperament-
        # bounded unasked-sharing rule as other evidence.
        var told := player_knows(id)
        var share_chance := 0.94 if told else float(MEETING_SHARE.get(framer, 0.6)) * UNASKED_SHARE * 1.6
        if _pick("frame:" + id) >= share_chance:
            continue
        # The board is public: a Null does not stand up and claim to have seen
        # someone whose companion is sitting right there to deny it. Someone
        # honestly mistaken does not think that far.
        if not bool(item.get("mistaken", false)) and not Array(current_claim(scapegoat).get("companions", [])).is_empty():
            continue
        _publish_fragment(item, framer)
        _feed_social(framer, "m_saw", _fragment_params(item), "dispute", scapegoat, "anchor", "frame:" + id)
        _add_accusation(framer, scapegoat, 0.8)
        var claim := current_claim(scapegoat)
        _feed_social(scapegoat, "m_defend_alone", {"pos": room_name(str(claim.get("position", ""))), "target": name_of(framer)}, "defense", scapegoat, "response", "frame:" + id)
        _vouch_on_character(scapegoat, [framer], "frame:" + id)
        # The keeper of a record that places the scapegoat elsewhere does not
        # always connect it on their own. The explorer, who asked, can.
        var alibi := {}
        for other in current_packet().get("fragments", []):
            if str(other.get("type", "")) == "ALIBI_SUPPORT" and str(other.get("supports", "")) == scapegoat and is_alive(str(other.get("owner", ""))):
                alibi = other
                break
        if not alibi.is_empty() and not player_knows(str(alibi.get("id", ""))) and not log_unread(str(alibi.get("id", ""))) and _pick("keeper:" + id) < 0.22:
            _refute_frame(id, framer, scapegoat, alibi, str(alibi.get("owner", "")))
        else:
            var doubter := _first_active(["mira", "dax", "vale", "noa"], [framer, scapegoat])
            if doubter != "":
                _feed_social(doubter, "m_caution", {"target": name_of(scapegoat)}, "react", scapegoat, "clarify", "frame:" + id)
        _set_moment("frame", {"ref": id, "framer": framer, "subject": scapegoat, "alibi": str(alibi.get("id", ""))})
        return true
    return false

func _refute_frame(frame_id: String, framer: String, scapegoat: String, alibi: Dictionary, speaker: String) -> void:
    _publish_fragment(alibi, speaker)
    if speaker != "player":
        _feed_social(speaker, _record_key(speaker, alibi), _fragment_params(alibi), "record", scapegoat, "support", "frame:" + frame_id)
    var refuted_frames: Dictionary = stage_state().get("refuted_frames", {})
    refuted_frames[frame_id] = true
    stage_state()["refuted_frames"] = refuted_frames
    _weaken_accusation(framer, scapegoat, 0.1)
    if is_alive(framer):
        _feed_social(framer, "m_retreat", {"target": name_of(scapegoat)}, "defense", framer, "response", "frame:" + frame_id)
    var catcher := _first_active(["noa", "eli", "dax", "sena"], [framer, scapegoat])
    if catcher != "":
        _feed_social(catcher, "m_catch_lie", {"a": name_of(framer), "b": name_of(scapegoat)}, "dispute", framer, "challenge", "frame:" + frame_id)
    _mark_public_conflict("frame:" + frame_id, [framer], "%s|i 본 사람이 %s라면, %s|eun 그 시간 다른 곳에 있었다는 기록과 맞지 않는다." % [name_of(framer), name_of(scapegoat), name_of(scapegoat)])

# A keeper speaks of their own logs in their own words; a backup or shared log
# is named plainly by its device.
func _record_key(speaker: String, item: Dictionary) -> String:
    return "m_record" if str(AstraCrewCatalog.RECORD_DOMAIN.get(speaker, "")) == str(item.get("record_type", "")) else "m_record_other"

# "아까는" / "어제는" / "DAY 2에는" — how far back a quoted statement is.
func _when_text(said_day: int) -> String:
    if said_day >= day:
        return "아까는"
    if said_day == day - 1:
        return "어제는"
    return "DAY %d에는" % said_day

func _weaken_accusation(speaker: String, target: String, factor: float) -> void:
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("speaker", "")) == speaker and str(entry.get("target", "")) == target and int(entry.get("day", 0)) == day:
            entry["weight"] = float(entry.get("weight", 1.0)) * factor

# A friend speaks for someone on character, not on evidence (§23, §30). They
# can be wrong: a Null keeps its friends.
func _vouch_on_character(target: String, exclude: Array, topic: String) -> void:
    var friend := ""
    var best := 0.32
    for other in living_ids():
        if other == target or other in exclude:
            continue
        var value: float = crew[other].get_affinity(target)
        if crew[other].is_null() and not crew[target].is_null():
            continue
        if value > best:
            best = value
            friend = str(other)
    if friend == "":
        return
    _feed_social(friend, "m_vouch_character", {"target": name_of(target)}, "calm", target, "support", topic)
    _add_defense(friend, target)

func _thread_benign() -> bool:
    var benign: Dictionary = current_packet().get("benign", {})
    if benign.is_empty():
        return false
    var liar := str(benign.get("npc", ""))
    if not is_alive(liar):
        return false
    var claim := current_claim(liar)
    var exposer := ""
    for other in living_ids():
        if other == liar:
            continue
        var other_claim := current_claim(str(other))
        if liar in Array(other_claim.get("companions", [])) and str(other_claim.get("position", "")) != str(claim.get("position", "")):
            exposer = str(other)
            break
    if exposer == "":
        return false
    var caller := _first_active(["sena", "noa", "eli", "rho", "dax"], [liar])
    if caller == "":
        caller = exposer
    if exposer in ["sena", "noa", "eli", "rho", "dax"] or _pick("benign_caller:" + liar) < 0.5:
        caller = exposer
    _feed_social(caller, "m_benign_callout_self" if caller == exposer else "m_benign_callout", {"target": name_of(liar), "mate": name_of(exposer), "pos": room_name(str(claim.get("position", "")))}, "dispute", liar, "anchor", "benign:" + liar)
    _add_accusation(caller, liar, 0.6)
    _raise_pair(liar, exposer)
    _mark_public_conflict("benign:" + liar, [liar], "%s|eun %s에 있었다고 했지만, %s|eun 그 시간 %s|wa 함께 있었다고 한다." % [name_of(liar), room_name(str(claim.get("position", ""))), name_of(exposer), name_of(liar)])
    if _confessed_today(liar) and _pick("benign_self:" + liar) < 0.5:
        _publish_confession(liar)
    else:
        _feed_social(liar, "m_deflect", {}, "defense", liar, "response", "benign:" + liar)
        crew[liar].adjust_stress(0.1)
        var cautioner := _first_active(["mira", "lyra"], [liar, caller])
        if cautioner != "":
            _feed_social(cautioner, "m_caution", {"target": name_of(liar)}, "react", liar, "clarify", "benign:" + liar)
    _set_moment("benign", {"subject": liar, "caller": caller})
    return true

func _publish_confession(npc_id: String) -> void:
    var confessions: Dictionary = stage_state().get("confessions", {})
    var entry: Dictionary = confessions.get(npc_id, {})
    if entry.is_empty():
        return
    entry["public"] = true
    confessions[npc_id] = entry
    stage_state()["confessions"] = confessions
    _feed_social(npc_id, "m_confess_public", {"pos": room_name(str(entry.get("position", "")))}, "defense", npc_id, "response", "benign:" + npc_id)
    _feed_line(npc_id, "", AstraSocialLines.secret(npc_id, str(entry.get("reason", "")), room_name(str(entry.get("position", "")))), "defense", "followup", "benign:" + npc_id)
    for accusation in stage_state().get("public_accusations", []):
        if str(accusation.get("target", "")) == npc_id and int(accusation.get("day", 0)) == day:
            accusation["weight"] = float(accusation.get("weight", 1.0)) * 0.3

func _thread_callback() -> bool:
    if day <= 1:
        return false
    var speaker := _first_active(["noa", "eli", "dax", "vale"], [])
    if speaker == "":
        return false
    for target in living_ids():
        if target == speaker:
            continue
        for conflict in AstraClaimLedger.self_conflicts(claim_ledger, str(target)):
            var a: Dictionary = conflict.get("a", {})
            var b: Dictionary = conflict.get("b", {})
            if bool(stage_state().get("callbacks", {}).get(str(target) + str(a.get("index", 0)), false)):
                continue
            # Only statements this speaker could have heard: public ones.
            if str(a.get("scope", "")) != AstraClaimLedger.SCOPE_PUBLIC and str(b.get("scope", "")) != AstraClaimLedger.SCOPE_PUBLIC:
                continue
            var callbacks: Dictionary = stage_state().get("callbacks", {})
            callbacks[str(target) + str(a.get("index", 0))] = true
            stage_state()["callbacks"] = callbacks
            _feed_social(speaker, "m_callback", {"target": name_of(str(target)), "old": room_name(str(a.get("position", ""))), "new": room_name(str(b.get("position", ""))), "day": int(a.get("day", 1)), "when": _when_text(int(a.get("day", 1)))}, "record", str(target), "anchor", "callback:" + str(target))
            _feed_social(str(target), "m_deny", {}, "defense", str(target), "response", "callback:" + str(target))
            _add_accusation(speaker, str(target), 0.6)
            _set_moment("callback", {"subject": str(target), "speaker": speaker})
            return true
    # Yesterday's decision is also on the table: who pushed it, and the fact
    # that the ship is still under attack.
    var rounds: Array = stage_state().get("vote_rounds", [])
    if rounds.is_empty():
        return false
    var last_round: Dictionary = rounds[rounds.size() - 1]
    var isolated := str(last_round.get("isolated", ""))
    if isolated == "" or int(last_round.get("day", 0)) != day - 1:
        return false
    var reflective := _first_active(["mira", "lyra", "vale", "noa"], [])
    if reflective == "":
        return false
    _feed_social(reflective, "m_yesterday", {"target": name_of(isolated)}, "react", isolated, "anchor", "callback:vote")
    var hard := _first_active(["sena", "rho", "eli"], [reflective])
    if hard != "":
        _feed_social(hard, "m_forward", {"target": name_of(isolated)}, "react", "", "response", "callback:vote")
    # Whoever pushed yesterday's wrong call is now the one people look at.
    var pushers := {}
    for voter in Dictionary(last_round.get("ballots", {})):
        if str(last_round["ballots"][voter]) == isolated and str(voter) != "player" and is_alive(str(voter)):
            pushers[str(voter)] = true
    _set_moment("yesterday", {"subject": isolated, "pushers": pushers.keys()})
    return true

func _thread_accusation() -> bool:
    var best_speaker := ""
    var best_target := ""
    var best_value := 0.18
    var best_reason := ""
    for speaker in living_ids():
        if bool(accused_today.get("by:" + str(speaker), false)):
            continue
        var member: AstraCrewMember = crew[speaker]
        if member.is_null() and null_style(str(speaker)) == "QUIET":
            continue
        var top := top_suspect_of(str(speaker))
        var target := str(top.get("target", ""))
        if member.is_null():
            # A Null picks one person to steer the room toward and keeps at it.
            var goat := null_scapegoat(str(speaker))
            if goat != "":
                target = goat
                top = suspicion_breakdown(str(speaker), goat, true)
                top["value"] = float(top.get("score", 0.0)) + 0.18
        if target == "" or accused_today.has(target):
            continue
        var value := float(top.get("value", 0.0)) + _pick("acc:" + str(speaker)) * 0.04
        if member.is_null():
            # On a careful first morning a Null does not lead the accusations
            # unless someone has already come at it.
            if meeting_temperature() == "low" and _stood_against(target, str(speaker)) <= 0.0:
                continue
            # Nobody has named anyone yet today: a Null waits for the room
            # unless it is being pushed, or has a public reason it can point to.
            var first_today := true
            for entry in stage_state().get("public_accusations", []):
                if int(entry.get("day", 0)) == day:
                    first_today = false
                    break
            if first_today and _stood_against(target, str(speaker)) <= 0.0 and value < 0.42:
                continue
            match null_style(str(speaker)):
                "COUNTERATTACK":
                    value += 0.12 + 0.4 * _stood_against(target, str(speaker))
                "DEFLECTOR":
                    value += 0.1
                "ALLY":
                    value += 0.04
        else:
            # Nobody names a colleague aloud without being fairly sure; the
            # careful need more than the quick (§11), and a quiet first
            # morning makes everyone slower to say it.
            var need := conviction_need(str(speaker)) * (0.95 if meeting_temperature() == "low" else 0.8)
            if value < need:
                continue
            # A strong private hunch is enough to vote on, not enough to turn
            # into a collective accusation. The room needs an independent
            # source, a contradiction somebody actually raised, a validating
            # Link, or testimony the explorer deliberately heard from this
            # speaker. Retellings of the same witness do not count twice.
            if not _collective_accusation_ready(str(speaker), target):
                continue
            value += (0.4 - AstraDecisionModel.judgement(str(speaker), "conviction")) * 0.5
        if value > best_value:
            best_value = value
            best_speaker = str(speaker)
            best_target = target
            best_reason = _reason_text_for(str(speaker), top.get("reasons", []))
    if best_speaker == "":
        return false
    accused_today[best_target] = true
    accused_today["by:" + best_speaker] = true
    var with_evidence := false
    # An honest accuser says what they actually hold (§28): the sighting or the
    # log goes on the table with the name.
    if not crew[best_speaker].is_null():
        for item in current_packet().get("fragments", []):
            var fid := str(item.get("id", ""))
            if str(item.get("owner", "")) != best_speaker or AstraKnowledgeModel.is_public(flags, fid) or best_target not in Array(item.get("points_to", [])):
                continue
            var key := ""
            match str(item.get("type", "")):
                "DIRECT_WITNESS": key = "m_saw" if bool(item.get("specific", false)) else "m_saw_group"
                "SYSTEM_RECORD": key = _record_key(best_speaker, item)
                "BENIGN_EXPOSURE", "COVER_EXPOSURE": key = "saw_at"
            if key == "":
                continue
            _publish_fragment(item, best_speaker)
            _feed_social(best_speaker, key, _witness_params(item, best_speaker), "dispute", best_target, "anchor", "suspicion:" + best_target)
            with_evidence = true
            break
    _add_accusation(best_speaker, best_target, 1.0)
    _feed_social(best_speaker, "m_accuse", {"target": name_of(best_target), "reason": best_reason}, "suspect", best_target, "followup" if with_evidence else "anchor", "suspicion:" + best_target)
    var claim := current_claim(best_target)
    var mates: Array = []
    for mate in claim.get("companions", []):
        if is_alive(str(mate)):
            mates.append(str(mate))
    _feed_social(best_target, "m_defend_self" if not mates.is_empty() else "m_defend_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates)), "target": name_of(best_speaker)}, "defense", best_target, "response", "suspicion:" + best_target)
    var ally := ""
    var ally_value := 0.25
    for other in living_ids():
        if other in [best_speaker, best_target]:
            continue
        var value := float(suspicion_breakdown(str(other), best_target, crew[other].is_null()).get("score", 0.0))
        if value > ally_value:
            ally_value = value
            ally = str(other)
    # A Null's partner keeps its distance unless the accusation is weak.
    if ally != "" and crew[ally].is_null() and crew[best_target].is_null():
        ally = ""
    if ally != "":
        _feed_social(ally, "m_agree", {"target": name_of(best_target)}, "react", best_target, "support", "suspicion:" + best_target)
        _add_accusation(ally, best_target, 0.5)
    else:
        _vouch_on_character(best_target, [best_speaker], "suspicion:" + best_target)
    _set_moment("accuse", {"speaker": best_speaker, "subject": best_target})
    return true

func _evidence_origin(item: Dictionary) -> String:
    if item.is_empty():
        return ""
    var type := str(item.get("type", ""))
    if type == "HEARSAY":
        var original := _hearsay_source(item)
        if not original.is_empty():
            return "witness:" + str(original.get("owner", ""))
        return "witness:" + str(item.get("via", ""))
    if type in ["DIRECT_WITNESS", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
        return "witness:" + str(item.get("owner", ""))
    if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
        return "record:%s:%s:%s" % [str(item.get("record_type", "")), str(item.get("time", "")), str(item.get("room", ""))]
    if type == "EXPERT_INFERENCE":
        return "expert:" + str(item.get("owner", ""))
    return "fact:" + str(item.get("id", ""))

func _collective_accusation_ready(speaker: String, target: String) -> bool:
    # A player-raised Link is already explicit verification in the room.
    for entry in stage_state().get("links", []):
        if int(entry.get("day", 0)) == day and str(entry.get("result", "")) == "CONTRADICTION" and target in Array(entry.get("targets", [])):
            return true
    # A contradiction only counts after somebody actually said it aloud.
    for other in living_ids():
        if str(other) != target and _conflict_raised(target, str(other)):
            return true

    var view := suspicion_breakdown(speaker, target)
    var origins := {}
    var player_heard := false
    for reason in view.get("reasons", []):
        if float(reason.get("weight", 0.0)) <= 0.0:
            continue
        var code := str(reason.get("code", ""))
        if code not in ["HARD_RECORD", "DIRECT_WITNESS", "TIMELINE", "EXPERT_INFERENCE", "CHANGED_STORY", "FALSE_SIGHTING"]:
            continue
        var source := str(reason.get("source", ""))
        var item := fragment(source)
        if item.is_empty():
            continue
        var origin := _evidence_origin(item)
        if origin != "":
            origins[origin] = true
        if str(item.get("owner", "")) == speaker and player_knows(source) and conversation_open(speaker):
            player_heard = true
    return player_heard or origins.size() >= 2

func _lone_private_conviction(speaker: String, target: String) -> bool:
    # Kept as a compatibility helper for tests/debug callers. A conviction is
    # "lone/private" exactly when it is not ready to become a room accusation.
    return not _collective_accusation_ready(speaker, target)

func _first_reason_code(reasons: Array) -> String:
    for item in reasons:
        if float(item.get("weight", 0.0)) > 0.0:
            return str(item.get("code", ""))
    return "accumulated_behavior"

# The named person answers a record or a sighting in public.
func _respond_to_evidence(subject: String, item: Dictionary, topic: String) -> void:
    var role := _day_role(subject)
    var excuse := str(AstraStageStory.method(str(incident().get("method", ""))).get("excuse", "remote"))
    if role == "actor":
        if str(item.get("type", "")) == "SYSTEM_RECORD":
            _feed_social(subject, "m_excuse_" + excuse, {"room": room_name(str(item.get("room", "")))}, "defense", subject, "response", topic)
            var excuses: Dictionary = stage_state().get("public_excuses", {})
            var today: Dictionary = excuses.get(_day_key(), {})
            today[subject] = true
            excuses[_day_key()] = today
            stage_state()["public_excuses"] = excuses
            for other in current_packet().get("fragments", []):
                if str(other.get("type", "")) != "EXPERT_INFERENCE" or str(other.get("refutes", "")) != subject or not is_alive(str(other.get("owner", ""))):
                    continue
                var expert := str(other.get("owner", ""))
                # The expert speaks up if the explorer already asked them, or
                # by temperament.
                var chance := 0.9 if player_knows(str(other.get("id", ""))) else float(MEETING_SHARE.get(expert, 0.6)) * UNASKED_SHARE * 2.5
                if _pick("rebut:" + str(other.get("id", ""))) >= chance:
                    break
                _publish_fragment(other, expert)
                _feed_social(expert, "m_rebut", {"fact": str(other.get("text", ""))}, "record", subject, "challenge", topic)
                # A Null does not fold at the first expert: it finds a second
                # story, and the room cannot tell who is right (§24).
                if _pick("excuse_again:" + subject) < float(AstraDifficulty.number(difficulty, "null_persistence", 0.55)):
                    _feed_social(subject, "m_excuse_again", {"expert": name_of(expert), "room": room_name(str(item.get("room", "")))}, "defense", subject, "response", topic)
                    var contested: Dictionary = stage_state().get("contested", {})
                    contested[str(other.get("id", ""))] = "open"
                    stage_state()["contested"] = contested
                else:
                    var demander := _first_active(["sena", "rho", "eli"], [subject, expert])
                    if demander != "":
                        _feed_social(demander, "m_demand", {"target": name_of(subject)}, "suspect", subject, "followup", topic)
                        _add_accusation(demander, subject, 0.7)
                break
        else:
            _feed_social(subject, "m_deny", {}, "defense", subject, "response", topic)
            var cover := str(current_packet().get("cover", ""))
            if str(current_packet().get("cover_style", "")) == "mutual" and is_alive(cover):
                _feed_social(cover, "m_vouch", {"target": name_of(subject), "pos": room_name(str(current_claim(cover).get("position", "")))}, "calm", subject, "support", topic)
                var catcher := _first_active(["noa", "eli", "dax"], [subject, cover])
                if catcher != "":
                    _feed_social(catcher, "m_catch_lie", {"a": name_of(cover), "b": name_of(subject)}, "dispute", cover, "challenge", topic)
            else:
                _vouch_on_character(subject, [str(item.get("owner", ""))], topic)
    else:
        var claim := current_claim(subject)
        var mates: Array = []
        for mate in claim.get("companions", []):
            if is_alive(str(mate)):
                mates.append(str(mate))
        _feed_social(subject, "m_defend_self" if not mates.is_empty() else "m_defend_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates)), "target": name_of(str(item.get("owner", "")))}, "defense", subject, "response", topic)
        var vouched := false
        for mate in mates:
            if subject in Array(current_claim(mate).get("companions", [])):
                _feed_social(mate, "m_vouch", {"target": name_of(subject), "pos": room_name(str(current_claim(mate).get("position", "")))}, "calm", subject, "support", topic)
                vouched = true
                break
        if not vouched:
            _vouch_on_character(subject, [str(item.get("owner", ""))], topic)

func contested_state(fragment_id: String) -> String:
    return str(stage_state().get("contested", {}).get(fragment_id, ""))

func _record_player_contact(npc_id: String, action: String, fact_id: String = "") -> void:
    var contacts: Dictionary = stage_state().get("agency_contacts", {})
    var key := fact_id if fact_id != "" else ("claim:D%d:%s" % [day, npc_id])
    contacts[key] = {"day": day, "npc": npc_id, "action": action, "fact": fact_id}
    stage_state()["agency_contacts"] = contacts

func _agency_contact_for(fact_id: String) -> Dictionary:
    return Dictionary(stage_state().get("agency_contacts", {}).get(fact_id, {}))

func _agency_event(kind: String, data: Dictionary = {}) -> void:
    var events: Array = stage_state().get("agency_events", [])
    var entry := {"kind": kind, "day": day}
    entry.merge(data, true)
    events.append(entry)
    while events.size() > 160:
        events.pop_front()
    stage_state()["agency_events"] = events

func agency_metrics() -> Dictionary:
    var public_caused := 0
    var meeting_changed := 0
    var vote_changed := int(stage_state().get("agency_vote_changes", []).size())
    for raw in stage_state().get("agency_events", []):
        var event: Dictionary = raw
        match str(event.get("kind", "")):
            "public_fact":
                if bool(event.get("player_caused", false)):
                    public_caused += 1
            "meeting_shift":
                if bool(event.get("player_caused", false)):
                    meeting_changed += 1
    return {"player_caused_public_facts": public_caused, "player_caused_meeting_changes": meeting_changed,
        "player_caused_vote_changes": vote_changed}

func _publish_fragment(item: Dictionary, speaker: String) -> void:
    var id := str(item.get("id", ""))
    AstraKnowledgeModel.make_public(flags, id, active_participants(), day, speaker)
    if id not in stage_state().get("public_presented", []):
        stage_state()["public_presented"].append(id)
    var public_log: Array = stage_state().get("public_log", [])
    var contact := _agency_contact_for(id)
    # "Player-caused" means an explicit conversation contact exposed this fact,
    # or the explorer personally presented it. Merely knowing a fact through
    # another path must not claim causal credit for an NPC's independent share.
    var contacted := not contact.is_empty()
    public_log.append({"day": day, "fact": id, "speaker": speaker, "player_contact": contacted,
        "player_action": str(contact.get("action", "")), "source": str(item.get("owner", "")),
        "provenance": str(item.get("type", ""))})
    _agency_event("public_fact", {"fact": id, "speaker": speaker, "source": str(item.get("owner", "")),
        "provenance": str(item.get("type", "")), "player_caused": speaker == "player" or contacted,
        "player_action": str(contact.get("action", "")), "public_trigger": "player_present" if speaker == "player" else "npc_share"})
    while public_log.size() > 80:
        public_log.pop_front()
    stage_state()["public_log"] = public_log

func _mark_public_conflict(key: String, targets: Array, detail: String) -> void:
    if public_contradiction_keys.has(key):
        return
    public_contradiction_keys[key] = true
    manual_contradictions.append({"key": key, "kind": "public", "targets": targets.duplicate(), "detail": detail, "day": day})
    stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1

func _first_active(order: Array, exclude: Array) -> String:
    for npc_id in order:
        if is_alive(str(npc_id)) and str(npc_id) not in exclude:
            return str(npc_id)
    return ""

func _feed_social(npc_id: String, key: String, params: Dictionary, kind: String, target_id: String, thread_role: String = "", topic: String = "") -> void:
    if not is_alive(npc_id):
        return
    var text := AstraSocialLines.line(npc_id, key, params, _pick(npc_id + key + topic))
    if key == "m_deny":
        # Only reference evidence already spoken publicly. Innocents can use
        # the same resistance vocabulary, so wording is not a role detector.
        var heard := false
        for item in current_packet().get("fragments", []):
            if AstraKnowledgeModel.is_public(flags, str(item.get("id", ""))):
                heard = true
                break
        if heard:
            var tactic := 2 if (null_style(npc_id) == "COUNTERATTACK" if npc_id in living_null_ids() else npc_id in ["noa", "vale", "dax"]) else 0
            if public_contradiction_keys.has("excuse:" + npc_id):
                tactic = 1
            text = AstraSocialLines.resistance_line(npc_id, tactic)
    if text == "":
        return
    _feed_line(npc_id, target_id, text, kind, thread_role, topic)

func _feed_narration(text: String) -> void:
    _feed_line("", "", text, "narration", "", "board")

func _most_affine(target_id: String) -> String:
    var best := ""
    var best_value := -9.0
    for npc_id in living_ids():
        if npc_id == target_id:
            continue
        if crew[npc_id].get_affinity(target_id) > best_value:
            best_value = crew[npc_id].get_affinity(target_id)
            best = npc_id
    return best

# ---------------------------------------------------------------- explorer interventions

# What the explorer can do in this meeting, from what they actually hold.
func meeting_options() -> Array:
    if phase != "MEETING" or meeting_actions_left <= 0 or outcome != "":
        return []
    var options: Array = []
    var moment := meeting_moment()
    var subject := str(moment.get("subject", ""))
    match str(moment.get("kind", "")):
        "record":
            for other in current_packet().get("fragments", []):
                var other_id := str(other.get("id", ""))
                if str(other.get("type", "")) != "EXPERT_INFERENCE" or str(other.get("refutes", "")) != subject:
                    continue
                if contested_state(other_id) == "open" and is_alive(str(other.get("owner", ""))):
                    options.append({"kind": "settle", "ref": other_id, "tone": "calm",
                        "label": _josa_inline("%s에게 그 설명이 정말 가능한지 다시 확인한다" % name_of(str(other.get("owner", "")))),
                        "detail": "전문가가 확답하면, 반박된 변명이 모두 앞에서 무너집니다."})
                elif player_knows(other_id) and not AstraKnowledgeModel.is_public(flags, other_id) and _excuse_visible("player", subject):
                    options.append({"kind": "present", "ref": other_id, "tone": "redirect",
                        "label": _josa_inline("%s|i 한 말을 꺼낸다: 그 방식으로는 불가능하다" % name_of(str(other.get("owner", "")))),
                        "detail": str(other.get("text", ""))})
            if subject == "" and Array(moment.get("members", [])).size() >= 2:
                options.append({"kind": "group", "ref": str(moment.get("ref", "")), "tone": "press",
                    "label": "해당하는 %s의 위치를 한 명씩 다시 묻는다" % names_of(moment.get("members", [])),
                    "detail": "말을 다시 하게 하면 누군가의 이야기가 흔들릴 수 있습니다."})
            elif subject != "" and is_alive(subject):
                options.append({"kind": "press", "ref": subject, "tone": "press",
                    "label": _josa_inline("%s에게 그 시간 동선을 처음부터 다시 말하게 한다" % name_of(subject)),
                    "detail": "압박합니다. 거짓이 있다면 흔들리고, 없다면 오히려 믿음을 삽니다."})
        "witness":
            if subject == "" and Array(moment.get("members", [])).size() >= 2:
                options.append({"kind": "group", "ref": str(moment.get("ref", "")), "tone": "press",
                    "label": "해당하는 %s의 위치를 한 명씩 다시 묻는다" % names_of(moment.get("members", [])),
                    "detail": "말을 다시 하게 하면 누군가의 이야기가 흔들릴 수 있습니다."})
            elif subject != "" and is_alive(subject):
                options.append({"kind": "press", "ref": subject, "tone": "press",
                    "label": _josa_inline("%s에게 그 시간 동선을 처음부터 다시 말하게 한다" % name_of(subject)),
                    "detail": "압박합니다. 거짓이 있다면 흔들리고, 없다면 오히려 믿음을 삽니다."})
        "frame":
            var framer := str(moment.get("framer", ""))
            var alibi_id := str(moment.get("alibi", ""))
            if alibi_id != "" and player_knows(alibi_id) and not AstraKnowledgeModel.is_public(flags, alibi_id):
                var alibi := fragment(alibi_id)
                options.append({"kind": "present", "ref": alibi_id, "tone": "redirect",
                    "label": _josa_inline("%s의 기록으로 반박한다: %s|eun 그 시간 다른 곳에 있었다" % [name_of(str(alibi.get("owner", ""))), name_of(subject)]),
                    "detail": str(alibi.get("text", ""))})
            if is_alive(framer) and not bool(stage_state().get("refuted_frames", {}).get(str(moment.get("ref", "")), false)):
                options.append({"kind": "press_frame", "ref": framer, "tone": "press",
                    "label": _josa_inline("%s에게 정확히 무엇을 봤는지 되묻는다" % name_of(framer)),
                    "detail": "본 게 확실하지 않다면 물러설 수 있습니다. 확실하다고 버티면 오히려 힘이 실립니다."})
            if is_alive(subject):
                options.append({"kind": "defend", "ref": subject, "tone": "defend",
                    "label": _josa_inline("%s|eul 감싼다: 한 사람의 목격만으로는 부족하다" % name_of(subject)),
                    "detail": "당신을 믿는 사람일수록 이 말에 따라 표를 거둡니다."})
        "benign":
            if is_alive(subject):
                if _confessed_today(subject) and not bool(stage_state()["confessions"][subject].get("public", false)):
                    options.append({"kind": "defend", "ref": subject, "tone": "defend",
                        "label": _josa_inline("%s의 사정을 대신 설명한다" % name_of(subject)),
                        "detail": "당신이 따로 들은 사정을 공개합니다. 거짓말의 이유가 밝혀집니다."})
                elif not _confessed_today(subject):
                    options.append({"kind": "coax", "ref": subject, "tone": "calm",
                        "label": _josa_inline("%s에게 지금 사정을 말해 달라고 한다" % name_of(subject)),
                        "detail": "당신을 믿는다면 털어놓습니다. 아니면 더 입을 닫습니다."})
        "callback", "accuse":
            var speaker := str(moment.get("speaker", ""))
            if is_alive(speaker):
                options.append({"kind": "basis", "ref": speaker, "tone": "calm",
                    "label": _josa_inline("잠깐, %s의 근거부터 다시 듣자" % name_of(speaker)),
                    "detail": "근거가 약하면 지목의 힘이 빠지고, 근거 없이 몰아간 사람이 눈에 띕니다."})
            if is_alive(subject):
                options.append({"kind": "support", "ref": subject, "tone": "confront",
                    "label": _josa_inline("%s 쪽이 걸린다고 말한다" % name_of(subject)),
                    "detail": "당신을 믿는 사람들이 이쪽으로 기웁니다."})
                if options.size() < 3:
                    options.append({"kind": "defend", "ref": subject, "tone": "defend",
                        "label": _josa_inline("%s|eul 감싼다" % name_of(subject)),
                        "detail": "당신을 믿는 사람일수록 이 말에 따라 표를 거둡니다."})
        "hearsay":
            var via := str(moment.get("via", ""))
            var heard := fragment(str(moment.get("ref", "")))
            var original := _hearsay_source(heard)
            if via != "" and is_alive(via) and not original.is_empty() and not AstraKnowledgeModel.is_public(flags, str(original.get("id", ""))):
                options.append({"kind": "source", "ref": str(moment.get("ref", "")), "tone": "calm",
                    "label": _josa_inline("본 사람에게 직접 묻는다: %s, 정확히 무엇을 봤어요?" % name_of(via)),
                    "detail": "말은 옮겨지며 바뀔 수 있습니다. 본 사람이 직접 말하면 전해진 말은 힘을 잃습니다."})
            if subject == "" and Array(moment.get("members", [])).size() >= 2 and options.size() < 2:
                options.append({"kind": "group", "ref": str(moment.get("ref", "")), "tone": "press",
                    "label": "해당하는 %s의 위치를 한 명씩 다시 묻는다" % names_of(moment.get("members", [])),
                    "detail": "말을 다시 하게 하면 누군가의 이야기가 흔들릴 수 있습니다."})
        "shield":
            var doubter := str(moment.get("speaker", ""))
            if doubter != "" and is_alive(doubter):
                options.append({"kind": "basis", "ref": doubter, "tone": "calm",
                    "label": _josa_inline("%s에게 되묻는다: 공격이 아니었다고 볼 근거가 있나" % name_of(doubter)),
                    "detail": "근거 없이 의심을 심었다면 그 사람이 눈에 띕니다."})
            if is_alive(subject):
                options.append({"kind": "defend", "ref": subject, "tone": "defend",
                    "label": _josa_inline("%s|eul 감싼다: 노려졌다는 건 무언가를 알고 있었다는 뜻이다" % name_of(subject)),
                    "detail": "당신을 믿는 사람일수록 이 말에 따라 표를 거둡니다."})
        "yesterday":
            for pusher in moment.get("pushers", []):
                if is_alive(str(pusher)) and options.size() < 1:
                    options.append({"kind": "basis", "ref": str(pusher), "tone": "calm",
                        "label": _josa_inline("어제 %s|eul 밀었던 %s에게 이유를 묻는다" % [name_of(subject), name_of(str(pusher))]),
                        "detail": "어제의 판단이 무엇에 기대고 있었는지 드러납니다."})
    # What the explorer holds and nobody has said yet: the strongest item.
    if options.size() < 3:
        var best := {}
        var best_p := -1.0
        for item in known_fragments():
            var id := str(item.get("id", ""))
            if AstraKnowledgeModel.is_public(flags, id) or _option_has_ref(options, id):
                continue
            var type := str(item.get("type", ""))
            if type == "EXPERT_INFERENCE" and not _excuse_visible("player", str(item.get("refutes", ""))):
                continue
            if type == "ALIBI_SUPPORT" and not AstraKnowledgeModel.is_public(flags, _frame_id_for(str(item.get("refutes", "")))):
                continue
            if int(item.get("day", day)) != day and type not in ["SYSTEM_RECORD", "DIRECT_WITNESS"]:
                continue
            var p := float(item.get("strength", 0.3)) + (0.2 if int(item.get("day", day)) == day else 0.0) + (0.2 if bool(item.get("specific", false)) else 0.0)
            if p > best_p:
                best_p = p
                best = item
        if not best.is_empty():
            options.append({"kind": "present", "ref": str(best.get("id", "")), "tone": "redirect",
                "label": _present_label(best), "detail": str(best.get("text", ""))})
    for npc_id in living_ids():
        if options.size() >= 3:
            break
        if _confessed_today(str(npc_id)) and not bool(stage_state()["confessions"][npc_id].get("public", false)) and not _option_has_ref(options, str(npc_id)):
            if float(_public_heat().get(str(npc_id), 0.0)) > 0.0:
                options.append({"kind": "defend", "ref": str(npc_id), "tone": "defend",
                    "label": _josa_inline("%s의 사정을 대신 설명한다" % name_of(str(npc_id))),
                    "detail": "당신이 따로 들은 사정을 공개합니다."})
    options = options.slice(0, 3)
    if not link_statements().is_empty():
        options.append({"kind": "link", "ref": "", "tone": "redirect", "label": "누군가의 말과 내가 아는 근거를 이어서 따진다…",
            "detail": "진술 하나와 근거 하나(또는 둘)를 골라 왜 맞지 않는지 보여 줍니다. 맞으면 방이 움직이고, 억지면 신뢰를 잃습니다."})
    options.append({"kind": "accuse", "ref": "", "tone": "confront", "label": "내가 한 사람을 지목한다…", "detail": "이유와 함께 한 사람을 지목합니다. 당신을 믿는 사람들이 따라올 수 있습니다."})
    return options

func _option_has_ref(options: Array, ref: String) -> bool:
    for option in options:
        if str(option.get("ref", "")) == ref:
            return true
    return false

func _frame_id_for(framer: String) -> String:
    for item in current_packet().get("fragments", []):
        if str(item.get("type", "")) == "NULL_DECEPTION" and str(item.get("owner", "")) == framer:
            return str(item.get("id", ""))
    return ""

func _present_label(item: Dictionary) -> String:
    var owner := name_of(str(item.get("owner", "")))
    match str(item.get("type", "")):
        "SYSTEM_RECORD":
            return _josa_inline("%s의 %s|eul 꺼낸다" % [owner, str(item.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(item.get("record_type", "")), "기록")))])
        "ALIBI_SUPPORT":
            return _josa_inline("%s의 기록을 꺼낸다: %s|eun 다른 곳에 있었다" % [owner, name_of(str(item.get("subject", "")))])
        "EXPERT_INFERENCE":
            return _josa_inline("%s|i 한 말을 꺼낸다: 그 방식으로는 불가능하다" % owner)
        "HEARSAY":
            return _josa_inline("%s|i 전해 들은 말을 꺼낸다" % owner)
    return _josa_inline("%s|i 본 것을 꺼낸다" % owner)
func _current_accused() -> String:
    for index in range(meeting_feed.size() - 1, -1, -1):
        var entry: Dictionary = meeting_feed[index]
        if str(entry.get("kind", "")) == "suspect" and is_alive(str(entry.get("target", ""))):
            return str(entry.get("target", ""))
    return ""

func _public_conflicts() -> Array:
    var result: Array = []
    var ids := living_ids()
    for i in range(ids.size()):
        for j in range(i + 1, ids.size()):
            var a := str(ids[i])
            var b := str(ids[j])
            if not public_claims.has(a) or not public_claims.has(b):
                continue
            if public_contradiction_keys.has("contrast:%s:%s" % [a, b]):
                continue
            if _visible_conflict(a, _claim_visible("player", a), b, _claim_visible("player", b)) != "":
                result.append([a, b])
    return result.slice(0, 2)

func intervene(kind: String, ref: String) -> Dictionary:
    if kind == "clarify":
        return _clarify_argument(ref)
    if phase != "MEETING" or meeting_actions_left <= 0 or outcome != "":
        return {"ok": false}
    var before := _meeting_tops()
    var votes_before := _npc_vote_targets()
    var used_before := int(stage_state().get("interventions", {}).get(_day_key(), 0))
    var start := meeting_feed.size()
    var ok := false
    match kind:
        "present": ok = _intervene_present(ref)
        "defend": ok = _intervene_defend(ref)
        "contrast":
            var parts := ref.split("|")
            ok = parts.size() == 2 and _intervene_contrast(str(parts[0]), str(parts[1]))
        "support": ok = _intervene_support(ref)
        "accuse": ok = _intervene_accuse(ref)
        "settle": ok = _intervene_settle(ref)
        "group": ok = _intervene_group(ref)
        "press": ok = _intervene_press(ref)
        "press_frame": ok = _intervene_press_frame(ref)
        "coax": ok = _intervene_coax(ref)
        "basis": ok = _intervene_basis(ref)
        "source": ok = _intervene_source(ref)
        "link": ok = _intervene_link(ref)
    if not ok:
        return {"ok": false}
    meeting_actions_left -= 1
    # EMPATH's daily extra can be spent here as a second intervention.
    if used_before >= AstraCaseCatalog.MEETING_INTERVENTIONS and protocol == "EMPATH" and empath_available():
        _use_daily("empath_uses")
    _use_daily("interventions")
    _refresh_npc_suspicion()
    var shifts := _opinion_shift_lines(before)
    var arcs: Array = stage_state().get("meeting_arcs", [])
    if not arcs.is_empty():
        arcs.back()["player_action"] = kind
        arcs.back()["player_ref"] = ref
        arcs.back()["reaction_count"] = shifts.size()
    for shift in shifts:
        _agency_event("meeting_shift", {"npc": str(shift.get("npc", "")), "before": str(shift.get("before", "")),
            "after": str(shift.get("after", "")), "player_caused": true, "action": kind, "ref": ref})
    var votes_after := _npc_vote_targets()
    var vote_changes: Array = stage_state().get("agency_vote_changes", [])
    for voter in votes_before:
        if votes_after.has(voter) and str(votes_before[voter]) != str(votes_after[voter]):
            vote_changes.append({"day": day, "voter": str(voter), "before": str(votes_before[voter]),
                "after": str(votes_after[voter]), "action": kind, "ref": ref})
    stage_state()["agency_vote_changes"] = vote_changes
    _recompute_contradictions()
    changed.emit()
    return {"ok": true, "lines": meeting_feed.slice(start), "shifts": shifts}

func _npc_vote_targets() -> Dictionary:
    var result := {}
    var pool := eligible_vote_targets()
    if pool.is_empty():
        return result
    for voter in eligible_voters():
        result[str(voter)] = str(_vote_target_for(str(voter), pool).get("target", ""))
    return result

func _meeting_tops() -> Dictionary:
    var tops := {}
    for npc_id in living_ids():
        tops[npc_id] = str(top_suspect_of(str(npc_id)).get("target", ""))
    return tops

# Visible consequence of an intervention: who changed their mind, and why.
func _opinion_shift_lines(before: Dictionary) -> Array:
    var shifts: Array = []
    for npc_id in living_ids():
        var top := top_suspect_of(str(npc_id))
        var after := str(top.get("target", ""))
        if after == "" or after == str(before.get(npc_id, "")) or shifts.size() >= 2:
            continue
        shifts.append({"npc": str(npc_id), "before": str(before.get(npc_id, "")), "after": after})
        _feed_social(str(npc_id), "m_shift", {"target": name_of(after), "reason": str(top.get("reason_text", ""))}, "react", after, "followup", "shift")
        AstraDecisionModel.append_trace(flags, AstraDecisionModel.trace(str(npc_id), "meeting_shift", after, Array(top.get("reasons", [])), day))
        if voyage.has("opinion_changes"):
            voyage["opinion_changes"].append({"actor": str(npc_id), "before": str(before.get(npc_id, "")), "after": after, "reason_tag": "new_evidence",
                "reason": str(top.get("reason_text", "")), "source": "meeting", "day": day, "visible": true,
                "known_facts": AstraKnowledgeModel.known_facts(flags, str(npc_id))})
    return shifts

func _intervene_present(ref: String) -> bool:
    var item := fragment(ref)
    if item.is_empty() or not player_knows(ref) or AstraKnowledgeModel.is_public(flags, ref):
        return false
    _feed_line("player", str(item.get("subject", "")), _voice("present", "제가 들은 걸 공개할게요. %s") % str(item.get("text", "")), "player", "anchor", "present:" + ref)
    _publish_fragment(item, "player")
    stats["presented"] = int(stats.get("presented", 0)) + 1
    record_player_claim(AstraClaimLedger.KIND_WITNESS, "공개했다: " + str(item.get("text", "")), {"target": str(item.get("subject", item.get("refutes", "")))})
    var owner := str(item.get("owner", ""))
    if is_alive(owner) and owner != "player":
        _feed_social(owner, "m_confirm" if not bool(item.get("false", false)) else "m_saw", _fragment_params(item), "record", str(item.get("subject", "")), "support", "present:" + ref)
    var type := str(item.get("type", ""))
    var subject := str(item.get("subject", ""))
    if type == "EXPERT_INFERENCE":
        subject = str(item.get("refutes", ""))
        if is_alive(subject):
            _feed_social(subject, "m_deny", {}, "defense", subject, "response", "present:" + ref)
    elif type == "ALIBI_SUPPORT":
        var framer := str(item.get("refutes", ""))
        var frame_id := _frame_id_for(framer)
        if frame_id != "":
            _refute_frame(frame_id, framer, subject, item, "player")
        if framer in living_null_ids():
            _raise_player_threat(framer, 0.35)
    elif subject != "" and is_alive(subject):
        _respond_to_evidence(subject, item, "present:" + ref)
    elif type in ["DIRECT_WITNESS", "SYSTEM_RECORD", "HEARSAY"]:
        var members: Array = []
        for member_id in item.get("points_to", []):
            if is_alive(str(member_id)):
                members.append(str(member_id))
        if not members.is_empty():
            _feed_social(str(members[0]), "m_group_answer", {"members": names_of(members)}, "defense", str(members[0]), "response", "present:" + ref)
    for target in item.get("points_to", []):
        if str(target) in living_null_ids():
            _raise_player_threat(str(target), 0.3)
    notice.emit("present", {"fragment": item})
    return true

func _intervene_defend(target: String) -> bool:
    if not is_alive(target):
        return false
    stats["defenses"] = int(stats.get("defenses", 0)) + 1
    _add_defense("player", target)
    record_player_claim(AstraClaimLedger.KIND_DEFEND, "%s|eul 변호했다." % name_of(target), {"target": target})
    if _confessed_today(target) and not bool(stage_state()["confessions"][target].get("public", false)):
        var entry: Dictionary = stage_state()["confessions"][target]
        _feed_line("player", target, "%s의 진술이 어긋난 건 사건 때문이 아니에요. %s 실제로는 %s에 있었어요." % [name_of(target), innocent_discrepancy_text(str(entry.get("reason", ""))), room_name(str(entry.get("position", "")))], "player", "anchor", "defend:" + target)
        _publish_confession(target)
        crew[target].adjust_trust(0.06)
    else:
        _feed_line("player", target, _voice("defend", "%s|eul 몰아가기엔 근거가 부족해요. 확인된 것부터 봐요.") % name_of(target), "player", "anchor", "defend:" + target)
        _feed_social(target, "m_thanks", {}, "calm", target, "response", "defend:" + target)
    _maybe_challenge_player(target)
    notice.emit("defend", {"target": target})
    return true

func _intervene_contrast(a: String, b: String) -> bool:
    if not is_alive(a) or not is_alive(b):
        return false
    var key := "contrast:%s:%s" % [a, b]
    _raise_pair(a, b)
    _feed_line("player", a, _voice("compare", "%s, %s. 두 사람 다 %s에 어디 있었는지 다시 말해 주세요.") % [name_of(a), name_of(b), incident_time()], "player", "anchor", key)
    record_player_claim(AstraClaimLedger.KIND_WITNESS, "%s|wa %s|eul 대질했다." % [name_of(a), name_of(b)], {"target": a})
    for speaker in [a, b]:
        var claim := current_claim(speaker)
        var mates: Array = claim.get("companions", [])
        _feed_npc(speaker, "m_alibi_with" if not mates.is_empty() else "m_alibi_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates))}, "alibi", "")
    var kind := _visible_conflict(a, _claim_visible("player", a), b, _claim_visible("player", b))
    if kind != "":
        _mark_public_conflict(key, [a, b] if kind == "place" else ([b] if kind == "they_vouch" else [a]),
            "%s|wa %s의 진술은 동시에 맞을 수 없다." % [name_of(a), name_of(b)])
        var catcher := _first_active(["noa", "dax", "eli"], [a, b])
        if catcher != "":
            _feed_social(catcher, "m_catch_lie", {"a": name_of(a), "b": name_of(b)}, "dispute", a, "challenge", key)
    else:
        public_contradiction_keys[key] = true
        _feed_social(b, "m_vouch", {"target": name_of(a), "pos": room_name(str(current_claim(b).get("position", "")))}, "calm", a, "support", key)
    return true

func _intervene_support(target: String) -> bool:
    if not is_alive(target):
        return false
    _feed_line("player", target, _voice("support", "저도 %s 쪽이 걸려요. 설명이 더 필요해요.") % name_of(target), "player", "support", "suspicion:" + target)
    _add_accusation("player", target, 1.0)
    record_player_claim(AstraClaimLedger.KIND_ACCUSE, "%s에 대한 의심에 동의했다." % name_of(target), {"target": target})
    _feed_social(target, "m_defend_self", {"pos": room_name(str(current_claim(target).get("position", ""))), "mates": AstraJosa.join_names(_names(current_claim(target).get("companions", []))), "target": "탐사요원"}, "defense", target, "response", "suspicion:" + target)
    if target in living_null_ids():
        _raise_player_threat(target, 0.2)
    return true

func _intervene_accuse(target: String) -> bool:
    if not is_alive(target):
        return false
    stats["accusations"] = int(stats.get("accusations", 0)) + 1
    accused_today[target] = true
    var view := suspicion_breakdown("player", target)
    var basis := _reason_phrase(view.get("reasons", []))
    var has_basis := float(view.get("score", 0.0)) >= 0.25
    _feed_line("player", target, "%s, 당신을 지목할게요. %s" % [name_of(target), ("근거는 " + basis + "이에요.") if has_basis else "아직 제 직감이 더 커요."], "player", "anchor", "suspicion:" + target)
    _add_accusation("player", target, 1.25 if has_basis else 0.8)
    record_player_claim(AstraClaimLedger.KIND_ACCUSE, "%s|eul 지목했다." % name_of(target), {"target": target})
    var claim := current_claim(target)
    _feed_social(target, "m_defend_self", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(claim.get("companions", []))), "target": "탐사요원"}, "defense", target, "response", "suspicion:" + target)
    if has_basis:
        var agree := _first_active(["sena", "rho", "eli", "noa"], [target])
        if agree != "":
            _feed_social(agree, "m_agree", {"target": name_of(target)}, "react", target, "support", "suspicion:" + target)
    else:
        var doubt := _first_active(["mira", "lyra", "dax"], [target])
        if doubt != "":
            _feed_social(doubt, "m_caution", {"target": name_of(target)}, "react", target, "clarify", "suspicion:" + target)
        for observer_id in living_ids():
            crew[observer_id].adjust_trust(-0.02)
    _maybe_challenge_player(target)
    if target in living_null_ids():
        _raise_player_threat(target, 0.35)
    notice.emit("accuse", {"target": target, "support": float(view.get("score", 0.0))})
    return true

# The expert is asked, in front of everyone, whether the second excuse can be
# true. They settle it.
func _intervene_settle(ref: String) -> bool:
    var item := fragment(ref)
    if item.is_empty() or contested_state(ref) != "open":
        return false
    var expert := str(item.get("owner", ""))
    var subject := str(item.get("refutes", ""))
    if not is_alive(expert):
        return false
    _feed_line("player", expert, _josa_inline("%s, 방금 그 설명… 정말 가능한 거예요? 확실하게 말해 줘요." % name_of(expert)), "player", "anchor", "settle:" + ref)
    _feed_social(expert, "m_settle", {"target": name_of(subject), "fact": str(item.get("text", ""))}, "record", subject, "challenge", "settle:" + ref)
    var contested: Dictionary = stage_state().get("contested", {})
    contested[ref] = "settled"
    stage_state()["contested"] = contested
    if is_alive(subject):
        crew[subject].adjust_stress(0.15)
        _feed_social(subject, "m_deny", {}, "defense", subject, "response", "settle:" + ref)
        _mark_public_conflict("excuse:" + subject, [subject], "%s의 두 번째 설명도 장비 구조상 성립하지 않는다." % name_of(subject))
        var demander := _first_active(["sena", "rho", "eli", "noa"], [subject, expert])
        if demander != "":
            _feed_social(demander, "m_demand", {"target": name_of(subject)}, "suspect", subject, "followup", "settle:" + ref)
            _add_accusation(demander, subject, 0.8)
    if subject in living_null_ids():
        _raise_player_threat(subject, 0.3)
    return true

# Everyone a vague record or sighting fits is asked to say again where they
# were. Someone lying under pressure can stumble; honest people hold.
func _intervene_group(ref: String) -> bool:
    var item := fragment(ref)
    if item.is_empty():
        return false
    var members: Array = []
    for member_id in item.get("points_to", []):
        if is_alive(str(member_id)):
            members.append(str(member_id))
    if members.size() < 2:
        return false
    _feed_line("player", "", "%s. 한 명씩, 그 시간에 어디 있었는지 다시 말해 주세요." % names_of(members), "player", "anchor", "group:" + ref)
    for member_id in members:
        _restate(str(member_id), "group:" + ref)
    return true

func _intervene_press(target: String) -> bool:
    if not is_alive(target):
        return false
    _feed_line("player", target, _josa_inline(_voice("press", "%s, 그 시간 동선을 처음부터 다시 말해 주세요. 천천히요.") % name_of(target)), "player", "anchor", "press:" + target)
    _restate(target, "press:" + target, 0.12)
    _maybe_challenge_player(target)
    return true

# One person says their account again with the whole room watching. Whoever is
# lying about today may slip; everyone else holds, and that counts for them.
func _restate(npc_id: String, topic: String, extra: float = 0.0) -> void:
    var member: AstraCrewMember = crew[npc_id]
    var role := _day_role(npc_id)
    var claim := current_claim(npc_id)
    var mates: Array = []
    for mate in claim.get("companions", []):
        if is_alive(str(mate)):
            mates.append(str(mate))
    member.adjust_stress(0.06 + extra)
    if role in ["actor", "cover"] and _pick("slip:" + npc_id + topic) < 0.25 + member.stress * 0.45 + extra:
        _partial_admit_public(member, topic)
        return
    _feed_npc(npc_id, "m_alibi_with" if not mates.is_empty() else "m_alibi_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates))}, "alibi", "", "response", topic)
    if role not in ["actor", "cover"]:
        var held: Dictionary = stage_state().get("held_firm", {})
        held[npc_id] = day
        stage_state()["held_firm"] = held

func _partial_admit_public(member: AstraCrewMember, topic: String) -> void:
    var room := str(incident().get("room", ""))
    var old_pos := str(current_packet().get("claims", {}).get(member.id, {}).get("position", ""))
    var admissions: Dictionary = stage_state().get("admissions", {})
    admissions[member.id] = {"day": day, "position": room, "public": true}
    stage_state()["admissions"] = admissions
    var line := AstraSocialLines.line(member.id, "partial_admit", {"room": room_name(room), "pos": room_name(old_pos)}, _pick(member.id + "pap"))
    _feed_line(member.id, member.id, line, "defense", "response", topic)
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PUBLIC, line, {"position": room, "about_day": day})
    stats["admissions"] = int(stats.get("admissions", 0)) + 1
    _mark_public_conflict("slip:" + member.id, [member.id], "%s|i 다시 말하는 도중 %s 앞까지 갔다고 인정했다." % [member.display_name, room_name(room)])
    var catcher := _first_active(["noa", "eli", "sena", "dax"], [member.id])
    if catcher != "":
        _feed_social(catcher, "m_callback", {"target": member.display_name, "old": room_name(old_pos), "new": room_name(room), "day": day, "when": "아까는"}, "record", member.id, "challenge", topic)
        _add_accusation(catcher, member.id, 0.8)
    if member.is_null():
        _raise_player_threat(member.id, 0.3)
    notice.emit("admission", {"npc_id": member.id, "public": true})

# The person who claimed a sighting is asked what exactly they saw.
func _intervene_press_frame(framer: String) -> bool:
    var frame_id := _frame_id_for(framer)
    var item := fragment(frame_id)
    if item.is_empty() or not is_alive(framer):
        return false
    var scapegoat := str(item.get("subject", ""))
    _feed_line("player", framer, _josa_inline("%s, 정확히 뭘 봤어요? 얼굴이었어요, 뒷모습이었어요?" % name_of(framer)), "player", "anchor", "press_frame:" + frame_id)
    var member: AstraCrewMember = crew[framer]
    member.adjust_stress(0.12)
    var doubt := 0.3 + member.stress * 0.45 + (0.2 if _player_pressure_on(framer) > 0.0 else 0.0)
    if _pick("hedge:" + frame_id) < doubt:
        _feed_social(framer, "m_retreat", {"target": name_of(scapegoat)}, "defense", framer, "response", "press_frame:" + frame_id)
        var refuted_frames: Dictionary = stage_state().get("refuted_frames", {})
        refuted_frames[frame_id] = true
        stage_state()["refuted_frames"] = refuted_frames
        _weaken_accusation(framer, scapegoat, 0.15)
        var catcher := _first_active(["noa", "mira", "dax", "eli"], [framer, scapegoat])
        if catcher != "":
            _feed_social(catcher, "m_note_thin", {"target": name_of(scapegoat)}, "react", framer, "followup", "press_frame:" + frame_id)
        _mark_public_conflict("frame:" + frame_id, [framer], "%s|eun %s|eul 봤다고 했다가 물러섰다." % [name_of(framer), name_of(scapegoat)])
        if framer in living_null_ids():
            _raise_player_threat(framer, 0.3)
    else:
        _feed_social(framer, "m_hold_sighting", _fragment_params(item), "dispute", scapegoat, "response", "press_frame:" + frame_id)
        for entry in stage_state().get("public_accusations", []):
            if str(entry.get("speaker", "")) == framer and str(entry.get("target", "")) == scapegoat and int(entry.get("day", 0)) == day:
                entry["weight"] = float(entry.get("weight", 1.0)) + 0.3
    return true

# The explorer asks someone hiding something harmless to say it now.
func _intervene_coax(target: String) -> bool:
    if not is_alive(target) or _day_role(target) != "benign":
        return false
    var member: AstraCrewMember = crew[target]
    _feed_line("player", target, _josa_inline(_voice("coax", "%s, 사건이랑 상관없는 일이라면 지금 말해도 괜찮아요. 그걸로 아무도 당신을 보내지 않아요.") % name_of(target)), "player", "anchor", "coax:" + target)
    if member.trust >= 0.5 or member.stress >= 0.55 or _pick("coax:" + target) < 0.35:
        var result := {"lines": []}
        _confess(member, result, false)
        _publish_confession(target)
        member.adjust_trust(0.05)
    else:
        _feed_social(target, "m_deflect", {}, "defense", target, "response", "coax:" + target)
        member.adjust_stress(0.08)
        member.adjust_trust(-0.03)
    return true

# "Wait — on what grounds?" The accuser has to say it aloud. A real reason
# stands; a push without one loses its pull and marks the person who made it.
func _intervene_basis(speaker: String) -> bool:
    if not is_alive(speaker):
        return false
    var target := ""
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("speaker", "")) == speaker and int(entry.get("day", 0)) >= day - 1:
            target = str(entry.get("target", ""))
    if target == "":
        target = str(meeting_moment().get("subject", ""))
    if target == "" or target == speaker:
        return false
    _feed_line("player", speaker, _josa_inline(_voice("basis", "잠깐요. %s, %s|eul 의심하는 근거부터 다시 말해 줄래요?") % [name_of(speaker), name_of(target)]), "player", "anchor", "basis:" + speaker)
    var view := suspicion_breakdown(speaker, target, true)
    var hard := 0.0
    for reason in view.get("reasons", []):
        if str(reason.get("code", "")) in ["HARD_RECORD", "TIMELINE", "DIRECT_WITNESS", "EXPERT_INFERENCE", "CHANGED_STORY", "FALSE_SIGHTING", "CONTRADICTION"] and float(reason.get("weight", 0.0)) > 0.0:
            hard += float(reason.get("weight", 0.0))
    if hard >= 0.22:
        _feed_social(speaker, "m_basis", {"target": name_of(target), "reason": _reason_text_for(speaker, view.get("reasons", []))}, "suspect", target, "response", "basis:" + speaker)
        for entry in stage_state().get("public_accusations", []):
            if str(entry.get("speaker", "")) == speaker and str(entry.get("target", "")) == target and int(entry.get("day", 0)) == day:
                entry["weight"] = float(entry.get("weight", 1.0)) + 0.2
    else:
        _feed_social(speaker, "m_basis_thin", {"target": name_of(target)}, "defense", speaker, "response", "basis:" + speaker)
        _weaken_accusation(speaker, target, 0.25)
        var thin: Array = stage_state().get("thin_accusations", [])
        thin.append({"day": day, "speaker": speaker, "target": target})
        stage_state()["thin_accusations"] = thin
        var noter := _first_active(["noa", "dax", "mira", "eli", "vale"], [speaker, target])
        if noter != "":
            _feed_social(noter, "m_note_thin", {"target": name_of(target)}, "react", speaker, "followup", "basis:" + speaker)
        if speaker in living_null_ids():
            _raise_player_threat(speaker, 0.25)
    return true

# Going to the source of a retold sighting. The witness says what they saw;
# a detail that changed on the way is put right in front of everyone.
func _intervene_source(ref: String) -> bool:
    var item := fragment(ref)
    if str(item.get("type", "")) != "HEARSAY":
        return false
    var via := str(item.get("via", ""))
    var original := _hearsay_source(item)
    if not is_alive(via) or original.is_empty() or AstraKnowledgeModel.is_public(flags, str(original.get("id", ""))):
        return false
    _feed_line("player", via, _josa_inline(_voice("hearsay", "%s, 직접 본 사람한테 듣고 싶어요. 정확히 무엇을 봤어요?") % name_of(via)), "player", "anchor", "hearsay:" + ref)
    _source_answers(item, original, via)
    stats["sources_checked"] = int(stats.get("sources_checked", 0)) + 1
    if bool(item.get("distorted", false)):
        # Catching a changed detail is the kind of care people remember.
        for npc_id in living_crew_ids():
            crew[npc_id].adjust_trust(0.02)
    return true

# ---------------------------------------------------------------- linking (1.0)
#
# The explorer's own reasoning, said aloud: one statement someone made, and
# one or two things the explorer knows that bear on it. The pair is judged only
# from what the statement and the evidence say (places, people, times, the
# method an excuse relies on) — never from roles — so every piece of evidence
# that shows the same thing is accepted, and a pairing that shows nothing is
# said to show nothing. A link that shows nothing costs the explorer a little
# of the room's patience; one that holds moves the room.

const LINK_PENALTY_TRUST := 0.03

# Statements the explorer heard and can take up: alibis (their own words or
# the board), sightings said aloud, and an excuse given in public.
func link_statements() -> Array:
    var result: Array = []
    for npc_id in living_ids():
        var claim := _claim_visible("player", str(npc_id))
        if claim.is_empty():
            continue
        var mates: Array = claim.get("companions", [])
        var where := _place_of(str(npc_id), str(claim.get("position", "")))
        var text := ("%s에서 %s|wa 함께 있었다" % [where, names_of(mates)]) if not mates.is_empty() else ("%s에 혼자 있었다" % where)
        result.append({"ref": "claim:" + str(npc_id), "speaker": str(npc_id), "subject": str(npc_id),
            "label": _josa_inline("%s: “%s”" % [name_of(str(npc_id)), text])})
        if _excuse_visible("player", str(npc_id)):
            result.append({"ref": "excuse:" + str(npc_id), "speaker": str(npc_id), "subject": str(npc_id),
                "label": _josa_inline("%s의 해명: 기록은 자기가 한 게 아니다" % name_of(str(npc_id)))})
    for item in known_fragments(day):
        var type := str(item.get("type", ""))
        if type not in ["DIRECT_WITNESS", "NULL_DECEPTION", "HEARSAY"] or not AstraKnowledgeModel.is_public(flags, str(item.get("id", ""))):
            continue
        if not is_alive(str(item.get("owner", ""))):
            continue
        result.append({"ref": "said:" + str(item.get("id", "")), "speaker": str(item.get("owner", "")), "subject": str(item.get("subject", "")),
            "label": _josa_inline("%s의 목격: %s" % [name_of(str(item.get("owner", ""))), _short_text(str(item.get("text", "")))])})
    var moment := meeting_moment()
    var moment_subject := str(moment.get("subject", ""))
    var moment_ref := str(moment.get("ref", ""))
    for entry in result:
        var p := 0
        if str(entry.get("subject", "")) == moment_subject and moment_subject != "":
            p += 4
        if str(entry.get("speaker", "")) in [str(moment.get("owner", "")), str(moment.get("speaker", "")), str(moment.get("via", ""))]:
            p += 2
        if str(entry.get("ref", "")) == "said:" + moment_ref:
            p += 5
        entry["_link_order"] = p
    result.sort_custom(func(a, b): return int(a.get("_link_order", 0)) > int(b.get("_link_order", 0)))
    for entry in result:
        entry.erase("_link_order")
    return result

# Everything the explorer holds that could bear on a statement. Not filtered
# by what would work: choosing is the player's reasoning.
func link_evidence(statement_ref: String) -> Array:
    var result: Array = []
    var subject := _link_subject(statement_ref)
    for item in known_fragments():
        var id := str(item.get("id", ""))
        if "said:" + id == statement_ref:
            continue
        var type := str(item.get("type", ""))
        if int(item.get("day", day)) != day and type not in ["SYSTEM_RECORD", "DIRECT_WITNESS", "ALIBI_SUPPORT"]:
            continue
        var owner := str(item.get("owner", ""))
        var tag: String = {"SYSTEM_RECORD": "기록", "DIRECT_WITNESS": "목격", "HEARSAY": "전언", "EXPERT_INFERENCE": "전문 소견",
            "ALIBI_SUPPORT": "기록", "ROUTINE": "관찰", "NULL_DECEPTION": "목격", "BENIGN_EXPOSURE": "목격", "COVER_EXPOSURE": "목격"}.get(type, "정보")
        var source := "공개됨" if AstraKnowledgeModel.is_public(flags, id) else "당신만 들음"
        result.append({"ref": id, "kind": "fragment", "label": "[%s · %s · %s] %s" % [tag, name_of(owner), source, _short_text(str(item.get("text", "")))]})
    for npc_id in living_ids():
        if "claim:" + str(npc_id) == statement_ref:
            continue
        var claim := _claim_visible("player", str(npc_id))
        if claim.is_empty():
            continue
        var mates: Array = claim.get("companions", [])
        var where := room_name(str(claim.get("position", "")))
        result.append({"ref": "claim:" + str(npc_id), "kind": "claim",
            "label": _josa_inline("[진술 · %s] %s" % [name_of(str(npc_id)), ("%s에서 %s|wa 함께" % [where, names_of(mates)]) if not mates.is_empty() else ("%s에 혼자" % where)])})
    if subject != "" and not AstraClaimLedger.self_conflicts(claim_ledger, subject).is_empty():
        result.append({"ref": "earlier:" + subject, "kind": "earlier", "label": _josa_inline("[이전 진술 · %s] 전에 한 말" % name_of(subject))})
    # Keep every legal choice, but put today's and statement-relevant material
    # first so a long notebook is not a search puzzle. This never grades or
    # hides the wrong answers.
    for entry in result:
        var p := 0
        var ref := str(entry.get("ref", ""))
        if ref == "claim:" + subject or ref == "earlier:" + subject:
            p += 5
        elif not ref.begins_with("claim:") and not ref.begins_with("earlier:"):
            var item := fragment(ref)
            if int(item.get("day", 0)) == day:
                p += 3
            if subject in Array(item.get("points_to", [])) or str(item.get("subject", "")) == subject or str(item.get("supports", "")) == subject or str(item.get("refutes", "")) == subject:
                p += 4
            if AstraKnowledgeModel.is_public(flags, ref):
                p += 1
        entry["_link_order"] = p
    result.sort_custom(func(a, b): return int(a.get("_link_order", 0)) > int(b.get("_link_order", 0)))
    for entry in result:
        entry.erase("_link_order")
    return result

func _short_text(text: String) -> String:
    var plain := text
    var colon := plain.find(": ")
    if colon >= 0 and colon < 14:
        plain = plain.substr(colon + 2)
    return plain if plain.length() <= 58 else plain.left(56) + "…"

func _link_subject(statement_ref: String) -> String:
    if statement_ref.begins_with("claim:"):
        return statement_ref.trim_prefix("claim:")
    if statement_ref.begins_with("excuse:"):
        return statement_ref.trim_prefix("excuse:")
    if statement_ref.begins_with("said:"):
        return str(fragment(statement_ref.trim_prefix("said:")).get("subject", ""))
    return ""

# Room an evidence item places people in, and who.
func _placed(item: Dictionary) -> Dictionary:
    var type := str(item.get("type", ""))
    var people: Array = []
    if type in ["ALIBI_SUPPORT", "ROUTINE"]:
        people = [str(item.get("supports", item.get("subject", "")))]
    else:
        people = Array(item.get("points_to", [])).duplicate()
        if people.is_empty() and str(item.get("subject", "")) != "":
            people = [str(item.get("subject", ""))]
    return {"room": str(item.get("room", "")), "people": people, "specific": bool(item.get("specific", false)) or people.size() == 1,
        "routine": type == "ROUTINE", "hearsay": type == "HEARSAY"}

# The judgement. Returns {result, why, targets, publish, family}.
func judge_link(statement_ref: String, evidence_ref: String, second_ref: String = "") -> Dictionary:
    var verdict := {"result": "IRRELEVANT", "why": "", "targets": [], "publish": [], "family": ""}
    var statement_ok := false
    for entry in link_statements():
        statement_ok = statement_ok or str(entry["ref"]) == statement_ref
    if not statement_ok:
        verdict["result"] = "INVALID"
        return verdict
    var evidence_ok := false
    var second_ok := second_ref == ""
    for entry in link_evidence(statement_ref):
        evidence_ok = evidence_ok or str(entry["ref"]) == evidence_ref
        second_ok = second_ok or (str(entry["ref"]) == second_ref and second_ref != evidence_ref)
    if not evidence_ok or not second_ok:
        verdict["result"] = "INVALID"
        return verdict
    if statement_ref.begins_with("claim:"):
        return _judge_claim(statement_ref.trim_prefix("claim:"), evidence_ref, second_ref)
    if statement_ref.begins_with("said:"):
        return _judge_sighting(fragment(statement_ref.trim_prefix("said:")), evidence_ref)
    if statement_ref.begins_with("excuse:"):
        var who := statement_ref.trim_prefix("excuse:")
        var expert := fragment(evidence_ref)
        var excuse := str(AstraStageStory.method(str(incident().get("method", ""))).get("excuse", ""))
        if str(expert.get("type", "")) == "EXPERT_INFERENCE" and str(expert.get("excuse", "")) == excuse and excuse != "":
            verdict = {"result": "CONTRADICTION", "family": "excuse", "targets": [who], "publish": [evidence_ref],
                "why": "%s의 해명은 %s|i 말한 장비 구조와 맞지 않는다." % [name_of(who), name_of(str(expert.get("owner", "")))]}
        else:
            verdict["why"] = "그 정보는 %s의 해명이 가능한지와는 관계가 없다." % name_of(who)
    verdict["why"] = _josa_inline(str(verdict["why"]))
    return verdict

func _judge_claim(who: String, evidence_ref: String, second_ref: String) -> Dictionary:
    var claim := _claim_visible("player", who)
    var where := str(claim.get("position", ""))
    var mates: Array = claim.get("companions", [])
    var verdict := {"result": "IRRELEVANT", "why": "", "targets": [], "publish": [], "family": ""}
    if evidence_ref.begins_with("earlier:"):
        if not AstraClaimLedger.self_conflicts(claim_ledger, who).is_empty():
            verdict = {"result": "CONTRADICTION", "family": "changed_story", "targets": [who], "publish": [],
                "why": "%s|eun 같은 시간에 대해 전과 다른 말을 했다." % name_of(who)}
        return _finish_verdict(verdict)
    if evidence_ref.begins_with("claim:"):
        var other := evidence_ref.trim_prefix("claim:")
        var other_claim := _claim_visible("player", other)
        var kind := _visible_conflict(who, claim, other, other_claim)
        if kind != "":
            verdict = {"result": "CONTRADICTION", "family": "companion" if kind != "place" else "place",
                "targets": [who, other], "publish": [],
                "why": ("%s|wa %s의 말은 동시에 맞을 수 없다. 둘 중 한 사람은 사실과 다르게 말하고 있다." % [name_of(who), name_of(other)])}
        elif other in mates and who in Array(other_claim.get("companions", [])) and str(other_claim.get("position", "")) == where:
            verdict = {"result": "SUPPORT", "family": "companion", "targets": [who], "publish": [],
                "why": "%s|wa %s|eun 같은 곳에서 서로를 봤다고 한다." % [name_of(who), name_of(other)]}
        else:
            verdict["why"] = "%s의 진술은 %s의 말과 부딪히지 않는다." % [name_of(other), name_of(who)]
        return _finish_verdict(verdict)
    var item := fragment(evidence_ref)
    var type := str(item.get("type", ""))
    var owner := str(item.get("owner", ""))
    if owner == who or str(item.get("via", "")) == who:
        verdict = {"result": "SAME_SOURCE", "why": "그건 %s 자신이 한 말이다. 같은 사람의 말로는 서로를 확인할 수 없다." % name_of(who)}
        return _finish_verdict(verdict)
    if type == "EXPERT_INFERENCE":
        verdict["why"] = "그 소견은 %s|i 어디 있었는지를 말하지 않는다." % name_of(who)
        return _finish_verdict(verdict)
    var placed := _placed(item)
    if who not in Array(placed["people"]):
        verdict["why"] = "그 %s|eun %s|eul 가리키지 않는다." % ["기록" if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"] else "말", name_of(who)]
        return _finish_verdict(verdict)
    if type == "BENIGN_EXPOSURE" and _confession_visible("player", who) and bool(stage_state().get("confessions", {}).get(who, {}).get("public", false)):
        verdict = {"result": "ALREADY_EXPLAINED", "publish": [evidence_ref], "targets": [who],
            "why": "%s|i 그곳에 없었던 이유는 이미 모두 앞에서 설명됐다." % name_of(who)}
        return _finish_verdict(verdict)
    if str(placed["room"]) == where or bool(placed["routine"]) and str(placed["room"]) == where:
        verdict = {"result": "SUPPORT", "family": "place", "targets": [who], "publish": [evidence_ref],
            "why": "그 %s|eun %s|i 말한 곳과 같은 곳을 가리킨다." % ["기록" if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"] else "말", name_of(who)]}
        return _finish_verdict(verdict)
    if bool(placed["routine"]):
        verdict = {"result": "UNCLEAR", "publish": [evidence_ref], "targets": [who],
            "why": "그 관찰은 사건 전의 일이다. 그 뒤에 자리를 옮겼을 수 있다."}
        return _finish_verdict(verdict)
    if bool(placed["hearsay"]):
        verdict = {"result": "HEARSAY_ONLY", "publish": [evidence_ref], "targets": [who],
            "why": "전해 들은 말만으로는 %s의 말을 뒤집기 어렵다. 본 사람에게 직접 확인해야 한다." % name_of(who)}
        return _finish_verdict(verdict)
    if bool(placed["specific"]):
        verdict = {"result": "CONTRADICTION", "family": "place", "targets": [who], "publish": [evidence_ref],
            "why": "%s|eun %s에 있었다고 했지만, %s|eun %s|eul %s 쪽에 둔다." % [name_of(who), _place_of(who, where), _evidence_name(item), name_of(who), room_name(str(placed["room"]))]}
        return _finish_verdict(verdict)
    # A group: this alone narrows, it does not contradict. Two sources whose
    # groups meet only at this person do.
    var group: Array = Array(placed["people"]).filter(func(x): return is_alive(str(x)) or str(x) == who)
    if second_ref != "" and not second_ref.begins_with("claim:") and not second_ref.begins_with("earlier:"):
        var other_item := fragment(second_ref)
        var other_placed := _placed(other_item)
        # Provenance, not the last person who repeated the sentence, defines
        # independence. Direct testimony and hearsay of that same witness are
        # one source; two separate records/witnesses can corroborate.
        var origin_a := _evidence_origin(item)
        var origin_b := _evidence_origin(other_item)
        var independent := origin_a != "" and origin_b != "" and origin_a != origin_b
        if who in Array(other_placed["people"]) and str(other_placed["room"]) == str(placed["room"]) and not bool(other_placed["hearsay"]):
            var both: Array = group.filter(func(x): return x in Array(other_placed["people"]))
            if not independent:
                verdict = {"result": "SAME_SOURCE", "publish": [evidence_ref, second_ref], "targets": [who],
                    "why": "두 정보는 같은 사람에게서 나왔다. 하나로 세야 한다."}
            elif both.size() == 1:
                verdict = {"result": "CONTRADICTION", "family": "intersection", "targets": [who], "publish": [evidence_ref, second_ref],
                    "why": "%s|wa %s|i 함께 가리키는 사람은 %s뿐이다. %s|eun %s에 있었다고 했다." % [_evidence_name(item), _evidence_name(other_item), name_of(who), name_of(who), _place_of(who, where)]}
            else:
                verdict = {"result": "NARROWS", "publish": [evidence_ref, second_ref], "targets": both,
                    "why": "두 정보가 함께 가리키는 사람은 %s|ida." % names_of(both)}
            return _finish_verdict(verdict)
    verdict = {"result": "NARROWS", "publish": [evidence_ref], "targets": group,
        "why": "그 %s|eun %s 가운데 누군가를 가리킨다. 이것만으로는 %s|ira고 말할 수 없다." % ["기록" if type == "SYSTEM_RECORD" else "말", names_of(group), name_of(who)]}
    return _finish_verdict(verdict)

func _judge_sighting(item: Dictionary, evidence_ref: String) -> Dictionary:
    var verdict := {"result": "IRRELEVANT", "why": "", "targets": [], "publish": [], "family": ""}
    var seer := str(item.get("owner", ""))
    var seen := str(item.get("subject", ""))
    var room := str(item.get("room", ""))
    if seen == "":
        verdict["why"] = "그 목격은 특정한 사람을 가리키지 않는다."
        return _finish_verdict(verdict)
    if evidence_ref.begins_with("claim:"):
        var other := evidence_ref.trim_prefix("claim:")
        var claim := _claim_visible("player", other)
        if other == seer:
            verdict = {"result": "SAME_SOURCE", "why": "같은 사람의 말이다."}
        elif other == seen and str(claim.get("position", "")) != room:
            verdict = {"result": "CONTRADICTION", "family": "sighting", "targets": [seer, seen],
                "why": "%s|eun %s|eul %s에서 봤다고 했고, %s 본인은 %s에 있었다고 한다. 둘 다 맞을 수는 없다." % [name_of(seer), name_of(seen), room_name(room), name_of(seen), room_name(str(claim.get("position", "")))]}
        elif seen in Array(claim.get("companions", [])) and str(claim.get("position", "")) != room:
            verdict = {"result": "CONTRADICTION", "family": "sighting", "targets": [seer],
                "why": "%s|eun 그 시간 %s|wa 함께 %s에 있었다고 한다. %s의 목격과 맞지 않는다." % [name_of(other), name_of(seen), room_name(str(claim.get("position", ""))), name_of(seer)]}
        else:
            verdict["why"] = "%s의 진술은 그 목격과 부딪히지 않는다." % name_of(other)
        return _finish_verdict(verdict)
    if evidence_ref.begins_with("earlier:"):
        verdict["why"] = "그 목격과는 다른 이야기다."
        return _finish_verdict(verdict)
    var other_item := fragment(evidence_ref)
    var placed := _placed(other_item)
    if str(other_item.get("owner", "")) == seer or str(other_item.get("via", "")) == seer:
        verdict = {"result": "SAME_SOURCE", "why": "같은 사람의 말이다. 서로를 확인해 주지 못한다."}
    elif seen in Array(placed["people"]) and bool(placed["specific"]) and not bool(placed["routine"]) and str(placed["room"]) != room:
        verdict = {"result": "CONTRADICTION", "family": "sighting", "targets": [seer], "publish": [evidence_ref],
            "why": "%s|eun %s|eul %s 쪽에 둔다. %s의 목격과 맞지 않는다." % [_evidence_name(other_item), name_of(seen), room_name(str(placed["room"])), name_of(seer)]}
    elif seen in Array(placed["people"]) and str(placed["room"]) == room:
        verdict = {"result": "SUPPORT", "family": "sighting", "targets": [seen], "publish": [evidence_ref],
            "why": "%s|i 같은 곳을 가리킨다. 목격을 뒷받침한다." % _evidence_name(other_item)}
    else:
        verdict["why"] = "그 정보는 %s의 목격과 관계가 없다." % name_of(seer)
    return _finish_verdict(verdict)

func _evidence_name(item: Dictionary) -> String:
    var owner := name_of(str(item.get("owner", "")))
    match str(item.get("type", "")):
        "SYSTEM_RECORD", "ALIBI_SUPPORT":
            return "%s|i 가진 %s" % [owner, str(item.get("device", "기록"))]
        "HEARSAY":
            return "%s|i 전해 들은 말" % owner
    return "%s의 목격" % owner

func _finish_verdict(verdict: Dictionary) -> Dictionary:
    for key in ["targets", "publish"]:
        if not verdict.has(key):
            verdict[key] = []
    if not verdict.has("family"):
        verdict["family"] = ""
    verdict["why"] = _josa_inline(str(verdict.get("why", "")))
    return verdict

func _intervene_link(ref: String) -> bool:
    var parts := ref.split("|")
    if parts.size() < 2:
        return false
    var statement_ref := str(parts[0])
    var evidence_ref := str(parts[1])
    var second_ref := str(parts[2]) if parts.size() > 2 else ""
    var attempted_evidence: Array = [evidence_ref]
    if second_ref != "":
        attempted_evidence.append(second_ref)
    attempted_evidence.sort()
    for prior in stage_state().get("links", []):
        if int(prior.get("day", 0)) != day or str(prior.get("statement", "")) != statement_ref:
            continue
        var prior_evidence: Array = [str(prior.get("evidence", ""))]
        if str(prior.get("second", "")) != "":
            prior_evidence.append(str(prior.get("second", "")))
        prior_evidence.sort()
        if prior_evidence == attempted_evidence:
            return false
    var verdict := judge_link(statement_ref, evidence_ref, second_ref)
    var result := str(verdict.get("result", "INVALID"))
    if result == "INVALID":
        return false
    var subject := _link_subject(statement_ref)
    var topic := "link:%s|%s" % [statement_ref, evidence_ref]
    var statement_label := ""
    for entry in link_statements():
        if str(entry["ref"]) == statement_ref:
            statement_label = str(entry["label"])
    var evidence_label := ""
    for entry in link_evidence(statement_ref):
        if str(entry["ref"]) == evidence_ref:
            evidence_label = str(entry["label"])
    _feed_line("player", subject, _voice("link", "이 두 가지를 같이 봐 주세요. %s — 그리고 %s") % [statement_label, evidence_label], "player", "anchor", topic)
    for id in verdict.get("publish", []):
        var item := fragment(str(id))
        if item.is_empty() or AstraKnowledgeModel.is_public(flags, str(id)):
            continue
        _publish_fragment(item, "player")
        stats["presented"] = int(stats.get("presented", 0)) + 1
        var owner := str(item.get("owner", ""))
        if is_alive(owner):
            _feed_social(owner, "m_confirm", _fragment_params(item), "record", subject, "support", topic)
    var links: Array = stage_state().get("links", [])
    links.append({"day": day, "statement": statement_ref, "evidence": evidence_ref, "second": second_ref, "result": result,
        "family": str(verdict.get("family", "")), "targets": Array(verdict.get("targets", [])).duplicate(), "why": str(verdict.get("why", ""))})
    stage_state()["links"] = links
    stats["links"] = int(stats.get("links", 0)) + 1
    match result:
        "CONTRADICTION":
            stats["links_held"] = int(stats.get("links_held", 0)) + 1
            _feed_narration(str(verdict["why"]))
            var targets: Array = verdict.get("targets", [])
            _mark_public_conflict(topic, targets, str(verdict["why"]))
            if statement_ref.begins_with("claim:") and evidence_ref.begins_with("claim:"):
                _raise_pair(subject, evidence_ref.trim_prefix("claim:"))
            record_player_claim(AstraClaimLedger.KIND_WITNESS, "모순을 짚었다: " + str(verdict["why"]), {"target": str(targets[0]) if not targets.is_empty() else subject})
            match str(verdict.get("family", "")):
                "excuse":
                    var contested: Dictionary = stage_state().get("contested", {})
                    contested[evidence_ref] = "settled"
                    stage_state()["contested"] = contested
                "sighting":
                    var sighting := fragment(statement_ref.trim_prefix("said:"))
                    if str(sighting.get("type", "")) == "NULL_DECEPTION":
                        var refuted: Dictionary = stage_state().get("refuted_frames", {})
                        refuted[str(sighting.get("id", ""))] = true
                        stage_state()["refuted_frames"] = refuted
                        _weaken_accusation(str(sighting.get("owner", "")), str(sighting.get("subject", "")), 0.1)
            for target in targets:
                if is_alive(str(target)):
                    _answer_contradiction(str(target), topic, str(verdict.get("family", "")))
                    if str(target) in living_null_ids():
                        _raise_player_threat(str(target), 0.3)
            var catcher := _first_active(["noa", "dax", "eli", "vale", "mira"], targets)
            if catcher != "":
                _feed_social(catcher, "m_link_holds", {"target": names_of(targets)}, "react", str(targets[0]) if not targets.is_empty() else "", "followup", topic)
        "SUPPORT":
            _feed_narration(str(verdict["why"]))
            for target in verdict.get("targets", []):
                if is_alive(str(target)):
                    _add_defense("player", str(target))
                    crew[str(target)].adjust_trust(0.04)
                    _feed_social(str(target), "m_thanks", {}, "calm", str(target), "response", topic)
        "NARROWS", "UNCLEAR", "HEARSAY_ONLY", "SAME_SOURCE", "ALREADY_EXPLAINED":
            _feed_narration(str(verdict["why"]))
            var noter := _first_active(["noa", "dax", "mira", "vale", "eli", "lyra", "rho", "sena"], [subject])
            if noter != "":
                _feed_social(noter, "m_link_partial", {}, "react", subject, "clarify", topic)
        _:
            # Nothing shown: the named person bristles, the room notices.
            stats["links_failed"] = int(stats.get("links_failed", 0)) + 1
            _feed_narration(str(verdict["why"]))
            var noter := _first_active(["noa", "dax", "mira", "eli", "vale", "lyra", "rho", "sena"], [subject])
            if noter != "":
                _feed_social(noter, "m_link_fails", {}, "react", subject, "clarify", topic)
            for observer_id in living_ids():
                crew[observer_id].adjust_trust(-LINK_PENALTY_TRUST)
            if is_alive(subject) and subject != "":
                crew[subject].adjust_stress(0.05)
                crew[subject].adjust_trust(-0.04)
    notice.emit("link", {"result": result, "targets": verdict.get("targets", [])})
    return true

# Someone whose words were just shown not to fit answers — in their own way,
# from what they know. The wording is shared by Nulls and innocents: it is
# the reason under it that differs, and an innocent with a harmless reason
# may say it now.
func _answer_contradiction(target: String, topic: String, family: String) -> void:
    var member: AstraCrewMember = crew[target]
    var role := _day_role(target)
    member.adjust_stress(0.08)
    if role == "benign":
        if _confessed_today(target) or member.trust >= 0.55 or _pick("admit:" + target + topic) < 0.4:
            if not _confessed_today(target):
                _confess(member, {"lines": []}, false)
            _publish_confession(target)
            return
        _feed_social(target, "m_deflect", {}, "defense", target, "response", topic)
        return
    if role in ["actor", "cover"] or member.is_null():
        var tactic := _resistance_tactic(target, family)
        match tactic:
            "concede":
                # Give up the small point to keep the large one.
                _feed_line(target, target, AstraSocialLines.resistance_line(target, 1), "defense", "response", topic)
            "redirect":
                var other := _redirect_target(target)
                if other != "":
                    _feed_social(target, "m_redirect", {"target": name_of(other)}, "dispute", other, "response", topic)
                    _add_accusation(target, other, 0.4)
                else:
                    _feed_line(target, target, AstraSocialLines.resistance_line(target, 2), "defense", "response", topic)
            "credibility":
                _feed_social(target, "m_doubt_explorer", {}, "dispute", "player", "response", topic)
            "silence":
                _feed_narration("%s|eun 대답하지 않는다. 시선을 피한 채 다른 사람이 먼저 말하기를 기다린다." % name_of(target))
            _:
                _feed_line(target, target, AstraSocialLines.resistance_line(target, 0), "defense", "response", topic)
        if role == "actor" and _pick("slip:" + target + topic) < 0.18 + member.stress * 0.35:
            _partial_admit_public(member, topic)
        return
    # Honest: they hold to what they know, and whoever was with them says so.
    var claim := current_claim(target)
    var mates: Array = []
    for mate in claim.get("companions", []):
        if is_alive(str(mate)):
            mates.append(str(mate))
    _feed_social(target, "m_defend_self" if not mates.is_empty() else "m_defend_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates)), "target": "탐사요원"}, "defense", target, "response", topic)
    for mate in mates:
        if target in Array(current_claim(str(mate)).get("companions", [])):
            _feed_social(str(mate), "m_vouch", {"target": name_of(target), "pos": room_name(str(current_claim(str(mate)).get("position", "")))}, "calm", target, "support", topic)
            break
    var held: Dictionary = stage_state().get("held_firm", {})
    held[target] = day
    stage_state()["held_firm"] = held

# A Null defends in character: its style and what it can point to in public.
func _resistance_tactic(target: String, family: String) -> String:
    var style := null_style(target) if target in living_null_ids() else "QUIET"
    var roll := _pick("tactic:%s:%s:%d" % [target, family, day])
    match style:
        "DEFLECTOR":
            return "redirect" if roll < 0.6 else "source"
        "COUNTERATTACK":
            return "credibility" if roll < 0.55 else "redirect"
        "ALLY":
            return "concede" if roll < 0.5 else "source"
        _:
            return "silence" if roll < 0.35 else "concede"

# Someone else with a real, public problem to point at — never invented.
func _redirect_target(from: String) -> String:
    var best := ""
    var best_value := 0.0
    for other in living_ids():
        if other == from or str(other) in living_null_ids():
            continue
        var value := float(_public_conflicts_on(str(other))) + float(_public_heat().get(str(other), 0.0))
        if value > best_value:
            best_value = value
            best = str(other)
    return best

# Two people's words that cannot both be true only count for the room once
# someone has said so aloud.
func _raise_pair(a: String, b: String) -> void:
    var raised: Dictionary = stage_state().get("raised_pairs", {})
    raised[_pair_key(a, b)] = day
    stage_state()["raised_pairs"] = raised

func _explained_publicly(npc_id: String) -> bool:
    var entry: Dictionary = stage_state().get("confessions", {}).get(npc_id, {})
    return bool(entry.get("public", false)) and int(entry.get("day", 0)) == day

# "자기 선실" rather than "마렌은 마렌의 선실".
func _place_of(who: String, position: String) -> String:
    return "자기 선실" if position == "cabin:" + who else room_name(position)

func _pair_key(a: String, b: String) -> String:
    return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]

func _conflict_raised(a: String, b: String) -> bool:
    return int(stage_state().get("raised_pairs", {}).get(_pair_key(a, b), 0)) == day

# The room noticing the board on its own: a methodical person points at two
# alibis that cannot both be true. Only some people notice, and not always.
func _thread_claims() -> bool:
    var ids := living_ids()
    for i in range(ids.size()):
        for j in range(i + 1, ids.size()):
            var a := str(ids[i])
            var b := str(ids[j])
            if _conflict_raised(a, b):
                continue
            var kind := _visible_conflict(a, _claim_visible("", a), b, _claim_visible("", b))
            if kind == "":
                continue
            var catcher := ""
            for candidate in ["noa", "dax", "eli", "vale", "mira", "sena", "lyra", "rho"]:
                if is_alive(candidate) and candidate not in [a, b] and _pick("notice:%s:%s:%s" % [candidate, a, b]) < float(CONNECTS.get(candidate, 0.4)) * 0.42:
                    catcher = candidate
                    break
            if catcher == "":
                continue
            _raise_pair(a, b)
            var key := "contrast:%s:%s" % [a, b]
            _feed_social(catcher, "m_catch_lie", {"a": name_of(a), "b": name_of(b)}, "dispute", a, "anchor", key)
            _mark_public_conflict(key, [a, b], "%s|wa %s의 진술은 동시에 맞을 수 없다." % [name_of(a), name_of(b)])
            for speaker in [a, b]:
                var claim := current_claim(speaker)
                var mates: Array = claim.get("companions", [])
                _feed_npc(speaker, "m_alibi_with" if not mates.is_empty() else "m_alibi_alone", {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates))}, "alibi", "", "response", key)
            _set_moment("claims", {"subject": a, "members": [a, b], "speaker": catcher})
            return true
    return false

# Legacy meeting API used by 0.7.x UI code paths and tests.
func present_clue(ref: String) -> Dictionary:
    return intervene("present", ref)

func accuse(target_id: String) -> Dictionary:
    return intervene("accuse", target_id)

func defend(target_id: String) -> Dictionary:
    return intervene("defend", target_id)

func confront(a_id: String, b_id: String) -> Dictionary:
    return intervene("contrast", "%s|%s" % [a_id, b_id])

# ---------------------------------------------------------------- explorer threat (read by Nulls)

# Public moves by the explorer against a Null, dated: yesterday's push is
# remembered, today's is felt (the same fading the crew's threat gets).
func _raise_player_threat(null_id: String, amount: float) -> void:
    var log: Array = stage_state().get("player_threat_log", [])
    log.append({"null": null_id, "amount": amount, "day": day})
    stage_state()["player_threat_log"] = log

# How dangerous the explorer looks to this Null, from what the Null actually
# witnessed: public accusations and presented evidence, votes cast against it,
# and being cross-examined by the explorer in person. Never the notebook.
# Older moves weigh less, exactly as they do for the crew (night_threats).
func player_threat_for(null_id: String) -> float:
    # "player_threat" is a flat override kept for old saves and tests.
    var threat := 0.1 + float(stage_state().get("player_threat", {}).get(null_id, 0.0))
    for entry in stage_state().get("player_threat_log", []):
        if str(entry.get("null", "")) == null_id:
            threat += float(entry.get("amount", 0.0)) * (1.0 if int(entry.get("day", 0)) == day else 0.4)
    var dated: Array = stage_state().get("player_confront_log", [])
    if dated.is_empty():
        threat += 0.14 * float(stage_state().get("player_confronted", {}).get(null_id, 0))
    for entry in dated:
        if str(entry.get("npc", "")) == null_id:
            threat += 0.14 if int(entry.get("day", 0)) == day else 0.05
    for round in stage_state().get("vote_rounds", []):
        if str(Dictionary(round.get("ballots", {})).get("player", "")) == null_id:
            threat += 0.22 if int(round.get("day", 0)) == day else 0.08
    threat += 0.02 * float(stats.get("presented", 0))
    return threat

# ================================================================ vote
#
# Every legal voter names one legal target. There is no abstention anywhere.
# A unique top isolates at once. A tie goes to a runoff between the tied only;
# a tied runoff is decided by the explorer among those still tied. The
# explorer's ballot always weighs exactly one.

func vote_stage() -> String:
    return str(stage_state().get("vote_stage", "BALLOT"))

func runoff_candidates() -> Array:
    return Array(stage_state().get("runoff", [])).duplicate()

func _vote_target_for(voter_id: String, candidates: Array) -> Dictionary:
    var member: AstraCrewMember = crew[voter_id]
    var legal: Array = []
    for target in candidates:
        if str(target) != voter_id:
            legal.append(str(target))
    if legal.is_empty():
        return {"target": "", "trace": AstraDecisionModel.trace(voter_id, "vote", "", [AstraDecisionModel.reason("no_legal_vote_target", 1.0)], day)}
    if member.is_null():
        return _null_vote(voter_id, legal)
    var views := {}
    var ranked: Array = []
    for target in legal:
        # A ballot is not a hidden knowledge merge. Public material and the
        # voter's own direct experience keep their force; facts privately
        # relayed by somebody else are only weak context until the room verifies
        # them aloud. SMART play can make those facts public and restore their
        # full weight. This keeps private knowledge meaningful without letting
        # eight private notebooks silently solve the case for the explorer.
        var view := _vote_view(voter_id, str(target))
        view["score"] = float(view.get("score", 0.0)) + (_stable_noise("vote:%s:%s" % [voter_id, target]) - 0.5) * 0.04
        views[target] = view
        ranked.append(target)
    ranked.sort_custom(func(a, b): return float(views[a]["score"]) > float(views[b]["score"]))
    var top := str(ranked[0])
    var top_score := float(views[top]["score"])
    var second_score := float(views[ranked[1]]["score"]) if ranked.size() > 1 else -1.0
    # Convinced by what they themselves know or heard: the room cannot move them.
    if top_score >= conviction_need(voter_id) and top_score - second_score >= 0.08:
        var reasons: Array = views[top].get("reasons", [])
        return {"target": top, "mode": "evidence", "trace": AstraDecisionModel.trace(voter_id, "vote", top, reasons, day)}
    # Not convinced: they listen to the room, in their own way (§31).
    var best := ""
    var best_value := -99.0
    var best_reasons: Array = []
    var best_mode := "unsure"
    var best_pusher := ""
    var risk_bias := AstraDecisionModel.judgement(voter_id, "risk_bias", 0.0)
    for target in legal:
        var view: Dictionary = views[target]
        var pull := _social_pull(voter_id, str(target))
        var value := float(view["score"]) + float(pull["crowd"]) + float(pull["player"])
        if risk_bias > 0.0:
            var claim := _claim_visible(voter_id, str(target))
            if not claim.is_empty() and Array(claim.get("companions", [])).is_empty():
                value += risk_bias
        value += (_stable_noise("sv:%s:%s" % [voter_id, target]) - 0.5) * 0.16
        if value > best_value:
            best_value = value
            best = str(target)
            best_reasons = Array(view.get("reasons", [])).duplicate(true)
            best_mode = "unsure"
            best_pusher = ""
            if float(pull["player"]) >= 0.12 and float(pull["player"]) >= float(pull["crowd"]):
                best_mode = "player"
                best_pusher = "player"
                best_reasons.push_front(AstraDecisionModel.reason("PLAYER_PUSH", float(pull["player"]), "player"))
            elif float(pull["crowd"]) >= 0.12:
                best_mode = "follow"
                best_pusher = str(pull["from"])
                best_reasons.push_front(AstraDecisionModel.reason("MEETING_PUSH", float(pull["crowd"]), best_pusher))
    if best_reasons.is_empty():
        best_reasons = [AstraDecisionModel.reason("insufficient_evidence", 0.01)]
    return {"target": best, "mode": best_mode, "pusher": best_pusher, "trace": AstraDecisionModel.trace(voter_id, "vote", best, best_reasons, day)}

func _vote_view(voter_id: String, target_id: String) -> Dictionary:
    var full := suspicion_breakdown(voter_id, target_id)
    var reasons: Array = []
    var score := 0.0
    for raw in full.get("reasons", []):
        var reason: Dictionary = Dictionary(raw).duplicate(true)
        var weight := float(reason.get("weight", 0.0))
        var source := str(reason.get("source", ""))
        var item := fragment(source)
        if not item.is_empty() and not AstraKnowledgeModel.is_public(flags, source):
            var owner := str(item.get("owner", ""))
            if owner != voter_id:
                # Privately relayed evidence is real knowledge, but it is not
                # independent public verification. It can break a close call,
                # not create room-wide certainty by itself.
                weight *= 0.28
            elif str(item.get("type", "")) == "HEARSAY":
                # Even when this voter owns the retelling, its origin is still
                # another witness; preserve the existing hearsay caution.
                weight *= 0.7
        reason["weight"] = weight
        score += weight
        reasons.append(reason)
    return {"score": clampf(score, -2.0, 2.0), "reasons": reasons, "target": target_id}

# How sure someone must be before the room stops mattering to them.
func conviction_need(voter_id: String) -> float:
    return AstraDecisionModel.judgement(voter_id, "conviction") * float(AstraDifficulty.number(difficulty, "conviction_scale", 1.0))

# The pull of what was said in public on an undecided person: accusations by
# people they trust (bandwagon, relationship) and the explorer's own stance
# (regard, trust in the explorer). Defences pull the other way.
func _social_pull(voter_id: String, target_id: String) -> Dictionary:
    var member: AstraCrewMember = crew[voter_id]
    var bandwagon := AstraDecisionModel.judgement(voter_id, "bandwagon") * float(AstraDifficulty.number(difficulty, "bandwagon_scale", 1.0))
    var regard := AstraDecisionModel.judgement(voter_id, "regard")
    var crowd := 0.0
    var player := 0.0
    var strongest := ""
    var strongest_value := 0.0
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("target", "")) != target_id:
            continue
        var speaker := str(entry.get("speaker", ""))
        if speaker == voter_id:
            continue
        var age := day - int(entry.get("day", day))
        if age > 1:
            continue
        var fade := (1.0 if age == 0 else 0.35) * float(entry.get("weight", 1.0))
        if speaker == "player":
            player += regard * clampf(member.trust, 0.1, 1.0) * fade
        elif crew.has(speaker) and is_alive(speaker):
            var value := bandwagon * clampf(0.55 + member.get_affinity(speaker) * 0.6, 0.1, 1.0) * fade
            crowd += value
            if value > strongest_value:
                strongest_value = value
                strongest = speaker
    for entry in stage_state().get("public_defenses", []):
        if str(entry.get("target", "")) != target_id or int(entry.get("day", 0)) != day:
            continue
        var speaker := str(entry.get("speaker", ""))
        if speaker == "player":
            player -= regard * clampf(member.trust, 0.1, 1.0) * 0.7
        elif crew.has(speaker) and speaker != voter_id and is_alive(speaker):
            crowd -= bandwagon * clampf(0.5 + member.get_affinity(speaker) * 0.6, 0.1, 1.0) * 0.6
    return {"crowd": crowd, "player": player, "from": strongest}

# A Null votes to hide: it joins the innocent crowd against a scapegoat, and
# gives up its partner only when the partner is already lost.
func _null_vote(voter_id: String, legal: Array) -> Dictionary:
    var partner := ""
    for other in living_null_ids():
        if str(other) != voter_id:
            partner = str(other)
    var crowd := {}
    for other in eligible_voters():
        if crew[other].is_null():
            continue
        var pick := str(_vote_target_for(str(other), legal).get("target", ""))
        crowd[pick] = int(crowd.get(pick, 0)) + 1
    var innocents := living_crew_ids().size()
    if partner != "" and partner in legal and float(crowd.get(partner, 0)) >= float(innocents) * 0.6 and _stable_noise("bus:%s:%d" % [voter_id, day]) < 0.55:
        var bus_view := suspicion_breakdown(voter_id, partner, true)
        return {"target": partner, "trace": AstraDecisionModel.trace(voter_id, "vote", partner, bus_view.get("reasons", []), day), "bus": true}
    var best := ""
    var best_value := -99.0
    var style := null_style(voter_id)
    var ally := null_ally(voter_id)
    for target in legal:
        if target == partner or (target == ally and legal.size() > 2):
            continue
        var value := float(crowd.get(target, 0)) * (1.5 if style == "QUIET" else 1.0) + float(_public_heat().get(target, 0.0)) + _stable_noise("nv:%s:%s" % [voter_id, target]) * 0.3
        if str(target) == null_scapegoat(voter_id):
            value += 1.2
        if style == "COUNTERATTACK":
            value += 1.2 * _stood_against(str(target), voter_id)
        elif style == "DEFLECTOR":
            value += 0.4 * float(_public_conflicts_on(str(target)))
        if value > best_value:
            best_value = value
            best = target
    if best == "":
        best = str(legal[0])
    var view := suspicion_breakdown(voter_id, best, true)
    var reasons: Array = view.get("reasons", [])
    if reasons.is_empty():
        reasons = [AstraDecisionModel.reason("accumulated_behavior", 0.2)]
    # Said aloud, a Null's ballot sounds like anyone's: the loudest accuser of
    # that person, or the public reason, or honest-sounding doubt.
    var pusher := ""
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("target", "")) == best and int(entry.get("day", 0)) == day and str(entry.get("speaker", "")) != voter_id:
            pusher = str(entry.get("speaker", ""))
    var mode := "follow" if pusher != "" else ("evidence" if float(view.get("score", 0.0)) >= 0.25 else "unsure")
    return {"target": best, "mode": mode, "pusher": pusher, "trace": AstraDecisionModel.trace(voter_id, "vote", best, reasons, day)}

# The one innocent a Null steers the room toward today: the person its own
# false sighting named, or else whoever the room already doubts in public
# (a real, visible problem — never an invented one). Chosen once per Day.
func null_scapegoat(null_id: String) -> String:
    var plans: Dictionary = stage_state().get("null_plans", {})
    var key := "%s:%d" % [null_id, day]
    if plans.has(key) and is_alive(str(plans[key])):
        return str(plans[key])
    var goat := ""
    for item in current_packet().get("fragments", []):
        if str(item.get("type", "")) == "NULL_DECEPTION" and str(item.get("owner", "")) == null_id and AstraKnowledgeModel.is_public(flags, str(item.get("id", ""))) \
                and not bool(stage_state().get("refuted_frames", {}).get(str(item.get("id", "")), false)) and is_alive(str(item.get("subject", ""))):
            goat = str(item.get("subject", ""))
    if goat == "":
        var best := 0.0
        var heat := _public_heat()
        for other in living_ids():
            if str(other) == null_id or crew[str(other)].is_null() or str(other) == null_ally(null_id):
                continue
            var value := float(heat.get(str(other), 0.0)) + 0.5 * float(_public_conflicts_on(str(other)))
            var claim := _claim_visible("", str(other))
            if not claim.is_empty() and Array(claim.get("companions", [])).is_empty():
                value += 0.15
            value += _stable_noise("goat:%s:%s:%d" % [null_id, other, day]) * 0.1
            if value > best:
                best = value
                goat = str(other)
    if goat == "":
        return ""
    plans[key] = goat
    stage_state()["null_plans"] = plans
    return goat

# One spoken sentence per ballot, in the voter's own voice (§28, §29).
func _vote_line(voter_id: String, target_id: String, decision: Dictionary) -> String:
    var mode := str(decision.get("mode", "evidence"))
    var trace: Dictionary = decision.get("trace", {})
    var params := {"target": name_of(target_id)}
    var key := "vote_evidence"
    match mode:
        "player":
            key = "vote_player"
        "follow":
            var pusher := str(decision.get("pusher", ""))
            if pusher == "player":
                key = "vote_player"
            elif pusher != "":
                key = "vote_follow"
                params["pusher"] = name_of(pusher)
            else:
                key = "vote_unsure"
        "unsure":
            key = "vote_unsure"
    var evidence_code := ""
    for reason in trace.get("reasons", []):
        var code := str(reason.get("code", ""))
        if float(reason.get("weight", 0.0)) > 0.0 and code in ["HARD_RECORD", "TIMELINE", "DIRECT_WITNESS", "EXPERT_INFERENCE", "CONTRADICTION", "CHANGED_STORY", "FALSE_SIGHTING", "RISK", "SOCIAL_BEHAVIOR"]:
            evidence_code = code
            break
    if key == "vote_evidence":
        if evidence_code == "":
            key = "vote_unsure"
        else:
            params["reason"] = _reason_text_for(voter_id, trace.get("reasons", []).filter(func(r): return str(r.get("code", "")) == evidence_code))
    elif key == "vote_unsure" and evidence_code != "":
        # Not sure, but leaning on something real: say what.
        key = "vote_lean"
        params["reason"] = _reason_text_for(voter_id, trace.get("reasons", []).filter(func(r): return str(r.get("code", "")) == evidence_code))
    return _josa_inline(AstraSocialLines.line(voter_id, key, params, _pick(voter_id + "vl" + target_id)))

func vote_intentions(candidates: Array = []) -> Dictionary:
    var pool := candidates if not candidates.is_empty() else eligible_vote_targets()
    var result := {}
    for voter in eligible_voters():
        result[voter] = str(_vote_target_for(str(voter), pool).get("target", ""))
    return result

func vote_tally(include_player_target: String = "") -> Dictionary:
    var tally := {}
    var intentions := vote_intentions()
    for voter in intentions:
        var target := str(intentions[voter])
        if target != "":
            tally[target] = int(tally.get(target, 0)) + 1
    if include_player_target != "" and include_player_target in eligible_vote_targets():
        tally[include_player_target] = int(tally.get(include_player_target, 0)) + PLAYER_VOTE_WEIGHT
    return tally

func ballot_choice() -> Dictionary:
    return Dictionary(flags.get("ballot_choice", {"state": "unselected", "target": ""})).duplicate()

func select_ballot(state: String, target: String = "") -> bool:
    if phase != "VOTE" or vote_cast or state != "target":
        return false
    if not can_vote_for("player", target):
        return false
    flags["ballot_choice"] = {"state": "target", "target": target}
    changed.emit()
    return true

func confirm_ballot() -> Dictionary:
    var choice := ballot_choice()
    if str(choice.get("state", "")) != "target" or str(choice.get("target", "")) == "":
        return {"ok": false, "reason": "unselected"}
    if vote_stage() == "TIEBREAK":
        return resolve_tiebreak(str(choice.get("target", "")))
    return cast_vote(str(choice.get("target", "")))

func cast_vote(target_id: String, _legacy_theory: Array = [], _legacy_confidence: int = 60) -> Dictionary:
    if phase != "VOTE" or vote_cast or outcome != "" or vote_stage() == "TIEBREAK":
        return {"ok": false}
    if not player_alive():
        return {"ok": false, "reason": "dead"}
    var candidates := eligible_vote_targets()
    if target_id == "" or target_id not in candidates:
        return {"ok": false, "reason": "invalid_target"}
    var round_kind := vote_stage()
    var ballots := {}
    var traces := {}
    var reasons := {}
    var spoken := {}
    for voter in eligible_voters():
        var decision := _vote_target_for(str(voter), candidates)
        var target := str(decision.get("target", ""))
        if target == "" or not can_vote_for(str(voter), target):
            push_error("ASTRA invariant: NPC produced no legal ballot")
            continue
        ballots[voter] = target
        traces[voter] = decision.get("trace", {})
        reasons[voter] = str(Dictionary(decision.get("trace", {})).get("explanation", ""))
        spoken[voter] = _vote_line(str(voter), target, decision)
        AstraDecisionModel.append_trace(flags, decision.get("trace", {}))
    ballots["player"] = target_id
    var tally := {}
    for voter in ballots:
        tally[str(ballots[voter])] = int(tally.get(str(ballots[voter]), 0)) + (PLAYER_VOTE_WEIGHT if voter == "player" else 1)
    var top := 0
    for candidate in tally:
        top = maxi(top, int(tally[candidate]))
    var leaders: Array = []
    for candidate in candidates:
        if int(tally.get(candidate, 0)) == top:
            leaders.append(str(candidate))
    var round := {"day": day, "round": round_kind, "ballots": ballots.duplicate(), "tally": tally.duplicate(), "leaders": leaders.duplicate()}
    stage_state()["vote_rounds"].append(round)
    if str(target_id) in living_null_ids():
        _raise_player_threat(target_id, 0.0)
    last_vote = {
        "round": round_kind, "tally": tally, "intentions": ballots, "vote_reasons": reasons, "decision_traces": traces,
        "player_target": target_id, "top": top, "leaders": leaders, "isolated": "", "tie": leaders.size() > 1,
        "voters": eligible_voters().duplicate(), "eligible_targets": candidates.duplicate(), "ballots": _ballot_rows(ballots, traces, reasons, spoken), "spoken": spoken.duplicate()
    }
    if leaders.size() == 1:
        _isolate(str(leaders[0]), top, "unique_highest" if round_kind == "BALLOT" else "runoff")
    elif round_kind == "BALLOT":
        stage_state()["vote_stage"] = "RUNOFF"
        stage_state()["runoff"] = leaders.duplicate()
        flags.erase("ballot_choice")
        last_vote["result_reason"] = "runoff"
        _log("동률 · 결선 투표 · " + names_of(leaders))
        notice.emit("runoff", {"candidates": leaders.duplicate()})
    else:
        stage_state()["vote_stage"] = "TIEBREAK"
        stage_state()["runoff"] = leaders.duplicate()
        flags.erase("ballot_choice")
        last_vote["result_reason"] = "tiebreak"
        _log("결선도 동률 · 탐사요원이 결정 · " + names_of(leaders))
        notice.emit("tiebreak", {"candidates": leaders.duplicate()})
    guide_completed("vote")
    changed.emit()
    return {"ok": true, "result": last_vote}

# The final word on a tied runoff belongs to the explorer. This is the one
# place the explorer's choice is decisive on its own; it is not a second vote.
func resolve_tiebreak(target_id: String) -> Dictionary:
    if phase != "VOTE" or vote_cast or vote_stage() != "TIEBREAK" or target_id not in runoff_candidates():
        return {"ok": false}
    last_vote["tiebreak_choice"] = target_id
    _isolate(target_id, int(last_vote.get("top", 0)), "tiebreak")
    changed.emit()
    return {"ok": true, "result": last_vote}

func _ballot_rows(ballots: Dictionary, traces: Dictionary, reasons: Dictionary, spoken: Dictionary = {}) -> Array:
    var rows: Array = []
    for voter in eligible_voters():
        if not ballots.has(voter):
            continue
        var trace: Dictionary = traces.get(voter, {})
        rows.append({"voter": voter, "target": str(ballots[voter]), "state": "target", "weight": 1,
            "reason_code": str(trace.get("strongest_reason", "")), "reason": str(reasons.get(voter, "")), "line": str(spoken.get(voter, "")),
            "decision_trace": trace.duplicate(true)})
    rows.append({"voter": "player", "target": str(ballots.get("player", "")), "state": "target", "weight": PLAYER_VOTE_WEIGHT,
        "reason_code": "player_target", "reason": "탐사요원이 직접 고른 사람"})
    return rows

func _isolate(target_id: String, votes: int, reason: String) -> void:
    var member: AstraCrewMember = crew[target_id]
    member.status = AstraCrewMember.STATUS_ISOLATED
    # The role is recorded for the end of the Stage only; nothing shown now
    # says what they were.
    isolations.append({"day": day, "id": target_id, "votes": votes, "role": member.role, "reason": reason})
    vote_cast = true
    stage_state()["vote_stage"] = "DONE"
    var rounds: Array = stage_state().get("vote_rounds", [])
    if not rounds.is_empty():
        rounds[rounds.size() - 1]["isolated"] = target_id
    last_vote["isolated"] = target_id
    last_vote["result_reason"] = reason
    last_vote["isolation_text"] = "장기수면 포드가 잠긴다. 이 Stage가 끝날 때까지 %s|eun 말하지도, 투표하지도, 움직이지도 못한다." % member.display_name
    last_vote["isolation_text"] = _josa_inline(str(last_vote["isolation_text"]))
    last_vote["last_words"] = _isolated_words(target_id)
    _transcript(target_id, target_id, str(last_vote["last_words"]))
    _log("장기수면 격리 · %s (%d표)" % [member.display_name, votes])
    _fallback_selected()
    for observer_id in living_ids():
        crew[observer_id].adjust_stress(0.04)
    last_vote["aftermath"] = _build_containment_aftermath(target_id)
    var history: Array = Array(flags.get("vote_history_052", [])).duplicate(true)
    history.append({"day": day, "intentions": Dictionary(last_vote.get("intentions", {})).duplicate(), "reasons": Dictionary(last_vote.get("vote_reasons", {})).duplicate()})
    while history.size() > 8:
        history.pop_front()
    flags["vote_history_052"] = history
    _check_end("vote")
    notice.emit("vote", last_vote)

# How the isolated person takes it (§36), from what just happened, never from
# what they are: hurt when a close friend's ballot went against them, words
# for the explorer who pushed for it, confusion when nothing hard was said
# aloud against them, otherwise resigned.
func _isolated_words(target_id: String) -> String:
    var state := "resigned"
    var friend := ""
    var rounds: Array = stage_state().get("vote_rounds", [])
    var ballots: Dictionary = Dictionary(rounds.back().get("ballots", {})) if not rounds.is_empty() else {}
    var closest := 0.3
    for voter in ballots:
        if str(ballots[voter]) != target_id or str(voter) == "player" or not crew.has(str(voter)):
            continue
        var affinity: float = crew[target_id].get_affinity(str(voter))
        if affinity > closest:
            closest = affinity
            friend = str(voter)
    var pushed := false
    for entry in stage_state().get("public_accusations", []):
        if str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == target_id and int(entry.get("day", 0)) == day:
            pushed = true
    var hard_said := 0
    for item in current_packet().get("fragments", []):
        if AstraKnowledgeModel.is_public(flags, str(item.get("id", ""))) and target_id in Array(item.get("points_to", [])) and not bool(item.get("false", false)):
            hard_said += 1
    var roll := _pick("isoline:%s:%d" % [target_id, day])
    if friend != "" and roll < 0.7:
        state = "hurt"
    elif str(ballots.get("player", "")) == target_id and pushed and roll < 0.65:
        state = "at_player"
    elif hard_said == 0 and roll < 0.7:
        state = "confused"
    return AstraSocialLines.isolated_line(target_id, state, name_of(friend))

func _build_containment_aftermath(isolated: String) -> Array:
    var result: Array = []
    if isolated == "" or not crew.has(isolated):
        return result
    var member: AstraCrewMember = crew[isolated]
    result.append({"kind": "containment", "speaker": isolated, "text": "%s의 장비가 회수되고 장기수면 포드가 잠긴다." % member.display_name})
    result.append({"kind": "target", "speaker": isolated, "text": "“%s”" % str(last_vote.get("last_words", _isolated_words(isolated)))})
    # The person closest to them reacts first, as a friend; if nobody is close,
    # someone reacts as a colleague (§33).
    var friend := _most_affine(isolated)
    if friend != "" and crew[friend].get_affinity(isolated) >= 0.25:
        result.append({"kind": "observer", "speaker": friend, "text": _josa_inline(AstraSocialLines.line(friend, "after_isolation_close", {"target": member.display_name}, _pick(friend + "isoc")))})
    else:
        var observer := _first_active(["mira", "noa", "sena", "dax", "rho", "lyra", "vale", "eli"], [isolated])
        if observer != "":
            result.append({"kind": "observer", "speaker": observer, "text": _josa_inline(AstraSocialLines.line(observer, "after_isolation", {"target": member.display_name}, _pick(observer + "iso")))})
    result.append({"kind": "ship", "text": "포드가 닫힌다."})
    return result

func vote_ballots() -> Array:
    return Array(last_vote.get("ballots", [])).duplicate(true)

func vote_counts() -> Dictionary:
    var result := {"eligible": 0, "submitted": 0, "targets": 0, "missing": 0, "errors": 0, "valid_weight": 0}
    for ballot in vote_ballots():
        result["eligible"] += 1
        result["submitted"] += 1
        result["targets"] += 1
        result["valid_weight"] += int(ballot.get("weight", 1))
    return result

func vote_result_text() -> String:
    var isolated := str(last_vote.get("isolated", ""))
    if isolated != "":
        return _josa_inline("%s|i 장기수면 포드로 들어갔다." % name_of(isolated))
    match vote_stage():
        "RUNOFF": return "최다 득표가 동률이다. %s 사이에서 결선 투표를 한다." % names_of(runoff_candidates())
        "TIEBREAK": return "결선도 동률이다. 탐사요원이 %s 중 한 사람을 정해야 한다." % names_of(runoff_candidates())
    return ""

# The two people the room is most likely to isolate get one last sentence.
func final_statements() -> Array:
    if phase != "VOTE" or vote_cast:
        return []
    var tally := {}
    for voter in eligible_voters():
        var target := str(_vote_target_for(str(voter), eligible_vote_targets()).get("target", ""))
        tally[target] = int(tally.get(target, 0)) + 1
    var ranked: Array = eligible_vote_targets().duplicate()
    ranked.sort_custom(func(a, b): return int(tally.get(a, 0)) > int(tally.get(b, 0)))
    var statements: Array = []
    for npc_id in ranked.slice(0, 2):
        var member := npc(str(npc_id))
        if member == null:
            continue
        # Someone hiding something harmless says so, without saying what.
        var hiding := _day_role(member.id) == "benign" and public_contradiction_keys.has("benign:" + member.id) and not bool(stage_state().get("confessions", {}).get(member.id, {}).get("public", false))
        var text := AstraSocialLines.line(member.id, "last_plea_secret" if hiding else "last_plea", {}, _pick(member.id + "plea"))
        # What was actually raised against them today decides what they answer.
        var linked := false
        for entry in stage_state().get("links", []):
            linked = linked or (int(entry.get("day", 0)) == day and str(entry.get("result", "")) == "CONTRADICTION" and member.id in Array(entry.get("targets", [])))
        var confession: Dictionary = stage_state().get("confessions", {}).get(member.id, {})
        var accused_by_player := false
        for entry in stage_state().get("public_accusations", []):
            accused_by_player = accused_by_player or (str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == member.id and int(entry.get("day", 0)) == day)
        if bool(confession.get("public", false)) and int(confession.get("day", 0)) == day:
            text = AstraSocialLines.line(member.id, "last_explained", {}, _pick(member.id + "plea2"))
        elif linked:
            text = AstraSocialLines.line(member.id, "last_link", {}, _pick(member.id + "plea2"))
        elif accused_by_player:
            text = AstraSocialLines.line(member.id, "last_accused_by_you", {}, _pick(member.id + "plea2"))
        var defended := false
        for entry in stage_state().get("public_defenses", []):
            defended = defended or (str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == member.id and int(entry.get("day", 0)) == day)
        if defended:
            text += " " + AstraSocialLines.review_line(member.id, 2)
        else:
            for arc in stage_state().get("meeting_arcs", []):
                if str(arc.get("review_subject", arc.get("subject", ""))) == member.id and bool(arc.get("clarified", false)):
                    text += " " + AstraSocialLines.review_line(member.id, 0)
                    break
        statements.append({"id": member.id, "name": member.display_name, "text": _josa_inline(text), "votes_expected": int(tally.get(npc_id, 0))})
    return statements

# ================================================================ end conditions

func _check_end(stage_step: String) -> void:
    if outcome != "":
        return
    var reason := ""
    var nulls_left := living_null_ids().size()
    if not player_alive():
        outcome = "LOSE"
        reason = "player_killed"
    elif nulls_left == 0:
        outcome = "WIN"
        reason = "contained"
    elif nulls_left >= crew_side_votes():
        outcome = "LOSE"
        reason = "null_control"
    if outcome != "":
        stage_state()["outcome_reason"] = reason
        _log("Stage 판정 · %s (%s · %s)" % [outcome, reason, stage_step])

func outcome_reason() -> String:
    return str(stage_state().get("outcome_reason", ""))

# ================================================================ night
#
# Part I has no night menu: the night resolves on its own and its result opens
# the next morning. With GUARDIAN equipped and a charge left, the explorer
# picks one person (or themself) to shield first.

func night_needs_choice() -> bool:
    return protocol == "GUARDIAN" and player_alive() and guardian_charges() > 0 and outcome == ""

func guardian_charges() -> int:
    return int(stage_state().get("guardian", {}).get("charges", 0))

func night_options() -> Dictionary:
    var protect: Array = []
    if night_needs_choice():
        var last := str(stage_state().get("guardian", {}).get("last_target", ""))
        for id in ["player"] + active_participants():
            if str(id) != last:
                protect.append(str(id))
    return {"protect": protect}

func choose_night_action(kind: String, target: String) -> Dictionary:
    if phase != "NIGHT" or night_done or outcome != "":
        return {"ok": false}
    if kind == "skip":
        night_plan = {}
    else:
        var options := night_options()
        if kind != "protect" or target not in options.get("protect", []):
            push_error("ASTRA invariant: invalid night action %s -> %s" % [kind, target])
            return {"ok": false}
        night_plan = {"kind": "protect", "target": target}
        var guardian: Dictionary = stage_state().get("guardian", {})
        guardian["charges"] = int(guardian.get("charges", 0)) - 1
        guardian["last_target"] = target
        guardian["history"].append({"day": day, "target": target})
        stage_state()["guardian"] = guardian
    _resolve_night()
    night_done = true
    notice.emit("night", night_result)
    changed.emit()
    return {"ok": true, "result": night_result}

# Whom a Null would go after tonight, and why, from what the Nulls know: who
# spoke against them in public, who voted them, who keeps the kind of record
# that could expose what they did, and how hard the explorer has pushed.
func night_threats() -> Dictionary:
    var nulls := living_null_ids()
    var threats := {}
    if nulls.is_empty():
        return threats
    var packet := current_packet()
    var actor := str(packet.get("actor", ""))
    var record_type := str(packet.get("record_type", ""))
    for crew_id in living_crew_ids():
        var threat := 0.08
        for entry in stage_state().get("public_accusations", []):
            if str(entry.get("speaker", "")) == crew_id and str(entry.get("target", "")) in nulls:
                threat += 0.3 if int(entry.get("day", 0)) == day else 0.12
        for round in stage_state().get("vote_rounds", []):
            if str(Dictionary(round.get("ballots", {})).get(crew_id, "")) in nulls:
                threat += 0.22 if int(round.get("day", 0)) == day else 0.08
        for id in stage_state().get("public_presented", []):
            var item := fragment(str(id))
            if str(item.get("owner", "")) == crew_id and not Array(item.get("points_to", [])).filter(func(x): return str(x) in nulls).is_empty():
                threat += 0.35
        # Role knowledge: the Null knows which keeper's records could show
        # what it did today.
        if actor in nulls and record_type != "" and str(AstraCrewCatalog.RECORD_DOMAIN.get(crew_id, "")) == record_type:
            threat += 0.2
        threat += crew[crew_id].trust * 0.1
        threats[crew_id] = threat
    if player_alive():
        var best := 0.0
        for null_id in nulls:
            best = maxf(best, player_threat_for(str(null_id)))
        threats["player"] = best * float(AstraDifficulty.number(difficulty, "player_target_scale", 1.0))
    return threats

# The Nulls weigh the threat list their own way (§37): the most exposed Null
# decides, in its style; a door the shield covered last night cannot be covered
# again tonight, and the Nulls know the rule too; a Null spares the person its
# cover depends on. The top threat is the likeliest target, never a certainty.
func _choose_night_target() -> String:
    var threats := night_threats()
    var nulls := living_null_ids()
    if threats.is_empty() or nulls.is_empty():
        return ""
    var planner := str(nulls[0])
    var heat := _public_heat()
    for null_id in nulls:
        if float(heat.get(str(null_id), 0.0)) > float(heat.get(planner, 0.0)):
            planner = str(null_id)
    var style := null_style(planner)
    var ally := null_ally(planner)
    var shield_last := ""
    if protocol == "GUARDIAN" and guardian_charges() > 0:
        shield_last = str(stage_state().get("guardian", {}).get("last_target", ""))
    var ranked: Array = threats.keys()
    ranked.sort_custom(func(a, b): return float(threats[a]) > float(threats[b]))
    var best := ""
    var best_score := -99.0
    for id in threats:
        var score := float(threats[id])
        match style:
            "QUIET":
                # A death that points straight back is loud: the loudest
                # accuser is the one a quiet Null leaves for later.
                if str(id) == str(ranked[0]) and _stood_against(str(id), planner) > 0.4:
                    score -= 0.22
            "COUNTERATTACK":
                if str(id) != "player":
                    score += 0.25 * _stood_against(str(id), planner)
            "ALLY":
                if str(id) == ally:
                    score -= 1.0
            "DEFLECTOR":
                if str(AstraCrewCatalog.RECORD_DOMAIN.get(str(id), "")) == str(current_packet().get("record_type", "")):
                    score += 0.1
        if shield_last != "" and str(id) == shield_last:
            score += 0.15
        if crew.has(str(id)):
            score -= 0.12 * crew[planner].get_affinity(str(id))
        score += _stable_noise("night:%s:%d" % [id, day]) * 0.3
        if score > best_score:
            best_score = score
            best = str(id)
    return best

func _resolve_night() -> void:
    var report: Array = []
    var result := {"victim": "", "protected": false, "shield": false, "attacked": "", "report": []}
    var nulls := living_null_ids()
    var plan_target := str(night_plan.get("target", ""))
    var clock := AstraCaseCatalog.format_time(180 + int(_stable_noise("clock:%d" % day) * 50.0))
    if not nulls.is_empty():
        var victim := _choose_night_target()
        result["attacked"] = victim
        var shield := stage_index() == 1 and day == 1 and AstraDifficulty.flag(difficulty, "first_night_safe") and not bool(stage_state().get("shield_used", false))
        if victim == "":
            report.append("밤은 조용했다. 아무도 쓰러지지 않았다.")
        elif shield:
            stage_state()["shield_used"] = true
            result["shield"] = true
            report.append("%s, 선실 구역의 비상 격벽이 스스로 내려왔다. 누군가 %s 선실 쪽으로 가다 막혔다." % [clock, "당신의" if victim == "player" else name_of(victim) + "의"])
            report.append("초기 보안 봉쇄는 첫 각성 주기에 한 번만 작동한다. 이 보호는 반복되지 않는다.")
        elif plan_target != "" and plan_target == victim:
            result["protected"] = true
            result["victim"] = victim
            stats["protects"] = int(stats.get("protects", 0)) + 1
            report.append("%s, %s 선실 앞에서 Aegis가 침입을 차단했다." % [clock, "당신의" if victim == "player" else name_of(victim) + "의"])
            report.append("누가 문을 열려 했는지는 기록되지 않았다. 차폐막에는 손자국 대신 열 흔적만 남았다.")
        elif victim == "player":
            stage_state()["player_alive"] = false
            result["victim"] = "player"
            casualties.append({"day": day, "id": "player"})
            report.append("%s, 당신의 선실 문이 조용히 열린다." % clock)
        else:
            var member: AstraCrewMember = crew[victim]
            member.status = AstraCrewMember.STATUS_OFFLINE
            casualties.append({"day": day, "id": victim})
            result["victim"] = victim
            report.append("%s, %s의 생체 신호가 끊겼다. 의무 경보는 울리지 않았다." % [clock, member.display_name])
            for observer_id in living_ids():
                crew[observer_id].adjust_stress(0.08)
            _fallback_selected()
        if plan_target != "" and not bool(result.get("protected", false)) and plan_target != victim:
            report.append("Aegis는 %s 곁에서 밤을 보냈다. 그쪽 문은 아무도 두드리지 않았다." % ("당신" if plan_target == "player" else name_of(plan_target)))
    # A log nobody opened that would have pointed at a Null does not survive
    # the night: the Null wipes it. What the explorer already opened is safe.
    # This is the cost of leaving a keeper unasked, not a timer.
    if not nulls.is_empty():
        var destroyed: Dictionary = stage_state().get("destroyed", {})
        for item in current_packet().get("fragments", []):
            var fid := str(item.get("id", ""))
            if str(item.get("type", "")) != "SYSTEM_RECORD" or not log_unread(fid) or player_knows(fid) or destroyed.has(fid):
                continue
            var hits := false
            for id in item.get("points_to", []):
                if str(id) in nulls:
                    hits = true
            if not hits:
                continue
            destroyed[fid] = true
            stats["destroyed"] = int(stats.get("destroyed", 0)) + 1
            report.append("같은 밤, %s의 %s 일부가 지워졌다. 아무도 열어 보지 않은 기록이었다." % [name_of(str(item.get("owner", ""))), str(item.get("device", AstraCaseGenerator.RECORD_DEVICE.get(str(item.get("record_type", "")), "기록")))])
            break
        stage_state()["destroyed"] = destroyed
    # Overnight, people who were together talk: hearsay spreads by a real path.
    _overnight_sharing()
    morning_report = []
    for line in report:
        morning_report.append(_josa_inline(str(line)))
    result["report"] = morning_report.duplicate()
    result["day"] = day
    night_result = result
    stage_state()["night_log"].append(result.duplicate(true))
    for line in morning_report:
        _log("밤 · " + str(line))
    _check_end("night")

func _overnight_sharing() -> void:
    var packet := current_packet()
    for id in living_crew_ids():
        var claim := current_claim(str(id))
        var group: Array = [str(id)]
        for mate in claim.get("companions", []):
            if is_alive(str(mate)) and not crew[str(mate)].is_null():
                group.append(str(mate))
        if group.size() >= 2:
            _autonomous_knowledge_share(group)

# ================================================================ result

func _finalize() -> void:
    var nulls: Array = truth.get("nulls", [])
    var null_isolated := 0
    var innocent_isolated := 0
    for item in isolations:
        if str(item.get("role", "")) == "NULL":
            null_isolated += 1
        else:
            innocent_isolated += 1
    var survivors := living_crew_ids().size()
    var rows: Array = []
    var base := 1500 if outcome == "WIN" else 200
    rows.append(["Stage 판정", base])
    rows.append(["Null 격리 ×%d" % null_isolated, null_isolated * 400])
    if innocent_isolated > 0:
        rows.append(["무고한 격리 ×%d" % innocent_isolated, -innocent_isolated * 150])
    rows.append(["생존 승무원 ×%d" % survivors, survivors * 80])
    if player_alive():
        rows.append(["탐사요원 생존", 200])
    if int(stats.get("confessions", 0)) > 0:
        rows.append(["숨긴 사정 밝혀냄 ×%d" % int(stats.get("confessions", 0)), int(stats.get("confessions", 0)) * 80])
    if int(stats.get("admissions", 0)) > 0:
        rows.append(["말 바꿈 끌어냄 ×%d" % int(stats.get("admissions", 0)), int(stats.get("admissions", 0)) * 100])
    if int(stats.get("public_contradictions", 0)) > 0:
        rows.append(["공개된 모순 ×%d" % int(stats.get("public_contradictions", 0)), int(stats.get("public_contradictions", 0)) * 40])
    if int(stats.get("protects", 0)) > 0:
        rows.append(["Aegis 차단 ×%d" % int(stats.get("protects", 0)), int(stats.get("protects", 0)) * 150])
    if outcome == "WIN":
        rows.append(["신속 격리 (DAY %d)" % day, maxi(0, 4 - day) * 150])
    var total := 0
    for row in rows:
        total += int(row[1])
    total = maxi(0, total)
    var rank := "D"
    if total >= 3200:
        rank = "S"
    elif total >= 2600:
        rank = "A"
    elif total >= 2000:
        rank = "B"
    elif total >= 1200:
        rank = "C"
    var truth_rows: Array = []
    for npc_id in roster:
        var member: AstraCrewMember = crew[npc_id]
        var lies: Array = []
        for key in stage_state().get("packets", {}):
            var packet: Dictionary = stage_state()["packets"][key]
            var benign: Dictionary = packet.get("benign", {})
            if str(benign.get("npc", "")) == npc_id:
                lies.append({"day": int(key), "reason": str(benign.get("reason", "")), "text": innocent_discrepancy_text(str(benign.get("reason", "")))})
        truth_rows.append({"id": npc_id, "role": member.role, "status": member.status, "benign_lies": lies})
    var reason := outcome_reason()
    var title := "격리 완료" if outcome == "WIN" else "재구성 실패"
    var subtitle := ""
    match reason:
        "contained":
            subtitle = "마지막 Null이 포드에 잠겼다. 이 주기의 위협은 멈췄다."
        "player_killed":
            subtitle = "신호 두절 · 밤사이 당신의 생체 신호가 끊겼다. 이번 재구성은 여기서 끝난다."
        _:
            subtitle = "표에서 밀렸다 · Null 쪽 표가 나머지 사람들의 표와 같아졌다. 더 이상 누구도 포드로 보낼 수 없다."
    var chapter := AstraVoyageContent.chapter(case_id)
    final_report = {
        "outcome": outcome, "reason": reason, "title": title, "subtitle": subtitle, "rows": rows, "total": total, "rank": rank,
        "nulls": nulls.duplicate(), "truth": truth_rows, "day": day, "stage": stage_index(), "part": part(),
        "null_isolated": null_isolated, "innocent_isolated": innocent_isolated, "survivors": survivors,
        "player_alive": player_alive(), "isolations": isolations.duplicate(true), "casualties": casualties.duplicate(true),
        "protects": int(stats.get("protects", 0)), "stats": stats.duplicate(),
        "chapter": str(case_data.get("chapter", "")), "roster": roster.duplicate(), "difficulty": difficulty,
        "story": {
            "resolved": str(chapter.get("resolved", "")) if outcome == "WIN" else "",
            "open_question": str(chapter.get("open_question", "")),
            "next_hook": str(chapter.get("next_hook", "")) if outcome == "WIN" else "",
            "outro": str(chapter.get("outro", "")) if outcome == "WIN" else ""
        },
        "loop_summary": loop_summary(),
        "post_mortem": post_mortem(),
        "theory": {"grade": 0, "label": "", "matched": 0, "suspects": []},
        "mission_complete": false, "objectives": []
    }

func loop_summary() -> Dictionary:
    var lines: Array = []
    for item in isolations:
        lines.append("DAY %d · %s 장기수면 격리 — 실제로는 %s" % [int(item.get("day", 1)), AstraJosa.i(name_of(str(item.get("id", "")))), "Null" if str(item.get("role", "")) == "NULL" else "승무원"])
    for victim in casualties:
        var victim_id := str(victim.get("id", ""))
        lines.append("DAY %d 밤 · %s 신호가 끊겼다" % [int(victim.get("day", 1)), "탐사요원의" if victim_id == "player" else name_of(victim_id) + "의"])
    for night in stage_state().get("night_log", []):
        if bool(night.get("protected", false)):
            lines.append("DAY %d 밤 · Aegis가 %s|eul 지켰다" % [int(night.get("day", 1)), "탐사요원" if str(night.get("victim", "")) == "player" else name_of(str(night.get("victim", "")))])
    var cleaned: Array = []
    for line in lines:
        cleaned.append(_josa_inline(str(line)))
    return {"case_id": case_id, "day": day, "outcome": outcome, "seed": seed_value, "difficulty": difficulty, "lines": cleaned.slice(0, 8)}

# A loss should teach, and a death must not look like the game cheated. This
# names only public or first-hand reasons a Null had to fear the explorer.
func post_mortem() -> Dictionary:
    var danger: Array = []
    if outcome_reason() == "player_killed":
        for null_id in truth.get("nulls", []):
            var count := int(stage_state().get("player_confronted", {}).get(null_id, 0))
            if count > 0:
                danger.append("%s|eul 대화에서 %d번 몰아세웠다. 그 자리에 %s도 있었다." % [name_of(str(null_id)), count, name_of(str(null_id))])
            for entry in stage_state().get("public_accusations", []):
                if str(entry.get("speaker", "")) == "player" and str(entry.get("target", "")) == str(null_id):
                    danger.append("DAY %d 회의에서 %s|eul 공개적으로 지목했다." % [int(entry.get("day", 1)), name_of(str(null_id))])
            for round in stage_state().get("vote_rounds", []):
                if str(Dictionary(round.get("ballots", {})).get("player", "")) == str(null_id):
                    danger.append("DAY %d 투표에서 %s에게 표를 던졌다." % [int(round.get("day", 1)), name_of(str(null_id))])
    var benign: Array = []
    for key in stage_state().get("packets", {}):
        var packet: Dictionary = stage_state()["packets"][key]
        var info: Dictionary = packet.get("benign", {})
        if not info.is_empty():
            benign.append("DAY %s · %s Null이 아니었다. %s" % [str(key), AstraJosa.eun(name_of(str(info.get("npc", "")))), innocent_discrepancy_text(str(info.get("reason", "")))])
    var cleaned: Array = []
    for line in danger:
        cleaned.append(_josa_inline(str(line)))
    return {"danger": cleaned.slice(0, 4), "innocent_lies": benign.slice(0, 4), "missed_clues": [], "innocent_lie": str(benign[0]) if not benign.is_empty() else "", "decisive_vote": ""}

func grade_theory() -> Dictionary:
    return {"grade": 0, "label": "", "matched": 0, "suspects": [], "confidence": 0, "day": 0}

# ================================================================ story scenes
#
# Mornings, Stage openings, awakenings, resolutions and failures play as a
# short queue of scenes (portrait + action + lines, sometimes a choice). The
# queue lives in the stage state, so a reload resumes on the same line.

func story_queue() -> Array:
    return stage_state().get("story_queue", [])

func story_scene() -> Dictionary:
    var queue := story_queue()
    var index := int(stage_state().get("story_index", 0))
    if index < 0 or index >= queue.size():
        return {}
    return Dictionary(queue[index])

func story_line_index() -> int:
    return int(stage_state().get("story_line", 0))

func story_finished() -> bool:
    return story_scene().is_empty()

func story_remaining() -> int:
    return maxi(0, story_queue().size() - int(stage_state().get("story_index", 0)))

# Advance one line; at the end of a scene without choices, go to the next scene.
func story_next() -> void:
    var scene := story_scene()
    if scene.is_empty():
        return
    var lines: Array = scene.get("lines", [])
    var line := story_line_index()
    if line < lines.size() - 1:
        stage_state()["story_line"] = line + 1
    elif str(scene.get("kind", "")) == "interlude":
        # Reading past a playable scene (headless play, tests) skips it.
        finish_interlude(str(scene.get("interlude", "")), "skipped")
        return
    elif Array(scene.get("choices", [])).is_empty():
        _story_advance_scene()
    changed.emit()

func story_skip() -> void:
    # Skips to the next scene that needs a choice or a hand (an interlude),
    # or to the end.
    while not story_finished():
        var scene := story_scene()
        if not Array(scene.get("choices", [])).is_empty():
            stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
            break
        if str(scene.get("kind", "")) == "interlude":
            break
        _story_advance_scene()
    changed.emit()

# ---------------------------------------------------------------- interludes

func _interlude_cast_ready(id: String) -> bool:
    var data := AstraInterludes.data(id)
    for actor in data.get("actors", []):
        if str(actor.get("id", "")) not in roster or not is_alive(str(actor.get("id", ""))):
            return false
    return not data.is_empty()

# Who the explorer is on screen: the name and look chosen at registration
# (meta per save slot, passed in by the app). The crew still say 탐사요원.
func player_profile() -> Dictionary:
    var profile := AstraExplorerCatalog.normalize(flags.get("player_profile", {}))
    if str(profile["name"]) == "":
        profile["name"] = "탐사요원"
    return profile

func set_player_profile(profile: Dictionary) -> void:
    flags["player_profile"] = AstraExplorerCatalog.normalize(profile)

func interlude_result(id: String) -> String:
    return str(stage_state().get("interludes", {}).get(id, ""))

# The playable scene is over: apply what it leaves behind and move on. The UI
# calls this with "success" or "partial"; reading past it (bots, story_next)
# counts as "skipped". Nothing here decides who is a Null (§64).
func finish_interlude(id: String, result: String, choice: String = "") -> bool:
    var scene := story_scene()
    if str(scene.get("kind", "")) != "interlude" or str(scene.get("interlude", "")) != id:
        return false
    if result.begins_with("choice:"):
        choice = result.trim_prefix("choice:")
        result = "success"
    if result not in ["success", "partial", "skipped"]:
        result = "partial"
    var done: Dictionary = stage_state().get("interludes", {})
    done[id] = result
    stage_state()["interludes"] = done
    if choice != "":
        var chosen: Dictionary = stage_state().get("interlude_choices", {})
        chosen[id] = choice
        stage_state()["interlude_choices"] = chosen
    _apply_interlude(id, result, choice)
    _story_advance_scene()
    changed.emit()
    return true

func _apply_interlude(id: String, result: String, choice: String = "") -> void:
    var data := AstraInterludes.data(id)
    var outcome_data: Dictionary = Dictionary(Dictionary(data.get("results", {})).get(result, {})).duplicate(true)
    # A choice inside the scene (which alarm to see with your own eyes)
    # changes what it leaves behind, not whether the scene counts.
    var picked: Dictionary = Dictionary(data.get("choices", {})).get(choice, {})
    if not picked.is_empty():
        outcome_data["note"] = str(picked.get("note", outcome_data.get("note", "")))
        outcome_data["grant"] = str(picked.get("grant", ""))
    var trust: Dictionary = outcome_data.get("trust", {})
    for npc_id in trust:
        if crew.has(str(npc_id)):
            crew[str(npc_id)].adjust_trust(float(trust[npc_id]))
    var grant := str(outcome_data.get("grant", ""))
    if grant != "":
        for item in current_packet().get("fragments", []):
            if str(item.get("type", "")) == grant:
                AstraKnowledgeModel.share_with(flags, str(item.get("id", "")), "player", day, "interlude")
                break
    var note := _fill_story(str(outcome_data.get("note", "")))
    if note != "" and not voyage.is_empty():
        var notes: Array = voyage.get("notes", [])
        if note not in notes:
            notes.append(note)
        voyage["notes"] = notes
    var hooks: Dictionary = stage_state().get("interlude_hooks", {})
    var hook: Dictionary = outcome_data.get("hook", {})
    for npc_id in hook:
        hooks[str(npc_id)] = {"id": id, "result": str(hook[npc_id]), "used": false}
    stage_state()["interlude_hooks"] = hooks
    var tag := str(outcome_data.get("memory_tag", ""))
    if tag != "" and not voyage.is_empty():
        var tags: Array = voyage.get("memory_tags", [])
        if tag not in tags:
            tags.append(tag)
        voyage["memory_tags"] = tags
    stats["interludes"] = int(stats.get("interludes", 0)) + 1
    if result == "success":
        stats["interludes_solved"] = int(stats.get("interludes_solved", 0)) + 1
    _log("인터루드 · %s · %s" % [str(data.get("title", id)), result])

# The first thing a person says when the explorer comes to them after an
# interlude they shared: the scene carries into the conversation (§62).
func _interlude_opener(member: AstraCrewMember) -> String:
    var hooks: Dictionary = stage_state().get("interlude_hooks", {})
    var hook: Dictionary = hooks.get(member.id, {})
    if hook.is_empty() or bool(hook.get("used", false)):
        return ""
    hook["used"] = true
    hooks[member.id] = hook
    stage_state()["interlude_hooks"] = hooks
    var data := AstraInterludes.data(str(hook.get("id", "")))
    return _fill_story(str(Dictionary(data.get("hook_lines", {})).get(member.id, {}).get(str(hook.get("result", "")), "")))

func story_choose(index: int) -> bool:
    var scene := story_scene()
    var choices: Array = scene.get("choices", [])
    if scene.is_empty() or index < 0 or index >= choices.size():
        return false
    if story_line_index() < Array(scene.get("lines", [])).size() - 1:
        stage_state()["story_line"] = Array(scene.get("lines", [])).size() - 1
    var choice: Dictionary = choices[index]
    var who := str(scene.get("speaker", ""))
    var effect := str(choice.get("effect", ""))
    # The last decision of the campaign sets the epilogue's tone (§35).
    if effect.begins_with("finale:"):
        _story_advance_scene()
        _queue_finale(effect.trim_prefix("finale:"))
        changed.emit()
        return true
    # The protocol choice is made inside the story, not in a menu (§41).
    if effect.begins_with("protocol:"):
        var picked := effect.trim_prefix("protocol:")
        if picked == "NONE" or set_protocol(picked):
            if picked == "NONE":
                protocol = "NONE"
            stage_state()["protocol_chosen"] = true
        _story_advance_scene()
        changed.emit()
        return true
    if not voyage.is_empty() and who != "":
        voyage["choices"][effect] = int(voyage["choices"].get(effect, 0)) + 1
        var delta := float(AstraVoyageContent.RESPONSES.get(who, {}).get(effect, 0.0))
        voyage["bonds"][who] = clampf(float(voyage["bonds"].get(who, 0.0)) + delta, -1.0, 1.0)
        _adjust_echo(who, str(scene.get("tag", "")), effect, delta)
        if crew.has(who):
            crew[who].adjust_trust(delta)
    var memory_tag := str(choice.get("memory_tag", ""))
    if memory_tag != "" and not voyage.is_empty():
        var tags: Array = voyage.get("memory_tags", [])
        var scoped := (who + ":" + memory_tag) if who != "" else memory_tag
        if scoped not in tags:
            tags.append(scoped)
        voyage["memory_tags"] = tags
    stage_state()["story_choice_" + str(scene.get("id", ""))] = effect
    var reaction := AstraVoyageContent.resolution_reaction(case_id, memory_tag, roster)
    _story_advance_scene()
    if not reaction.is_empty():
        var queue := story_queue()
        queue.insert(int(stage_state().get("story_index", 0)), _scene_entry(reaction, "resolution"))
        stage_state()["story_queue"] = queue
    changed.emit()
    return true

func _story_advance_scene() -> void:
    var scene := story_scene()
    if not scene.is_empty():
        var seen: Array = stage_state().get("story_seen", [])
        seen.append(str(scene.get("id", "")))
        stage_state()["story_seen"] = seen
        if not voyage.is_empty():
            _unlock_codex_from_scene(str(scene.get("id", "")))
    stage_state()["story_index"] = int(stage_state().get("story_index", 0)) + 1
    stage_state()["story_line"] = 0

func _scene_entry(data: Dictionary, kind: String) -> Dictionary:
    var entry := data.duplicate(true)
    entry["kind"] = kind
    if not entry.has("lines"):
        entry["lines"] = []
    var filled: Array = []
    for line in entry.get("lines", []):
        filled.append([str(line[0]), _fill_story(str(line[1]))])
    if filled.is_empty():
        filled.append(["", _fill_story(str(entry.get("action", "")))])
        entry["action_only"] = true
    entry["lines"] = filled
    entry["action"] = _fill_story(str(entry.get("action", "")))
    if not entry.has("choices"):
        entry["choices"] = []
    return entry

func _fill_story(text: String) -> String:
    var info := incident()
    return _josa_inline(AstraJosa.fill(text, {"time": incident_time(), "room": room_name(str(info.get("room", ""))),
        "incident": str(info.get("title", "")), "stage": str(stage_index()), "day": str(day)}))

func _set_story_queue(scenes: Array) -> void:
    stage_state()["story_queue"] = scenes
    stage_state()["story_index"] = 0
    stage_state()["story_line"] = 0

func _queue_morning(day_index: int, recovered: Array = []) -> void:
    var scenes: Array = []
    var art := str(AstraStageStory.STAGE_ART.get(case_id, "bridge"))
    var info := incident()
    if day_index == 1 and is_deep():
        var intro: Array = [["", "심층 재구성 · 깊이 %d. 깨어 있는 사람 %d명, Null %d." % [deep_depth(), active_participants().size(), null_count]]]
        var mod := deep_modifier()
        if mod != "":
            var info_mod: Dictionary = AstraDeepRun.MODIFIERS.get(mod, {})
            intro.append(["", "이번 깊이의 조건 · %s. %s" % [str(info_mod.get("name", "")), str(info_mod.get("text", ""))]])
        if protocol != "NONE":
            intro.append(["", "%s 프로토콜 장착. 어떤 프로토콜도 누가 Null인지 알려 주지는 않는다." % protocol_name()])
        scenes.append(_scene_entry({"id": "deep_intro_%d" % deep_depth(), "art": art, "speaker": "", "action": "재구성 %d" % deep_depth(), "lines": intro}, "deep"))
        scenes.append(_scene_entry({"id": "deep_incident_%d" % deep_depth(), "art": art, "speaker": _incident_expert(),
            "action": str(info.get("summary", "")),
            "lines": [[_incident_expert(), AstraSocialLines.line(_incident_expert(), "incident_note", {"room": room_name(str(info.get("room", ""))), "time": incident_time(), "stake": str(info.get("stake", ""))}, _pick("inc1"))]]}, "incident"))
        _set_story_queue(scenes)
        return
    if day_index == 1:
        var openings := AstraStageStory.opening(case_id)
        for scene in openings:
            var entry := _scene_entry(scene, "opening")
            scenes.append(entry)
        # Every opening already tells today's incident in people's words; the
        # separate incident card is only needed when a Stage has no opening.
        if openings.is_empty():
            scenes.append(_scene_entry({"id": "day1_incident_%s" % case_id.to_lower(), "art": art, "speaker": _incident_expert(),
            "action": str(info.get("summary", "")),
            "lines": [[_incident_expert(), AstraSocialLines.line(_incident_expert(), "incident_note", {"room": room_name(str(info.get("room", ""))), "time": incident_time(), "stake": str(info.get("stake", ""))}, _pick("inc1"))]]}, "incident"))
        var interlude_id := AstraInterludes.for_case(case_id, 1)
        if interlude_id != "" and _interlude_cast_ready(interlude_id):
            var interlude := AstraInterludes.data(interlude_id)
            scenes.append(_scene_entry({"id": "interlude_" + interlude_id, "interlude": interlude_id, "art": art, "speaker": "",
                "action": str(interlude.get("title", "")), "lines": [["", str(interlude.get("title", ""))]]}, "interlude"))
        var protocol_scene := _protocol_scene(art)
        if not protocol_scene.is_empty():
            scenes.append(protocol_scene)
    else:
        var night: Dictionary = stage_state().get("night_log", []).back() if not stage_state().get("night_log", []).is_empty() else {}
        var night_lines: Array = []
        for line in morning_report:
            night_lines.append(["", str(line)])
        if night_lines.is_empty():
            night_lines.append(["", "밤은 조용히 지나갔다."])
        scenes.append(_scene_entry({"id": "night_%d" % (day_index - 1), "art": "breach", "dark": true, "speaker": "",
            "action": "DAY %d 밤. 복도 조명이 절반으로 줄어든다." % (day_index - 1), "lines": night_lines}, "night"))
        var reaction_lines: Array = []
        var victim := str(night.get("victim", ""))
        if victim != "" and victim != "player" and not bool(night.get("protected", false)):
            var mourner := _most_affine(victim)
            if mourner != "":
                reaction_lines.append([mourner, AstraSocialLines.line(mourner, "morning_mourn", {"victim": name_of(victim)}, _pick("mourn"))])
            var hard := _first_active(["sena", "dax", "eli", "rho"], [mourner])
            if hard != "":
                reaction_lines.append([hard, AstraSocialLines.line(hard, "morning_resolve", {"victim": name_of(victim)}, _pick("resolve"))])
        elif bool(night.get("protected", false)) or bool(night.get("shield", false)):
            var target := str(night.get("attacked", ""))
            var speaker := target if target != "player" and is_alive(target) else _first_active(["mira", "sena", "noa"], [])
            if speaker != "":
                reaction_lines.append([speaker, AstraSocialLines.line(speaker, "morning_relief", {"target": "탐사요원" if target == "player" else name_of(target)}, _pick("relief"))])
            var thinker := _first_active(["noa", "dax", "eli"], [speaker])
            if thinker != "":
                reaction_lines.append([thinker, AstraSocialLines.line(thinker, "morning_attacked_meaning", {"target": "탐사요원" if target == "player" else name_of(target)}, _pick("meaning"))])
        else:
            var speaker := _first_active(["mira", "lyra", "rho"], [])
            if speaker != "":
                reaction_lines.append([speaker, AstraSocialLines.line(speaker, "morning_quiet", {}, _pick("quiet"))])
        var rounds: Array = stage_state().get("vote_rounds", [])
        if not rounds.is_empty():
            var isolated := str(rounds.back().get("isolated", ""))
            var watcher := _first_active(["noa", "mira", "vale", "lyra"], [])
            if isolated != "" and watcher != "":
                reaction_lines.append([watcher, AstraSocialLines.line(watcher, "morning_after_vote", {"target": name_of(isolated)}, _pick("aftervote"))])
        if not reaction_lines.is_empty():
            scenes.append(_scene_entry({"id": "morning_%d" % day_index, "art": art, "speaker": str(reaction_lines[0][0]),
                "action": AstraStageStory.morning_mood(case_id), "lines": reaction_lines}, "morning"))
        for note in recovered:
            var by := str(note.get("by", ""))
            if is_alive(by):
                scenes.append(_scene_entry({"id": "recovered_%s" % str(note.get("id", "")), "art": art, "speaker": by, "action": "",
                    "lines": [[by, AstraSocialLines.line(by, "recovered_record", {"from": name_of(str(note.get("from", "")))}, _pick("rec"))]]}, "morning"))
        scenes.append(_scene_entry({"id": "incident_%s_%d" % [case_id.to_lower(), day_index], "art": art, "speaker": _incident_expert(),
            "action": str(info.get("summary", "")),
            "lines": [[_incident_expert(), AstraSocialLines.line(_incident_expert(), "incident_note", {"room": room_name(str(info.get("room", ""))), "time": incident_time(), "stake": str(info.get("stake", ""))}, _pick("inc"))]]}, "incident"))
        var vignette := _vignette_080()
        if vignette.is_empty():
            vignette = _morning_vignette()
        if not vignette.is_empty():
            scenes.append(vignette)
    _set_story_queue(scenes)

# Part II: the recovered security protocols are explained by the people who
# would use them, and chosen inside the scene (§41). One option is no choice,
# so Stage 5 simply fits the Aegis field and says why it is limited (§42).
const PROTOCOL_VOICE := {
    "GUARDIAN": ["sena", "Aegis 차폐막이 다시 켜졌어. 비상 격벽 전력이 딱 두 번 쓸 만큼 남았어. 밤에 한 사람 선실 앞에 세워 둘 수 있어. 너 자신도 되고. 같은 문을 이틀 연달아 지킬 수는 없어."],
    "ANALYST": ["noa", "애널리스트 권한이면 하루 한 번, 두 사람의 말이나 말과 기록을 정밀하게 대조할 수 있어요. 맞는지, 어긋나는지, 판단할 수 없는지까지만요."],
    "EMPATH": ["mira", "엠패스는 표정과 목소리의 흔들림을 읽는 보조 장치예요. 하루 한 번 더 물어보거나, 회의에서 한 번 더 말할 수 있어요. 거짓말 탐지기는 아니에요."]
}
const PROTOCOL_CHOICE := {
    "GUARDIAN": "가디언 · 밤에 한 사람을 Aegis로 지킨다 (2회)",
    "ANALYST": "애널리스트 · 하루 한 번 두 말을 정밀 대조한다",
    "EMPATH": "엠패스 · 하루 한 번 더 묻거나 더 말한다"
}

func _protocol_scene(art: String) -> Dictionary:
    var options := available_protocols()
    if options.is_empty():
        return {}
    # What the explorer used last time comes first: keeping it is one click.
    if protocol in options:
        options.erase(protocol)
        options.push_front(protocol)
    var lines: Array = []
    for id in options:
        var voice: Array = PROTOCOL_VOICE.get(str(id), [])
        if voice.size() == 2 and is_alive(str(voice[0])):
            lines.append([str(voice[0]), str(voice[1])])
        elif voice.size() == 2:
            lines.append(["", str(voice[1])])
    if options.size() == 1:
        protocol = str(options[0])
        stage_state()["protocol_chosen"] = true
        lines.append(["", "%s 프로토콜을 장착했다. 어떤 프로토콜도 누가 Null인지 알려 주지는 않는다." % protocol_name()])
        return _scene_entry({"id": "protocol_%s" % case_id.to_lower(), "art": art, "speaker": str(lines[0][0]),
            "action": "ASTRA 보안 체계가 복구된 전문 프로토콜을 띄운다.", "lines": lines}, "protocol")
    var choices: Array = []
    for id in options:
        choices.append({"label": str(PROTOCOL_CHOICE.get(str(id), str(id))), "effect": "protocol:" + str(id)})
    lines.append(["", "이번 Stage 동안 하나만 쓸 수 있다. 어느 것도 누가 Null인지 알려 주지는 않는다."])
    return _scene_entry({"id": "protocol_%s" % case_id.to_lower(), "art": art, "speaker": str(lines[0][0]),
        "action": "ASTRA 보안 체계가 복구된 전문 프로토콜 목록을 띄운다.", "lines": lines, "choices": choices}, "protocol")

# The person whose work makes them the first to explain today's incident.
func _incident_expert() -> String:
    var info := incident()
    var method := AstraStageStory.method(str(info.get("method", "")))
    for expert in method.get("experts", []):
        if is_alive(str(expert)):
            return str(expert)
    for record_type in info.get("records", []):
        var owner := AstraCrewCatalog.record_owner(str(record_type))
        if is_alive(owner):
            return owner
    var alive := living_ids()
    return str(alive[0]) if not alive.is_empty() else ""

# One small human moment from yesterday (§24-§26): someone who was accused, or
# (Part I, where one Null means the ship knows the pod holds an innocent)
# someone whose vote sent them there; otherwise now and then a habit. Never
# evidence. Every person gets each kind of scene at most once per Stage.
func _vignette_080() -> Dictionary:
    var shown: Dictionary = stage_state().get("vignettes_080", {})
    var candidates := {"voted_wrong": [], "suspected": []}
    var rounds: Array = stage_state().get("vote_rounds", [])
    if not rounds.is_empty() and null_count == 1:
        var last_round: Dictionary = rounds.back()
        var isolated := str(last_round.get("isolated", ""))
        if isolated != "" and crew.has(isolated) and not crew[isolated].is_null() and int(last_round.get("day", 0)) == day - 1:
            for voter in Dictionary(last_round.get("ballots", {})):
                if str(last_round["ballots"][voter]) == isolated and crew.has(str(voter)) and is_alive(str(voter)):
                    candidates["voted_wrong"].append(str(voter))
    for entry in stage_state().get("public_accusations", []):
        var target := str(entry.get("target", ""))
        if int(entry.get("day", 0)) == day - 1 and crew.has(target) and is_alive(target) and target not in candidates["suspected"]:
            candidates["suspected"].append(target)
    for kind in ["voted_wrong", "suspected"]:
        var options: Array = []
        for id in candidates[kind]:
            if not shown.has(kind + ":" + str(id)) and AstraStageStory.vignette(kind, str(id)).size() == 2:
                options.append(str(id))
        if options.is_empty() or _pick("v080:%s:%d" % [kind, day]) > 0.6:
            continue
        var who := str(options[int(_pick("v080who:%s:%d" % [kind, day]) * options.size()) % options.size()])
        return _vignette_entry(kind, who, shown)
    if _pick("v080habit:%d" % day) < 0.35:
        var alive: Array = []
        for id in living_crew_ids():
            if not shown.has("habit:" + str(id)):
                alive.append(str(id))
        if not alive.is_empty():
            return _vignette_entry("habit", str(alive[int(_pick("v080habitwho:%d" % day) * alive.size()) % alive.size()]), shown)
    return {}

func _vignette_entry(kind: String, who: String, shown: Dictionary) -> Dictionary:
    shown[kind + ":" + who] = day
    stage_state()["vignettes_080"] = shown
    var pair := AstraStageStory.vignette(kind, who)
    return _scene_entry({"id": "vignette_%s_%s_%d" % [kind, who, day], "art": str(AstraStageStory.STAGE_ART.get(case_id, "lounge")),
        "speaker": who, "action": str(pair[0]), "lines": [[who, str(pair[1])]]}, "vignette")

# One small authored crew moment from the existing storylet library, between
# people who are all still here. Pure texture: it never carries evidence.
func _morning_vignette() -> Dictionary:
    if voyage.is_empty() or _pick("vignette") > 0.5:
        return {}
    var alive := active_participants()
    var candidates: Array = []
    for scene in AstraVoyageContent.all_scenes():
        var tag := str(scene.get("tag", ""))
        if tag not in ["pair", "trio", "work", "everyday"]:
            continue
        if not Array(scene.get("choices", [])).is_empty():
            continue
        if scene.has("chapters") and case_id not in Array(scene.get("chapters", [])):
            continue
        if str(scene.get("id", "")) in stage_state().get("story_seen", []) or int(voyage.get("seen_ever", {}).get(str(scene.get("id", "")), 0)) > 1:
            continue
        var ok := true
        var speakers: Array = []
        for line in scene.get("lines", []):
            speakers.append(str(line[0]))
        for key in ["speaker", "target"]:
            speakers.append(str(scene.get(key, "")))
        for who in scene.get("participants", []):
            speakers.append(str(who))
        for who in speakers:
            if who != "" and who not in alive:
                ok = false
                break
        if not ok or Array(scene.get("lines", [])).is_empty() or str(scene.get("requires", {}).get("fact", "")) != "":
            continue
        var visible := str(scene.get("action", "")) + str(scene.get("lines", []))
        for who in AstraCrewCatalog.ORDER:
            if who not in alive and AstraCrewCatalog.name_ko(who) in visible:
                ok = false
                break
        if ok:
            candidates.append(scene)
    if candidates.is_empty():
        return {}
    var picked: Dictionary = candidates[int(_pick("vigpick") * candidates.size()) % candidates.size()]
    var seen_ever: Dictionary = voyage.get("seen_ever", {})
    seen_ever[str(picked.get("id", ""))] = int(seen_ever.get(str(picked.get("id", "")), 0)) + 1
    voyage["seen_ever"] = seen_ever
    var entry := _scene_entry(picked, "vignette")
    entry["art"] = str(AstraStageStory.STAGE_ART.get(case_id, "lounge"))
    return entry

func _queue_result_story() -> void:
    if bool(stage_state().get("result_story", false)):
        return
    stage_state()["result_story"] = true
    var scenes: Array = []
    var art := str(AstraStageStory.STAGE_ART.get(case_id, "bridge"))
    if outcome == "WIN" and is_deep():
        _set_story_queue([_scene_entry({"id": "deep_clear_%d" % deep_depth(), "art": art, "speaker": "", "action": "재동기화",
            "lines": [["", "깊이 %d 재구성 완료. 기록이 한 겹 더 겹친다." % deep_depth()]]}, "resolution")])
        return
    if outcome == "WIN":
        var lines: Array = [["", AstraStageStory.resolution_open(case_id)]]
        var lost: Array = []
        for victim in casualties:
            if str(victim.get("id", "")) != "player":
                lost.append(name_of(str(victim.get("id", ""))))
        # The re-sync is told a little differently each Stage (§21).
        if not lost.is_empty():
            lines.append(["", _josa_inline(AstraStageStory.resync_line(AstraStageStory.RESYNC_LOST, stage_index()).replace("{lost}", AstraJosa.join_names(lost)))])
        var isolated_innocents: Array = []
        for item in isolations:
            if str(item.get("role", "")) != "NULL":
                isolated_innocents.append(name_of(str(item.get("id", ""))))
        if not isolated_innocents.is_empty():
            lines.append(["", _josa_inline(AstraStageStory.resync_line(AstraStageStory.RESYNC_ISOLATED, stage_index()).replace("{iso}", AstraJosa.join_names(isolated_innocents)))])
        if lost.is_empty() and isolated_innocents.is_empty():
            lines.append(["", AstraStageStory.resync_line(AstraStageStory.RESYNC_QUIET, stage_index())])
        scenes.append(_scene_entry({"id": "resolve_open_%s" % case_id.to_lower(), "art": art, "speaker": "", "action": "재동기화", "lines": lines}, "resolution"))
        var beat: Dictionary = AstraVoyageContent.resolution_thread(case_id, voyage.get("memory_tags", []) if not voyage.is_empty() else [])
        if beat.is_empty() and case_id == AstraCaseCatalog.CALIBRATION:
            beat = AstraStageStory.CALIBRATION_RESOLUTION.duplicate(true)
            beat["id"] = "story_resolution_calibration"
            beat["speaker"] = "noa"
        if not beat.is_empty():
            beat["art"] = art
            scenes.append(_scene_entry(beat, "resolution"))
        var after: Array = []
        for line in AstraStageStory.resolution_after(case_id):
            if str(line[0]) == "" or str(line[0]) in roster:
                after.append(line)
        if not after.is_empty():
            scenes.append(_scene_entry({"id": "resolve_after_%s" % case_id.to_lower(), "art": art, "speaker": str(after[0][0]), "action": "", "lines": after}, "resolution"))
        var chapter := AstraVoyageContent.chapter(case_id)
        scenes.append(_scene_entry({"id": "story_hook_%s" % case_id.to_lower(), "art": art, "speaker": "", "action": "",
            "lines": [["", str(chapter.get("next_hook", ""))]]}, "hook"))
        if is_campaign_finale():
            scenes.append(_scene_entry(AstraStageStory.FINALE_CHOICE, "finale"))
        if not voyage.is_empty():
            voyage["story_resolution_seen"] = true
            voyage["story_hook_seen"] = true
            var fact := str(chapter.get("fact", ""))
            if fact != "":
                _voyage_fact(fact, str(chapter.get("discovery", "")), "RECORD")
    else:
        var failure := AstraStageStory.failure(outcome_reason(), stage_index())
        scenes.append(_scene_entry({"id": "failure_%s" % outcome_reason(), "art": "breach", "dark": true, "speaker": "",
            "action": str(failure.get("action", "")), "lines": failure.get("lines", [])}, "failure"))
        if outcome_reason() == "player_killed" and not voyage.is_empty():
            var echo := _last_words_heard()
            if not echo.is_empty():
                voyage["death_echo"] = {"case_id": case_id, "line": str(echo.get("text", "")), "speaker": str(echo.get("speaker", "")), "stage": stage_index()}
    _set_story_queue(scenes)

# The last Stage of the campaign, cleared (not in Deep Reconstruction).
func is_campaign_finale() -> bool:
    return outcome == "WIN" and not is_deep() and case_id in AstraCaseCatalog.CAMPAIGN and AstraCaseCatalog.next_stage(case_id) == ""

func finale_tone() -> String:
    return str(stage_state().get("finale_tone", ""))

# The epilogue for the decision, then what each person keeps of the
# explorer as feeling (the campaign tally), then ASTRA's last line.
func _queue_finale(choice: String) -> void:
    var tone := str(AstraStageStory.FINALE_TONE.get(choice, "DISCOVERY"))
    stage_state()["finale_tone"] = tone
    if not voyage.is_empty():
        var tags: Array = voyage.get("memory_tags", [])
        tags.append("finale:" + choice)
        voyage["memory_tags"] = tags
    var queue := story_queue()
    var at := int(stage_state().get("story_index", 0))
    var extra: Array = [_scene_entry(AstraStageStory.EPILOGUES[tone], "finale")]
    var tally := _campaign_tally()
    var lines: Array = []
    for kind in ["saved", "defended", "sent_wrong"]:
        var counts: Dictionary = tally.get(kind, {})
        var best := ""
        var best_count := 0
        for id in counts:
            if int(counts[id]) > best_count and str(id) in roster and str(id) not in _callback_speakers(lines):
                best_count = int(counts[id])
                best = str(id)
        if best != "":
            var said := AstraStageStory.finale_callback(kind, best)
            if said != "":
                lines.append([best, said])
    if lines.is_empty():
        lines.append(["mira", "처음 의료실에서 괜찮냐고 물었죠. 이제야 대답을 들을 수 있을 것 같아요."])
    extra.append(_scene_entry({"id": "finale_callbacks", "art": "lounge", "speaker": str(lines[0][0]), "action": "재동기화가 끝난 아침. 사람들이 하나씩 당신에게 말을 건다.", "lines": lines}, "finale"))
    extra.append(_scene_entry(AstraStageStory.FINALE_ASTRA, "finale"))
    for index in range(extra.size()):
        queue.insert(at + index, extra[index])
    stage_state()["story_queue"] = queue
    _log("최종 선택 · %s → %s" % [choice, tone])

func _callback_speakers(lines: Array) -> Array:
    var ids: Array = []
    for line in lines:
        ids.append(str(line[0]))
    return ids

# Across the whole campaign (carried in the slot memory): whom the explorer
# stood up for, sent to a pod while innocent, shielded, lost; interludes solved.
func _campaign_tally() -> Dictionary:
    var tally: Dictionary = Dictionary(voyage.get("campaign_tally_in", {})).duplicate(true) if not voyage.is_empty() else {}
    for key in ["defended", "sent_wrong", "saved", "deaths"]:
        if not tally.has(key):
            tally[key] = {}
    if outcome == "":
        return tally
    var map := {"fell": "deaths", "sent_by_you": "sent_wrong", "shielded": "saved", "defended": "defended"}
    for event in _echo_events():
        var key := str(map.get(str(event.get("tag", "")), ""))
        if key == "":
            continue
        var counts: Dictionary = tally[key]
        counts[str(event.get("id", ""))] = int(counts.get(str(event.get("id", "")), 0)) + 1
        tally[key] = counts
    tally["interludes_solved"] = int(tally.get("interludes_solved", 0)) + int(stats.get("interludes_solved", 0))
    tally["stages"] = int(tally.get("stages", 0)) + 1
    return tally

# The last thing someone said aloud before the explorer's last night (§30 of
# the campaign brief): the explorer carries it into the retry. Only a line
# said in public, never who the Null was.
func _last_words_heard() -> Dictionary:
    for index in range(meeting_feed.size() - 1, -1, -1):
        var entry: Dictionary = meeting_feed[index]
        var speaker := str(entry.get("speaker", ""))
        var text := str(entry.get("text", ""))
        if not crew.has(speaker) or text.length() < 10 or text.length() > 70:
            continue
        return {"speaker": speaker, "text": text}
    return {}

# What the finished Stage leaves behind as feeling, not memory (Residual
# Echo): who fell at night, which innocent the explorer voted into a pod, who
# the shield saved, whom the explorer stood up for.
func _echo_events() -> Array:
    var events: Array = []
    for victim in casualties:
        var id := str(victim.get("id", ""))
        if id != "player" and crew.has(id):
            events.append({"tag": "fell", "id": id})
    for item in isolations:
        var id := str(item.get("id", ""))
        if str(item.get("role", "")) == "NULL":
            continue
        for round in stage_state().get("vote_rounds", []):
            if int(round.get("day", 0)) == int(item.get("day", 0)) and str(Dictionary(round.get("ballots", {})).get("player", "")) == id:
                events.append({"tag": "sent_by_you", "id": id})
                break
    for night in stage_state().get("night_log", []):
        var attacked := str(night.get("attacked", ""))
        if bool(night.get("protected", false)) and attacked != "" and attacked != "player":
            events.append({"tag": "shielded", "id": attacked})
    for entry in stage_state().get("public_defenses", []):
        var target := str(entry.get("target", ""))
        if str(entry.get("speaker", "")) == "player" and crew.has(target) and not crew[target].is_null():
            events.append({"tag": "defended", "id": target})
    return events

# ================================================================ rewind (1.0)
#
# A lost Stage can be rewound, once, to the morning of the Day it was lost —
# the same reconstruction, the same people, the same truth. Only the explorer
# remembers (the canon: the explorer alone carries earlier histories). What
# carries over is memory, not knowledge the crew shares: short notes of what
# the explorer heard and saw, and the names worth asking again. Nobody else
# remembers anything; nothing is made public; the explorer still has to ask.

const REWINDS_PER_STAGE := 1

func rewinds_used() -> int:
    return int(stage_state().get("rewinds", 0))

# Called on the lost session: what the explorer takes back with them.
func rewind_memory() -> Dictionary:
    var notes: Array = []
    var leads: Array = []
    for item in known_fragments(day):
        var owner := str(item.get("owner", ""))
        if owner == "" or owner == "player":
            continue
        notes.append(_josa_inline("%s|i 이렇게 말했다 — %s" % [name_of(owner), _short_text(str(item.get("text", "")))]))
        if owner not in leads:
            leads.append(owner)
        if notes.size() >= 4:
            break
    for entry in stage_state().get("links", []):
        if int(entry.get("day", 0)) == day and str(entry.get("result", "")) == "CONTRADICTION" and notes.size() < 5:
            notes.append("맞지 않던 것 — " + str(entry.get("why", "")))
    var rounds: Array = stage_state().get("vote_rounds", [])
    if not rounds.is_empty() and int(rounds.back().get("day", 0)) == day:
        var isolated := str(rounds.back().get("isolated", ""))
        if isolated != "" and outcome_reason() == "null_control":
            notes.append(_josa_inline("%s|eul 포드로 보냈지만, 그걸로 끝나지 않았다." % name_of(isolated)))
    if outcome_reason() == "player_killed":
        notes.append("그날 밤, 누군가 당신을 노렸다. 회의에서 누구를 몰아붙였는지 떠올려 본다.")
    if notes.is_empty():
        notes.append("아무에게도 제대로 묻지 못했다. 이번에는 누구에게 먼저 갈지 정해야 한다.")
    return {"day": day, "notes": notes, "leads": leads, "reason": outcome_reason()}

# Called on the restored morning session.
func apply_rewind(memory: Dictionary, used: int) -> void:
    stage_state()["rewinds"] = used
    stage_state()["echo_notes"] = Array(memory.get("notes", [])).duplicate()
    stage_state()["echo_leads"] = Array(memory.get("leads", [])).duplicate()
    var lines: Array = [["", "숨이 멎는 감각 — 그리고 다시 아침이다. 같은 방, 같은 사람들. 기억하는 사람은 당신뿐이다."]]
    for note in Array(memory.get("notes", [])).slice(0, 4):
        lines.append(["", "기억 · " + str(note)])
    lines.append(["", "그들은 아무것도 모른다. 다시 물어야 한다. 이번에는 무엇을 다르게 할지 정할 수 있다."])
    _insert_morning_scene(_scene_entry({"id": "rewind_%d_%d" % [day, used], "art": str(AstraStageStory.STAGE_ART.get(case_id, "bridge")),
        "speaker": "", "action": "되감기", "lines": lines}, "echo"))
    _log("되감기 · DAY %d 아침 (%d/%d)" % [day, used, REWINDS_PER_STAGE])
    changed.emit()

func rewind_notes() -> Array:
    return Array(stage_state().get("echo_notes", [])).duplicate()

# ================================================================ UI helpers

func header_info() -> Dictionary:
    var counts := status_counts()
    return {
        "part": AstraCaseCatalog.part_label(case_id), "stage": stage_index(),
        "title": str(case_data.get("title", "")), "title_ko": str(AstraVoyageContent.chapter(case_id).get("title", "")),
        "day": day, "alive": int(counts["active"]) + (1 if player_alive() else 0),
        "active": int(counts["active"]), "isolated": int(counts["isolated"]), "lost": int(counts["offline"]),
        "player_alive": player_alive(),
        "conversations_left": conversations_left(), "conversations_max": conversations_max(),
        "protocol": protocol, "protocol_name": protocol_name(), "guardian_charges": guardian_charges(),
        "next": next_step_text()
    }

# The single line that says what to do now. Nothing else on screen repeats it.
func next_step_text() -> String:
    if outcome != "" and phase != "RESULT":
        return "이번 Stage의 결말이 정해졌습니다."
    match phase:
        "BRIEFING":
            if not story_finished():
                return "아침입니다. 장면을 끝까지 보세요."
            return "누구의 말을 먼저 들을지 고르세요. 오늘 대화는 %d번입니다." % conversations_max()
        "INTERROGATION":
            var open := ""
            for id in _conversation_book():
                if followups_left(str(id)) > 0:
                    open = str(id)
            if open != "" and open == selected_id:
                return "%s에게 이어서 물을 수 있습니다. (추가 질문 %d)" % [name_of(open), followups_left(open)]
            if conversations_left() > 0:
                return "한 사람과 더 이야기할 수 있습니다. (대화 %d / %d 남음)" % [conversations_left(), conversations_max()]
            return "오늘 대화를 모두 썼습니다. 회의를 여세요."
        "MEETING":
            if meeting_actions_left > 0:
                return "논쟁을 듣고, 맞지 않는 말이 있으면 근거와 이어서 따지세요."
            return "회의가 끝났습니다. 투표로 넘어가세요."
        "VOTE":
            if vote_cast:
                return "격리가 끝났습니다. 밤이 옵니다."
            match vote_stage():
                "RUNOFF": return "동률입니다. %s 중 한 명에게 다시 투표하세요." % names_of(runoff_candidates())
                "TIEBREAK": return "결선도 동률입니다. %s 중 누구를 격리할지 당신이 정합니다." % names_of(runoff_candidates())
            return "한 사람을 골라 투표하세요. 기권은 없습니다."
        "NIGHT":
            return "Aegis로 지킬 사람을 고르세요. 남은 차폐 %d회." % guardian_charges() if not night_done else "밤이 지나갔습니다."
    return ""

# Kept for the 0.7.x objective strip and help screen.
func current_objective() -> Dictionary:
    var text := next_step_text()
    return {"text": text, "description": text, "action_label": advance_label(), "action_target": "", "rooms": [], "binding": false, "phase_flow": AstraCaseCatalog.phase_flow(case_id)}

func phase_hint() -> String:
    return ""

func action_budget() -> Dictionary:
    match phase:
        "INTERROGATION":
            return {"label": "대화", "left": conversations_left(), "max": conversations_max()}
        "MEETING":
            return {"label": "개입", "left": meeting_actions_left, "max": interventions_max()}
    return {}

func phase_exhausted() -> bool:
    match phase:
        "BRIEFING":
            return story_finished()
        "INTERROGATION":
            if conversations_left() > 0:
                return false
            for id in _conversation_book():
                if followups_left(str(id)) > 0:
                    return false
            return true
        "MEETING":
            return meeting_actions_left <= 0
        "VOTE":
            return vote_cast
        "NIGHT":
            return night_done
    return false

func situation_line() -> String:
    var info := header_info()
    var parts: Array = ["생존 %d" % int(info["alive"])]
    if int(info["isolated"]) > 0:
        parts.append("격리 %d" % int(info["isolated"]))
    if int(info["lost"]) > 0:
        parts.append("사망 %d" % int(info["lost"]))
    return "  ·  ".join(PackedStringArray(parts))

func time_caption() -> String:
    return situation_line()

func difficulty_name() -> String:
    return AstraDifficulty.mode_name(difficulty)

func active_roster() -> Array:
    return roster.duplicate()

func status_label(npc_id: String) -> String:
    var member := npc(npc_id)
    if member == null:
        return "알 수 없음"
    match member.status:
        AstraCrewMember.STATUS_ACTIVE: return "정상"
        AstraCrewMember.STATUS_ISOLATED: return "장기수면 격리"
        AstraCrewMember.STATUS_OFFLINE: return "생체 신호 두절"
    return str(member.status)

func status_counts() -> Dictionary:
    var result := {"active":0, "isolated":0, "offline":0}
    for npc_id in roster:
        var member := npc(str(npc_id))
        if member == null:
            continue
        match member.status:
            AstraCrewMember.STATUS_ACTIVE: result["active"] += 1
            AstraCrewMember.STATUS_ISOLATED: result["isolated"] += 1
            AstraCrewMember.STATUS_OFFLINE: result["offline"] += 1
    return result

func null_total() -> int:
    return null_count

func calendar_caption() -> String:
    return "%s · STAGE %d · DAY %d" % [AstraCaseCatalog.part_label(case_id), stage_index(), day]

func campaign_day() -> int:
    return stage_index()

# Notebook first page: today's key points, one line per person, recent
# contradictions. Detailed provenance stays behind the details toggle.
func notebook_summary() -> Dictionary:
    var today: Array = []
    today.append("%s · %s — %s" % [incident_time(), str(incident().get("title", "")), room_name(str(incident().get("room", "")))])
    for item in known_fragments(day):
        today.append(_fragment_badge(item) + " " + str(item.get("text", "")))
    for entry in stage_state().get("analyses", []):
        if int(entry.get("day", 0)) == day:
            today.append("[정밀 대조] " + str(entry.get("text", "")))
    var people: Array = []
    for npc_id in roster:
        var member := npc(str(npc_id))
        var row := {"id": str(npc_id), "status": status_label(str(npc_id)), "alive": member.is_alive(), "mark": str(marks.get(npc_id, "")), "lines": []}
        if known_claims.has(npc_id):
            var claim: Dictionary = known_claims[npc_id]
            var mates: Array = claim.get("companions", [])
            row["lines"].append("%s%s%s" % ["(정정) " if bool(claim.get("revised", false)) else "", room_name(str(claim.get("position", ""))), " · " + AstraJosa.wa(names_of(mates)) + " 함께" if not mates.is_empty() else " · 혼자"])
        if _confessed_today(str(npc_id)):
            var entry: Dictionary = stage_state()["confessions"][npc_id]
            row["lines"].append("숨긴 사정: " + innocent_discrepancy_text(str(entry.get("reason", ""))))
        var yesterday := _yesterday_claim(str(npc_id))
        if not yesterday.is_empty():
            row["lines"].append("어제: " + _packet_room(packet_for(day - 1), str(yesterday.get("position", ""))))
        people.append(row)
    var conflicts: Array = []
    for item in contradictions:
        conflicts.append(str(item.get("detail", "")))
    return {"today": today.slice(0, 6), "people": people, "contradictions": conflicts.slice(0, 5)}

func _fragment_badge(item: Dictionary) -> String:
    match str(item.get("type", "")):
        "DIRECT_WITNESS", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE":
            return "[직접 목격]"
        "SYSTEM_RECORD", "ALIBI_SUPPORT":
            return "[시스템 기록]"
        "HEARSAY":
            return "[전언]"
        "EXPERT_INFERENCE":
            return "[전문 판단]"
    return "[본인 진술]"

func fragment_badge(item: Dictionary) -> String:
    return _fragment_badge(item)

# ---------------------------------------------------------------- contradictions (explorer's view)

func has_contradiction_on(npc_id: String) -> bool:
    for item in contradictions:
        if npc_id in item.get("targets", []):
            return true
    return false

func contradictions_on(npc_id: String) -> Array:
    var result: Array = []
    for item in contradictions:
        if npc_id in item.get("targets", []):
            result.append(item)
    return result

# What the explorer can see does not fit: claims against claims, claims
# against what they were told, a person against their own earlier words.
func _recompute_contradictions() -> void:
    var result: Array = []
    var ids: Array = known_claims.keys()
    ids.sort()
    for a_index in range(ids.size()):
        for b_index in range(a_index + 1, ids.size()):
            var a := str(ids[a_index])
            var b := str(ids[b_index])
            var kind := _claim_conflict_kind(a, b)
            if kind == "":
                continue
            var ca: Dictionary = known_claims[a]
            var targets: Array = [a, b]
            var detail := ""
            match kind:
                "place":
                    detail = "%s|wa %s 모두 %s에 있었다고 했지만, 서로를 보지 못했다고 한다." % [name_of(a), name_of(b), room_name(str(ca.get("position", "")))]
                "they_vouch":
                    detail = "%s|eun %s|wa 함께 있었다고 했지만, %s|eun 다른 곳을 말했다." % [name_of(b), name_of(a), name_of(a)]
                    targets = [a]
                _:
                    detail = "%s|eun %s|wa 함께 있었다고 했지만, %s|eun 다른 곳을 말했다." % [name_of(a), name_of(b), name_of(b)]
                    targets = [b]
            result.append({"key": "claim:%s:%s" % [a, b], "kind": "companion" if kind != "place" else "witness", "targets": targets, "detail": detail})
    for item in known_fragments(day):
        var type := str(item.get("type", ""))
        if type not in ["DIRECT_WITNESS", "SYSTEM_RECORD", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
            continue
        var subject := str(item.get("subject", ""))
        if subject == "" or not known_claims.has(subject):
            continue
        var claim: Dictionary = known_claims[subject]
        if str(claim.get("position", "")) == str(item.get("room", "")):
            continue
        result.append({"key": "fragment:%s" % str(item.get("id", "")), "kind": "log" if type == "SYSTEM_RECORD" else "witness", "targets": [subject],
            "detail": "%s|eun %s에 있었다고 했지만, %s" % [name_of(subject), room_name(str(claim.get("position", ""))), str(item.get("text", ""))]})
    # A retold sighting that does not match what the witness says they saw.
    for heard in known_fragments(day):
        if str(heard.get("type", "")) != "HEARSAY":
            continue
        for seen in known_fragments(day):
            if str(seen.get("type", "")) != "DIRECT_WITNESS" or str(seen.get("owner", "")) != str(heard.get("via", "")):
                continue
            var same := Array(seen.get("points_to", [])).filter(func(x): return x in Array(heard.get("points_to", []))).size() > 0
            if same:
                continue
            result.append({"key": "hearsay:%s" % str(heard.get("id", "")), "kind": "hearsay", "targets": [],
                "detail": "%s|i 전한 말과 %s 본인이 말한 목격이 다르다. 전해 들은 쪽이 틀렸을 수 있다." % [name_of(str(heard.get("owner", ""))), name_of(str(seen.get("owner", "")))]})
    for npc_id in roster:
        for conflict in AstraClaimLedger.self_conflicts(claim_ledger, str(npc_id)):
            var a: Dictionary = conflict.get("a", {})
            var b: Dictionary = conflict.get("b", {})
            result.append({"key": "self:%s:%d:%d" % [npc_id, int(a.get("index", 0)), int(b.get("index", 0))], "kind": "changed_story", "targets": [npc_id],
                "detail": "%s|eun %s. “%s” / “%s”" % [name_of(str(npc_id)), str(conflict.get("reason", "")), str(a.get("text", "")), str(b.get("text", ""))]})
            break
    for item in manual_contradictions:
        if int(item.get("day", day)) == day:
            result.append(item.duplicate(true))
    for item in result:
        item["public"] = public_contradiction_keys.has(str(item.get("key", "")))
        item["detail"] = _josa_inline(str(item.get("detail", "")))
    contradictions = result

# ---------------------------------------------------------------- who thinks what

func relations_of(observer_id: String) -> Dictionary:
    var member := npc(observer_id)
    if member == null or not member.is_alive():
        return {}
    var suspects: Array = []
    var trusted: Array = []
    for other in living_ids():
        if other == observer_id:
            continue
        suspects.append({"id": other, "value": member.get_suspicion(other)})
        trusted.append({"id": other, "value": member.get_affinity(other)})
    suspects.sort_custom(func(a, b): return float(a["value"]) > float(b["value"]))
    trusted.sort_custom(func(a, b): return float(a["value"]) > float(b["value"]))
    var watching: Array = []
    for entry in suspects.slice(0, 2):
        if float(entry["value"]) < 0.36:
            continue
        watching.append({"id": str(entry["id"]), "strength": _feeling_word(float(entry["value"])), "reason": ""})
    var leaning: Array = []
    for entry in trusted.slice(0, 1):
        if float(entry["value"]) < 0.2:
            continue
        leaning.append({"id": str(entry["id"]), "reason": _affinity_reason(observer_id, str(entry["id"]))})
    return {"id": observer_id, "watching": watching, "leaning": leaning, "mood": member.mood_label(),
        "spoke": public_claim_history(observer_id).size(), "retracted": AstraClaimLedger.retraction_count(claim_ledger, observer_id)}

func _feeling_word(value: float) -> String:
    if value >= 0.62:
        return "강하게 의심"
    if value >= 0.45:
        return "의심"
    return "마음에 걸려 함"

func _affinity_reason(observer_id: String, target_id: String) -> String:
    if AstraCrewCatalog.affinity_bias(observer_id, target_id) > 0.05:
        return "전부터 가까운 사이"
    if not voyage.is_empty():
        var key := AstraCrewCatalog.pair_key(observer_id, target_id)
        var past: Dictionary = voyage.get("past", {}).get(key, {})
        if not past.is_empty():
            return str(past.get("summary", "함께 일해 온 사이"))
    return "이번 일에서 같은 편에 섰다"

func opinions_about(target_id: String) -> Array:
    var result: Array = []
    for observer_id in living_ids():
        if observer_id == target_id:
            continue
        var value := npc(observer_id).get_suspicion(target_id)
        if value < 0.36:
            continue
        result.append({"id": observer_id, "strength": _feeling_word(value), "reason": ""})
    return result

# ================================================================ small shared helpers

func _queue_extra_scene(scene: Dictionary, kind: String) -> void:
    if scene.is_empty():
        return
    var queue := story_queue()
    queue.append(_scene_entry(scene, kind))
    stage_state()["story_queue"] = queue

func guide_exposed(id: String) -> void:
    var learning: Dictionary = flags.get("guides", {})
    if not learning.has(id):
        learning[id] = "exposed"
    flags["guides"] = learning

func guide_completed(id: String) -> void:
    var learning: Dictionary = flags.get("guides", {})
    learning[id] = "completed"
    flags["guides"] = learning

func mastered_guides() -> Array:
    var result: Array = Array(flags.get("guides_mastered", [])).duplicate()
    for id in flags.get("guides", {}):
        if str(flags["guides"][id]) == "completed" and id not in result:
            result.append(id)
    return result

func crew_state(who: String) -> Dictionary:
    if who not in roster:
        return {"joined": false, "can_speak": false, "can_vote": false, "name_known": false}
    return {"joined": true, "join_stage": int(AstraCrewCatalog.JOIN_STAGE.get(who, 1)), "join_day": int(AstraCrewCatalog.JOIN_STAGE.get(who, 1)),
        "status": status_label(who), "can_speak": who in active_participants(), "can_vote": who in eligible_voters(), "name_known": true}

func crew_count_caption() -> String:
    return "깨어 있는 동료 %d명 · 활동 %d명 · 탐사요원 %s" % [roster.size(), active_participants().size(), "생존" if player_alive() else "신호 두절"]

# The crew member who woke for this Stage, if any. Their first appearance is
# staged in the opening (portrait, name, job, action, first line).
func newcomer() -> String:
    for id in roster:
        if int(AstraCrewCatalog.JOIN_STAGE.get(id, 1)) == stage_index() and stage_index() > 1:
            return str(id)
    return ""

func story_recap() -> Dictionary:
    var chapter := AstraVoyageContent.chapter(case_id)
    var cleared := outcome == "WIN"
    return {
        "resolution_seen": cleared, "hook_seen": cleared,
        "resolved": str(chapter.get("resolved", "")) if cleared else "",
        "open_question": str(chapter.get("open_question", "")),
        "outro": str(chapter.get("outro", "")) if cleared else "",
        "next_hook": str(chapter.get("next_hook", "")) if cleared else "",
        "question": {}
    }

func loop_reset_framing() -> Dictionary:
    var framing := AstraVoyageContent.reset_framing(case_id).duplicate(true)
    framing["remembered"] = true
    framing["loop"] = int(voyage.get("loop", 0)) + 1 if not voyage.is_empty() else 1
    return framing

# ================================================================ retained 0.5.x-0.7.x state helpers

func _hydrate_054_voyage_defaults() -> void:
    if voyage.is_empty():
        return
    if not voyage.has("loop_focus_families"): voyage["loop_focus_families"] = []
    if not voyage.has("loop_focus_events"): voyage["loop_focus_events"] = []
    if not voyage.has("loop_focus_counts"): voyage["loop_focus_counts"] = {}
    if not voyage.has("recent_focus_families"): voyage["recent_focus_families"] = []
    if not voyage.has("speaker_exposure"): voyage["speaker_exposure"] = {}
    if not voyage.has("routine_observed"): voyage["routine_observed"] = []
    if not voyage.has("routine_observations"): voyage["routine_observations"] = []
    if not voyage.has("micro_arc_state"): voyage["micro_arc_state"] = {}
    if not voyage.has("micro_arc_recent"): voyage["micro_arc_recent"] = []
    if not voyage.has("micro_arc_pity"): voyage["micro_arc_pity"] = {}
    if not voyage.has("consequence_queue"): voyage["consequence_queue"] = []
    if not voyage.has("consequence_history"): voyage["consequence_history"] = []
    if not voyage.has("consequence_stats"): voyage["consequence_stats"] = {"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0}
    if not voyage.has("relationship_feedback"): voyage["relationship_feedback"] = []
    if not voyage.has("codex_known"): voyage["codex_known"] = []
    if not voyage.has("codex_unlocks_pending"): voyage["codex_unlocks_pending"] = []
    if not voyage.has("pinned_question"): voyage["pinned_question"] = ""
    if not voyage.has("opinion_changes"): voyage["opinion_changes"] = []
    if not voyage.has("motives"): voyage["motives"] = {}
    if not voyage.has("motive_observations"): voyage["motive_observations"] = []
    if not voyage.has("incident_history"): voyage["incident_history"] = []
    if not voyage.has("active_incident"): voyage["active_incident"] = {}
    if not voyage.has("foreknowledge_used"): voyage["foreknowledge_used"] = []
    if not voyage.has("foreknowledge_reactions"): voyage["foreknowledge_reactions"] = []
    if not voyage.has("scene_seen_counts"): voyage["scene_seen_counts"] = voyage.get("seen_ever",{}).duplicate(true)
    if not voyage.has("momentum_state"): voyage["momentum_state"] = {"drought":0,"force_meaningful":false}
    if not voyage.has("delegation_history"): voyage["delegation_history"] = []
    if not voyage.has("delegation_used"): voyage["delegation_used"] = false
    if not voyage.has("cooperative_history"): voyage["cooperative_history"] = []
    if not voyage.has("information_sources"): voyage["information_sources"] = {}
    if not voyage.has("canon_post_arrival_seen"): voyage["canon_post_arrival_seen"] = []
    if Dictionary(voyage.get("motives",{})).is_empty():
        voyage["motives"] = AstraPersonalMotiveModel.assign(
            seed_value,int(voyage.get("loop",0)),case_id,roster,active_participants(),truth.get("nulls",[])
        )
    if not voyage.has("active_arcs"):
        voyage["active_arcs"] = AstraStorylets054.select_arcs(
            seed_value,int(voyage.get("loop",0)),case_id,roster,Array(voyage.get("micro_arc_recent",[])),3,
            voyage.get("micro_arc_pity",{})
        )
        voyage["micro_arc_pity"] = AstraStorylets054.update_arc_pity(
            voyage.get("micro_arc_pity",{}),roster,voyage.get("active_arcs",[])
        )
    if not voyage.has("routine_state") or Dictionary(voyage.get("routine_state",{})).is_empty():
        voyage["routine_state"] = AstraCrewRoutineModel.build(
            seed_value,int(voyage.get("loop",0)),case_id,roster,active_participants(),truth.get("nulls",[])
        )
        if not voyage.has("activity_queue"): voyage["activity_queue"] = []
        _align_activity_queue_to_routine()

# Resolves "Name|i" style inline particles in engine-built sentences.
func _josa_inline(text: String) -> String:
    var out := text
    for particle in ["eun", "ida", "ira", "i", "eul", "wa", "ro", "rang"]:
        var marker: String = "|" + str(particle)
        var guard := 0
        while out.find(marker) >= 0 and guard < 40:
            guard += 1
            var at := out.find(marker)
            var start := at
            while start > 0 and out.substr(start - 1, 1) not in [" ", "\n", "(", "“", "‘", ":"]:
                start -= 1
            var word := out.substr(start, at - start)
            out = out.substr(0, start) + AstraJosa.attach(word, str(particle)) + out.substr(at + marker.length())
    return out

func _log(text: String) -> void:
    journal.append({"day": day, "phase": phase, "text": _josa_inline(text)})
    if journal.size() > 400:
        journal.pop_front()

func _transcript(npc_id: String, speaker: String, text: String, intent: String = "") -> void:
    if not transcripts.has(npc_id):
        transcripts[npc_id] = []
    var list: Array = transcripts[npc_id]
    var entry_id := "dialogue_%s_%d_%03d" % [npc_id, day, list.size()]
    var reply_to := ""
    var thread_id := entry_id
    if not list.is_empty():
        var previous: Dictionary = list[list.size() - 1]
        if speaker != "player" and str(previous.get("speaker", "")) == "player":
            reply_to = str(previous.get("entry_id", ""))
            thread_id = str(previous.get("thread_id", reply_to))
        elif speaker == "player":
            thread_id = entry_id
        else:
            thread_id = str(previous.get("thread_id", entry_id))
    list.append({
        "entry_id": entry_id, "thread_id": thread_id, "reply_to": reply_to,
        "speaker": speaker, "text": _josa_inline(text), "day": day,
        "intent": intent, "topic": intent.to_lower()
    })
    if list.size() > 120:
        list.pop_front()

func _names(ids: Array) -> Array:
    var names: Array = []
    for npc_id in ids:
        names.append(name_of(str(npc_id)))
    return names

func _stable_noise(key: String) -> float:
    return float(abs(hash("%d:%d:%s" % [seed_value, day, key])) % 1000) / 1000.0

# ---------------------------------------------------------------- social beats

# Somebody in the room notices what the investigator keeps doing and says so.
# Only fires when there is a real pattern to name, and the speaker is never the
# person being defended — being told "you always defend me" is not a challenge.
func _maybe_challenge_player(subject_id: String) -> void:
    var observers := living_crew_ids()
    if observers.is_empty() or rng.randf() > 0.55:
        return
    var speaker := ""
    for candidate in observers:
        if candidate == subject_id:
            continue
        # Noa keeps the records and Daren argues from patterns, so they notice
        # first; anyone can, but those two are likelier.
        if candidate in ["noa", "dax"]:
            speaker = candidate
            break
        if speaker == "":
            speaker = candidate
    if speaker == "":
        return
    var remark := player_pattern_remark(speaker)
    if remark.is_empty():
        return
    var key := "challenge_%s_%d" % [str(remark["target"]), day]
    if flags.has(key):
        return
    flags[key] = true
    var target_name := name_of(str(remark["target"]))
    var text := ""
    if str(remark["kind"]) == "defend":
        text = "탐사요원. %s 얘기가 나올 때마다 먼저 끼어드시는군요. 회의 %d번 모두요." % [target_name, int(remark["count"])]
    else:
        text = "탐사요원은 %s|eul %d번 지목했습니다. 다른 이름은 한 번도 나오지 않았습니다." % [target_name, int(remark["count"])]
    _feed_line(speaker, "player", text, "react")
    _record_beat("player_pattern", [speaker], "%s가 탐사요원의 행동 패턴을 지적했다." % name_of(speaker))

func _record_beat(beat_id: String, participants: Array, summary: String) -> void:
    if AstraSocialEvents.on_cooldown(social_beats, beat_id, day):
        return
    social_beats.append({"id": beat_id, "day": day, "who": participants.duplicate(), "summary": summary})

# ---------------------------------------------------------------- claim ledger

func _record_claim(speaker: String, kind: String, scope: String, text: String, data: Dictionary = {}) -> Dictionary:
    if text.strip_edges() == "":
        return {}
    var entry := AstraClaimLedger.make_entry(speaker, kind, day, phase, scope, text, data)
    return AstraClaimLedger.record(claim_ledger, entry)

# The investigator is in the record too. NPCs cite it when they push back on the
# player, which is what stops the meeting from being a one-way interrogation.
func record_player_claim(kind: String, text: String, data: Dictionary = {}) -> void:
    var entry := AstraClaimLedger.make_entry("player", kind, day, phase, AstraClaimLedger.SCOPE_PUBLIC, text, data)
    AstraClaimLedger.record(claim_ledger, entry)
    player_claims.append(entry)

func claim_history(npc_id: String) -> Array:
    return AstraClaimLedger.by_speaker(claim_ledger, npc_id)

func public_claim_history(npc_id: String) -> Array:
    return AstraClaimLedger.by_speaker(claim_ledger, npc_id, AstraClaimLedger.SCOPE_PUBLIC)

func search_claims(needle: String) -> Array:
    return AstraClaimLedger.search(claim_ledger, needle)

func changed_story(npc_id: String) -> Array:
    return AstraClaimLedger.self_conflicts(claim_ledger, npc_id)

# How often the player has publicly backed or attacked one person. An NPC that
# notices "you have defended Sena in all three meetings" is using this (§16).
func player_stance_on(target_id: String) -> Dictionary:
    var defended := 0
    var accused := 0
    for entry in player_claims:
        if str(entry.get("target", "")) != target_id:
            continue
        if str(entry.get("kind", "")) == AstraClaimLedger.KIND_DEFEND:
            defended += 1
        elif str(entry.get("kind", "")) == AstraClaimLedger.KIND_ACCUSE:
            accused += 1
    return {"defended": defended, "accused": accused}

# A one-line reason an NPC can say out loud about the player's behaviour, or ""
# when nothing stands out. NPCs never speak from this unless it is non-empty:
# no reason, no line (§39).
func player_pattern_remark(observer_id: String) -> Dictionary:
    var best_target := ""
    var best_count := 0
    var best_kind := ""
    for target_id in roster:
        var stance := player_stance_on(target_id)
        if int(stance["defended"]) >= 2 and int(stance["defended"]) > best_count:
            best_count = int(stance["defended"])
            best_target = target_id
            best_kind = "defend"
        if int(stance["accused"]) >= 3 and int(stance["accused"]) > best_count:
            best_count = int(stance["accused"])
            best_target = target_id
            best_kind = "accuse"
    if best_target == "" or observer_id == best_target:
        return {}
    return {"target": best_target, "kind": best_kind, "count": best_count}

func _last_feed_speaker() -> String:
    if meeting_feed.is_empty():
        return ""
    return str(meeting_feed[meeting_feed.size() - 1].get("speaker", ""))

func _crowd_shift(target_id: String, amount: float, speaker_id: String) -> void:
    for observer_id in living_ids():
        if observer_id == target_id or observer_id == speaker_id:
            continue
        var observer: AstraCrewMember = crew[observer_id]
        var weight := 1.0 + observer.get_affinity(speaker_id) * 0.6 - observer.get_affinity(target_id) * 0.4
        observer.add_suspicion(target_id, amount * clampf(weight, 0.3, 1.6))

func _feed_npc(npc_id: String, key: String, params: Dictionary, kind: String, target_id: String, thread_role: String = "", topic_override: String = "") -> void:
    var text := AstraDialogue.line_fresh(npc_id, key, params, dialogue_recent, rng.randf())
    if text == "":
        return
    _feed_line(npc_id, target_id, text, kind, thread_role, topic_override)

const FEED_KIND_TO_CLAIM := {
    "alibi": AstraClaimLedger.KIND_POSITION,
    "dispute": AstraClaimLedger.KIND_WITNESS,
    "suspect": AstraClaimLedger.KIND_ACCUSE,
    "defense": AstraClaimLedger.KIND_DENY,
    "calm": AstraClaimLedger.KIND_DEFEND,
    "record": AstraClaimLedger.KIND_WITNESS
}

func can_meeting_speak(speaker_id: String) -> bool:
    # "" is the narrator (the board, a stage direction).
    return speaker_id == "" or speaker_id == "player" or speaker_id in active_participants()

func _meeting_thread_type(topic: String, kind: String) -> String:
    if kind in ["record","dispute","alibi"] or topic.begins_with("clue:") or topic.begins_with("movement:"):
        return "FACT_THREAD"
    if kind in ["defense","suspect","react","mourn","calm"] or topic.begins_with("suspicion:"):
        return "RELATION_THREAD"
    return "DECISION_THREAD"

func _meeting_topic_label(topic: String, target_id: String, kind: String) -> String:
    if topic.begins_with("movement:"):
        return "%s의 동선" % name_of(topic.trim_prefix("movement:"))
    if topic.begins_with("suspicion:"):
        return "%s에 대한 의혹" % name_of(topic.trim_prefix("suspicion:"))
    if topic.begins_with("clue:"):
        return topic.trim_prefix("clue:")
    if target_id != "" and crew.has(target_id):
        return "%s의 진술" % name_of(target_id)
    match kind:
        "record": return "공개된 기록"
        "dispute": return "엇갈린 진술"
        "suspect": return "의심과 근거"
        _: return "현재 논점"

func _feed_line(speaker_id: String, target_id: String, text: String, kind: String, thread_role: String = "", topic_override: String = "") -> void:
    if not can_meeting_speak(speaker_id):
        push_error("ASTRA invariant: inactive meeting speaker " + speaker_id)
        return
    var entry_id := "meeting_%d_%03d" % [day, meeting_feed.size()]
    var topic: String = topic_override if topic_override != "" else (target_id if target_id != "" else kind)
    var thread_id := entry_id
    var reply_to := ""
    var transition := false
    var reply_context := ""
    if not meeting_feed.is_empty():
        var previous: Dictionary = meeting_feed[meeting_feed.size() - 1]
        var force_reply := thread_role in ["response", "support", "challenge", "clarify", "followup", "close"]
        if thread_role == "anchor":
            transition = true
        elif force_reply or str(previous.get("topic", "")) == topic or (thread_role == "" and kind in ["react", "defense", "dispute", "record"]):
            thread_id = str(previous.get("thread_id", entry_id))
            reply_to = str(previous.get("entry_id", ""))
            topic = str(previous.get("topic", topic)) if force_reply else topic
            var prev_speaker := str(previous.get("speaker", ""))
            reply_context = "탐사요원의 말에" if prev_speaker == "player" else (("%s의 말에" % name_of(prev_speaker)) if prev_speaker != "" else "")
        else:
            transition = true
    var role := thread_role
    if role == "":
        role = "anchor" if reply_to == "" else ("response" if kind == "defense" else "followup")
    var entry := {
        "entry_id": entry_id, "thread_id": thread_id, "reply_to": reply_to,
        "speaker": speaker_id, "target": target_id, "topic": topic,
        "thread_type": _meeting_thread_type(topic, kind),
        "topic_label": _meeting_topic_label(topic, target_id, kind),
        "topic_transition": transition, "reply_context": reply_context,
        "thread_role": role, "text": _josa_inline(_self_refs(speaker_id, text)), "kind": kind, "day": day
    }
    meeting_feed.append(entry)
    if speaker_id != "player" and target_id != "" and kind in ["suspect","defense","dispute","react","record"]:
        var reason_code := "statement_response"
        if kind == "dispute" or kind == "record":
            reason_code = "public_statement_conflict"
        elif kind == "defense":
            reason_code = "public_verification" if float(suspicion_breakdown(speaker_id, target_id).get("score", 0.0)) < 0.0 else "relationship_support"
        elif kind == "suspect":
            reason_code = "accumulated_behavior"
        var meeting_trace := AstraDecisionModel.trace(
            speaker_id, "meeting_" + kind, target_id,
            [AstraDecisionModel.reason(reason_code, 0.7, str(entry.get("thread_id","")))], day
        )
        AstraDecisionModel.append_trace(flags, meeting_trace)
        if kind == "defense" and not voyage.is_empty():
            var tags: Array = voyage.get("memory_tags",[])
            var defense_tag := speaker_id + "_defended_" + target_id
            if defense_tag not in tags:
                tags.append(defense_tag)
            voyage["memory_tags"] = tags
    if speaker_id != "player" and FEED_KIND_TO_CLAIM.has(kind):
        var claim := current_claim(speaker_id) if kind == "alibi" else {}
        _record_claim(speaker_id, str(FEED_KIND_TO_CLAIM[kind]), AstraClaimLedger.SCOPE_PUBLIC, str(entry["text"]), {
            "target": target_id,
            "position": str(claim.get("position", "")),
            "companions": claim.get("companions", [])
        })
    notice.emit("meeting_line", entry)

# ---------------------------------------------------------------- optional AI performance

# Replaces a rule-based line in the transcript with a validated AI performance.
# Only wording changes; no state, clue or relationship value is touched.
func apply_ai_line(npc_id: String, rule_line: String, utterance: String) -> void:
    var clean := utterance.strip_edges()
    if clean == "" or not transcripts.has(npc_id):
        return
    var history: Array = transcripts[npc_id]
    for index in range(history.size() - 1, -1, -1):
        var entry: Dictionary = history[index]
        if str(entry.get("speaker", "")) == npc_id and str(entry.get("text", "")) == _josa_inline(rule_line):
            entry["text"] = clean
            entry["ai"] = true
            changed.emit()
            return

func build_ai_context(npc_id: String, intent: String, rule_line: String) -> Dictionary:
    var member := npc(npc_id)
    if member == null:
        return {}
    var allowed_facts := {}
    var refs: Array[String] = []
    for clue in known_fragments():
        refs.append(str(clue.get("id", "")))
        allowed_facts[str(clue.get("id", ""))] = str(clue.get("text", ""))
    var turns: Array = []
    var history: Array = transcripts.get(npc_id, [])
    for index in range(maxi(0, history.size() - 10), history.size()):
        turns.append(history[index].duplicate())
    var relationships := {}
    for other in roster:
        if other != npc_id:
            relationships[other] = member.get_affinity(other)
    return {
        "npc": {
            "id": member.id, "name": member.display_name, "job": member.job,
            "speech_style": str(member.info.get("speech_note", "")),
            "social_goal": str(member.info.get("social_goal", "")),
            "pressure_response": str(member.info.get("pressure_response", "")),
            "emotion": {"stress": member.stress}, "trust_player": member.trust
        },
        "scene": {"phase": phase, "situation": "player_dialogue", "intent": intent, "day": day, "rule_based_line": rule_line},
        "allowed_fact_refs": refs,
        "allowed_facts": allowed_facts,
        "allowed_target_ids": living_ids(),
        "known_evidence": refs.duplicate(),
        "relationships": relationships,
        "recent_turns": turns
    }

# ---------------------------------------------------------------- 0.4.x voyage
# Snapshot-safe state; UI only invokes the public methods below.
func begin_voyage(memory: Dictionary = {}) -> void:
    if not voyage.is_empty():
        return
    var loop_count := int(memory.get("loops", 0))
    flags["guides_mastered"] = Array(memory.get("mastered_guides",[])).duplicate()
    voyage = {"loop":loop_count, "room":"medbay", "visits":["medbay"], "facts":[], "notes":[],
        "inspected":[], "met":[], "recent":memory.get("recent", []).duplicate(), "seen":{},
        "seen_ever":memory.get("seen_ever",{}).duplicate(true),
        "recent_families":memory.get("recent_families",[]).duplicate(),
        "loop_focus_families":[], "loop_focus_events":[], "loop_focus_counts":{},
        "recent_focus_families":memory.get("recent_focus_families",[]).duplicate(),
        "rare_recent":memory.get("rare_recent",[]).duplicate(),
        "recent_signatures":memory.get("recent_signatures",[]).duplicate(), "replay_signature":"",
        "echo":memory.get("echo", {}).duplicate(true), "bonds":memory.get("bonds", {}).duplicate(true),
        "memories":{}, "past":{}, "changes":[], "actions":0, "choices":{}, "deferred":[],
        "scene":{}, "line":0, "companion":"", "inventory":[], "used_items":[], "goal_done":false,
        "previous_choices":memory.get("choices",{}).duplicate(true),"losses":memory.get("losses",[]).duplicate(),
        "relationships":memory.get("relationships",{}).duplicate(true),
        "dialogue_memory_052":memory.get("dialogue_memory_052",{}).duplicate(true),
        "player_profile":memory.get("player_profile",AstraLivingCrew.blank_player_profile()).duplicate(true),
        "pattern_remarks":[], "deviations":[], "social_theme":"", "loop_hook":{}, "hook_shown":false,
        "questions":memory.get("questions",{}).duplicate(true),
        "evidence_ownership":memory.get("evidence_ownership",{}).duplicate(true), "last_fact":"",
        "storylet_pity":memory.get("storylet_pity",{}).duplicate(true),
        "speaker_exposure":{}, "mira_optional_exposure":0,
        "visible_scene_ids":[], "visible_rare_ids":[],
        "memory_tags":memory.get("memory_tags",[]).duplicate(),
        "promises":{}, "promise_history":memory.get("promise_history",[]).duplicate(),
        "activity_queue":[], "autonomous_seen_loop":[],
        "autonomous_recent":memory.get("autonomous_recent",[]).duplicate(),
        "visible_signatures":memory.get("visible_signatures",[]).duplicate(),
        "routine_state":{}, "routine_observed":[], "routine_observations":[],
        "active_arcs":[], "micro_arc_state":{},
        "micro_arc_recent":memory.get("micro_arc_recent",[]).duplicate(),
        "micro_arc_pity":memory.get("micro_arc_pity",{}).duplicate(true),
        "consequence_queue":memory.get("consequence_carry",[]).duplicate(true),
        "consequence_history":[], "consequence_stats":{"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0},
        "relationship_feedback":[],
        "codex_known":memory.get("codex_entries_unlocked",[]).duplicate(),
        "codex_unlocks_pending":[],
        "pinned_question":str(memory.get("pinned_question","")),
        "opinion_changes":[],
        "motives":{}, "motive_observations":[],
        "incident_history":memory.get("incident_history",[]).duplicate(true), "active_incident":{},
        "foreknowledge_used":[], "foreknowledge_reactions":[],
        "scene_seen_counts":memory.get("scene_seen_counts",memory.get("seen_ever",{})).duplicate(true),
        "momentum_state":memory.get("momentum_state",{"drought":0,"force_meaningful":false}).duplicate(true),
        "delegation_history":memory.get("delegation_history",[]).duplicate(true), "delegation_used":false,
        "cooperative_history":[], "information_sources":{},
        "story_resolution_seen":false, "story_hook_seen":false,
        "canon_post_arrival_seen":memory.get("canon_post_arrival_seen",[]).duplicate()}
    voyage["chapters"] = memory.get("chapters",[]).duplicate()
    voyage["previous_review"] = str(memory.get("first_review",""))
    var previous: Dictionary = memory.get("memories", {})
    var previous_past: Dictionary = memory.get("past", {})
    for id in roster:
        var index := rng.randi_range(0,2)
        var destination := str(AstraVoyageContent.DESTINATIONS[index])
        if loop_count > 0 and previous.get(id, "") == destination:
            destination = str(AstraVoyageContent.DESTINATIONS[(index+1)%3])
        voyage["memories"][id] = destination
        if previous.has(id) and previous[id] != destination:
            voyage["changes"].append("%s의 목적지" % name_of(id) + ": " + str(previous[id]) + " → " + destination)
        var bond := float(voyage["bonds"].get(id, 0.0))
        crew[id].adjust_trust(clampf(bond * 0.2, -0.12, 0.16))
    _roll_pair_histories(previous_past)
    _init_living_relationships()
    voyage["social_theme"] = AstraLivingCrew.theme_for(seed_value, loop_count, roster)
    _avoid_duplicate_loop_signature()
    _apply_social_theme()
    voyage["replay_signature"] = _replay_signature(str(voyage["social_theme"]))
    if case_id != AstraCaseCatalog.CALIBRATION:
        voyage["loop_hook"] = AstraLivingCrew.loop_hook(str(voyage["social_theme"]), roster, loop_count)
    _ensure_curiosity_questions()
    _mark_changed_questions()
    voyage["active_arcs"] = AstraStorylets054.select_arcs(
        seed_value, loop_count, case_id, roster, voyage.get("micro_arc_recent",[]), 3,
        voyage.get("micro_arc_pity",{})
    )
    voyage["micro_arc_pity"] = AstraStorylets054.update_arc_pity(
        voyage.get("micro_arc_pity",{}),roster,voyage.get("active_arcs",[])
    )
    voyage["motives"] = AstraPersonalMotiveModel.assign(
        seed_value,loop_count,case_id,roster,active_participants(),truth.get("nulls",[])
    )
    voyage["routine_state"] = AstraCrewRoutineModel.build(
        seed_value, loop_count, case_id, roster, active_participants(), truth.get("nulls",[])
    )
    voyage["activity_queue"] = AstraCrewActivityModel.schedule(
        seed_value, loop_count, case_id, roster, active_participants(),
        voyage.get("autonomous_recent",[]), 2
    )
    _align_activity_queue_to_routine()
    # 0.8.0: there is no exploration phase. The voyage state still carries
    # relationships, loop memory, codex and callbacks; everyone awake is met.
    voyage["met"] = roster.duplicate()
    _queue_echo_beat(memory)
    changed.emit()

# One beat of residue at the first morning, at most (§16-19, §30): after a
# death, the line the explorer carried back; otherwise, sometimes, one
# person's unexplained hesitation, ease or wariness left by the last Stage.
# Never a fact about roles; never two Stages in a row unless Part II opens.
func _queue_echo_beat(memory: Dictionary) -> void:
    voyage["campaign_tally_in"] = Dictionary(memory.get("campaign_tally", {})).duplicate(true)
    voyage["echo_events_in"] = Array(memory.get("echo_events", [])).duplicate(true)
    voyage["echo_last_stage"] = int(memory.get("echo_last_stage", 0))
    if phase != "BRIEFING" or day != 1:
        return
    var death: Dictionary = memory.get("death_echo", {})
    if str(death.get("case_id", "")) == case_id and str(death.get("line", "")) != "":
        _insert_morning_scene(_scene_entry({"id": "death_echo_%s" % case_id.to_lower(), "art": "breach", "dark": true, "speaker": "",
            "action": "당신만 기억하는 문장이 있다.",
            "lines": [["", "“%s”" % str(death.get("line", ""))],
                ["", "지난 재구성, 마지막 밤이 오기 전에 들은 말이다. 이번 주기에는 아직 아무도 그 말을 하지 않았다."]]}, "echo"))
        voyage["echo_last_stage"] = stage_index()
        return
    var events: Array = memory.get("echo_events", [])
    if events.is_empty():
        return
    var chance := 1.0 if stage_index() == 5 else 0.6
    if int(memory.get("echo_last_stage", 0)) == stage_index() - 1 and stage_index() != 5:
        chance = 0.25
    if _pick("echo:%d" % stage_index()) >= chance:
        return
    for tag in ["sent_by_you", "fell", "shielded", "defended"]:
        var options: Array = []
        for event in events:
            var id := str(event.get("id", ""))
            if str(event.get("tag", "")) == tag and id in roster and id not in options and AstraStageStory.echo_line(tag, id).size() == 2:
                options.append(id)
        if options.is_empty():
            continue
        var who := str(options[int(_pick("echo_who:%d" % stage_index()) * options.size()) % options.size()])
        var pair := AstraStageStory.echo_line(tag, who)
        _insert_morning_scene(_scene_entry({"id": "echo_%s_%s" % [tag, who], "art": str(AstraStageStory.STAGE_ART.get(case_id, "medbay")), "speaker": who,
            "action": str(pair[0]), "lines": [[who, str(pair[1])]]}, "echo"))
        voyage["echo_last_stage"] = stage_index()
        stage_state()["echo_shown"] = tag
        return

# Before any playable scene and the protocol choice, after the opening.
func _insert_morning_scene(entry: Dictionary) -> void:
    var queue := story_queue()
    var at := queue.size()
    for index in range(queue.size()):
        if str(queue[index].get("kind", "")) in ["protocol", "interlude"]:
            at = index
            break
    queue.insert(at, entry)
    stage_state()["story_queue"] = queue

# Canonical (order-independent) pair history for the current roster.
#
# Every pair keeps its previous history by default; only a small, chapter-
# scaled budget of pairs are allowed to reroll each loop (§22 of the design
# notes — randomizing all of them every loop leaves nothing for the player to
# actually remember). A pair with no prior history always gets one, since
# "no history yet" is not itself a kind of history.
func _init_living_relationships() -> void:
    var previous: Dictionary = voyage.get("relationships",{}).duplicate(true)
    var current := {}
    for i in range(roster.size()):
        for j in range(i + 1, roster.size()):
            var a := str(roster[i])
            var b := str(roster[j])
            var key := AstraCrewCatalog.pair_key(a,b)
            var history: Dictionary = voyage.get("past",{}).get(key,{})
            var relation := AstraLivingCrew.relationship_from(history, crew[a].get_affinity(b), crew[b].get_affinity(a))
            if previous.has(key):
                var old: Dictionary = previous[key]
                for axis in AstraLivingCrew.AXES:
                    relation[axis] = lerpf(float(relation.get(axis,0.5)),float(old.get(axis,0.5)),0.2)
            current[key] = relation
    voyage["relationships"] = current

func _replay_signature(theme: String) -> String:
    var parts: Array[String] = []
    for key in voyage.get("past",{}).keys():
        var entry: Dictionary = voyage["past"][key]
        parts.append("%s=%s" % [str(key),str(entry.get("type",""))])
    parts.sort()
    return "%s|%s" % [theme,",".join(parts)]

func _avoid_duplicate_loop_signature() -> void:
    var recent: Array = voyage.get("recent_signatures",[])
    if recent.is_empty():
        return
    var current_theme := str(voyage.get("social_theme",""))
    var current_signature := _replay_signature(current_theme)
    if current_signature not in recent.slice(maxi(0,recent.size()-5)):
        return
    var start := AstraLivingCrew.SOCIAL_THEMES.find(current_theme)
    for offset in range(1,AstraLivingCrew.SOCIAL_THEMES.size()+1):
        var candidate := str(AstraLivingCrew.SOCIAL_THEMES[(start + offset) % AstraLivingCrew.SOCIAL_THEMES.size()])
        var pair := AstraLivingCrew.theme_pair(candidate)
        if pair.size() < 2 or pair[0] not in roster or pair[1] not in roster:
            continue
        var signature := _replay_signature(candidate)
        if signature not in recent.slice(maxi(0,recent.size()-5)):
            voyage["social_theme"] = candidate
            return

func _apply_social_theme() -> void:
    var pair := AstraLivingCrew.theme_pair(str(voyage.get("social_theme","")))
    if pair.size() < 2:
        return
    var key := AstraCrewCatalog.pair_key(str(pair[0]),str(pair[1]))
    var relationships: Dictionary = voyage.get("relationships",{})
    if not relationships.has(key):
        return
    var relation: Dictionary = relationships[key]
    match str(voyage.get("social_theme","")):
        "OLD_FRIENDS":
            relation["comfort"] = clampf(float(relation.get("comfort",0.5)) + 0.12,0.0,1.0)
        "BROKEN_TRUST":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) - 0.12,0.0,1.0)
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.12,0.0,1.0)
        "PROTECTIVE":
            relation["protectiveness"] = clampf(float(relation.get("protectiveness",0.2)) + 0.2,0.0,1.0)
        "PROFESSIONAL_CONFLICT":
            relation["respect"] = maxf(float(relation.get("respect",0.5)),0.65)
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.16,0.0,1.0)
        "SHARED_FAILURE":
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.1,0.0,1.0)
        "UNKNOWN_PAST":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) - 0.06,0.0,1.0)
        "QUIET_ALLIANCE":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) + 0.1,0.0,1.0)
    relationships[key] = relation
    voyage["relationships"] = relationships

func _roll_pair_histories(previous_past: Dictionary) -> void:
    var stage := AstraCaseCatalog.CAMPAIGN.find(case_id)
    var reroll_budget := 0 if case_id == AstraCaseCatalog.CALIBRATION else clampi(stage, 0, 3)
    var pair_keys: Array = []
    for i in range(roster.size()):
        for j in range(i + 1, roster.size()):
            pair_keys.append(AstraCrewCatalog.pair_key(str(roster[i]), str(roster[j])))
    var rerollable: Array = pair_keys.duplicate()
    AstraCaseGenerator._shuffle(rerollable, rng)
    var allowed_rerolls := {}
    for i in range(mini(reroll_budget, rerollable.size())):
        allowed_rerolls[rerollable[i]] = true
    for key in pair_keys:
        var names := str(key).split(":")
        var a := str(names[0])
        var b := str(names[1])
        var prior: Variant = previous_past.get(key)
        var prior_type := str(prior.get("type", "")) if prior is Dictionary else ""
        var chosen_type := prior_type
        if prior_type == "" or bool(allowed_rerolls.get(key, false)):
            var candidates := AstraCrewCatalog.pair_candidates(a, b)
            chosen_type = str(candidates[rng.randi_range(0, candidates.size() - 1)])
        var entry: Dictionary = AstraCrewCatalog.pair_history_info(chosen_type).duplicate()
        entry["type"] = chosen_type
        voyage["past"][key] = entry
        var affinity_delta := float(entry.get("affinity_delta", 0.0))
        var trust_delta := float(entry.get("trust_delta", 0.0))
        crew[a].affinity[b] = clampf(AstraCrewCatalog.affinity_bias(a, b) + affinity_delta, -1.0, 1.0)
        crew[b].affinity[a] = clampf(AstraCrewCatalog.affinity_bias(b, a) + affinity_delta, -1.0, 1.0)
        crew[a].adjust_trust(trust_delta * 0.5)
        crew[b].adjust_trust(trust_delta * 0.5)
        if prior_type != "" and prior_type != chosen_type and voyage["changes"].size() < 8:
            var prior_summary := str(AstraCrewCatalog.pair_history_info(prior_type).get("summary", ""))
            voyage["changes"].append("%s / %s: %s → %s" % [name_of(a), name_of(b), prior_summary, str(entry["summary"])])

func _observe_personal_reason(who: String, source_key: String, detail: String = "") -> void:
    var before := AstraPersonalMotiveModel.progress_for(voyage.get("motives",{}),who)
    voyage["motives"] = AstraPersonalMotiveModel.observe(voyage.get("motives",{}),who,source_key,detail)
    var after := AstraPersonalMotiveModel.progress_for(voyage.get("motives",{}),who)
    if after <= before:
        return
    var hint := AstraPersonalMotiveModel.player_hint(voyage.get("motives",{}),who)
    if hint != "":
        var note := "%s · %s" % [name_of(who),hint]
        if note not in voyage["motive_observations"]:
            voyage["motive_observations"].append(note)

func motive_dev_report() -> Array:
    return AstraPersonalMotiveModel.dev_report(voyage.get("motives",{}))

func voyage_rooms() -> Array:
    return AstraVoyageContent.room_ids(roster, case_id)

func routine_state_for(npc_id: String) -> Dictionary:
    return AstraCrewRoutineModel.state_for(voyage.get("routine_state",{}),npc_id)


func _align_activity_queue_to_routine() -> void:
    var state: Dictionary = voyage.get("routine_state",{})
    var kept: Array = []
    var deviations := 0
    for npc_id in state:
        if bool(state[npc_id].get("is_deviation",false)):
            deviations += 1
    for raw in voyage.get("activity_queue",[]):
        var beat: Dictionary = raw
        var room := str(beat.get("room",""))
        var actors: Array = beat.get("actors",[])
        var needs_move := 0
        var valid := room in voyage_rooms()
        for actor_raw in actors:
            var actor := str(actor_raw)
            if actor not in active_participants() or not state.has(actor):
                valid = false
                break
            if str(state[actor].get("location","")) != room:
                needs_move += 1
        if not valid or deviations + needs_move > 3:
            continue
        for actor_raw in actors:
            var actor := str(actor_raw)
            if str(state[actor].get("location","")) != room:
                state[actor]["location"] = room
                state[actor]["activity"] = str(beat.get("action","자기 일을 하고 있다."))
                state[actor]["routine_reason"] = "AUTONOMOUS_BEAT"
                state[actor]["deviation_reason"] = "RELATIONSHIP_EVENT" if actors.size() > 1 else "INVESTIGATION"
                state[actor]["is_deviation"] = true
                deviations += 1
        kept.append(beat)
    voyage["routine_state"] = state
    voyage["activity_queue"] = kept

func _voyage_fact(id: String, note: String, source_type: String = "DIRECT") -> void:
    if id not in voyage["facts"]:
        voyage["facts"].append(id)
    if note not in voyage["notes"]:
        voyage["notes"].append(note)
    voyage["last_fact"] = id
    var source_types: Dictionary = voyage.get("information_sources",{})
    source_types[id] = source_type
    voyage["information_sources"] = source_types
    var ownership: Dictionary = voyage.get("evidence_ownership",{})
    var entry: Dictionary = ownership.get(id,{"found_by":"player","knows":["player"],"public":false})
    var knowers: Array = entry.get("knows",[])
    if "player" not in knowers:
        knowers.append("player")
    entry["knows"] = knowers
    ownership[id] = entry
    voyage["evidence_ownership"] = ownership
    AstraKnowledgeModel.discover_player(flags,id,day,"voyage")
    if id == str(AstraVoyageContent.chapter(case_id)["fact"]):
        voyage["goal_done"] = true
        _advance_curiosity_question(id)

func _echo_entry(who: String) -> Dictionary:
    var raw: Variant = voyage["echo"].get(who)
    if raw is Dictionary:
        var entry: Dictionary = raw.duplicate(true)
        entry["familiarity"] = float(entry.get("familiarity", 0.0))
        entry["trust"] = float(entry.get("trust", 0.0))
        entry["protection"] = float(entry.get("protection", 0.0))
        entry["conflict"] = float(entry.get("conflict", 0.0))
        entry["grief"] = float(entry.get("grief", 0.0))
        entry["tags"] = Array(entry.get("tags", []))
        return entry
    # A pre-0.4.2 save stored a single scalar here; it becomes familiarity,
    # the closest existing dimension to "some residue remains" (§24).
    var legacy := float(raw) if raw != null else 0.0
    return {"familiarity": legacy, "trust": 0.0, "protection": 0.0, "conflict": 0.0, "grief": 0.0, "tags": []}

func echo_strength(entry: Dictionary) -> float:
    var peak := 0.0
    for dim in ["familiarity", "trust", "protection", "conflict", "grief"]:
        peak = maxf(peak, absf(float(entry.get(dim, 0.0))))
    return peak

const ECHO_TAG_THRESHOLDS := {
    "trust": ["trusted_record", 0.32], "protection": ["shielded_player", 0.28],
    "familiarity": ["shared_repair", 0.5], "conflict": ["kept_distance", 0.3]
}

func _adjust_echo(who: String, tag: String, effect: String, delta: float) -> void:
    var entry := _echo_entry(who)
    entry["familiarity"] = clampf(float(entry["familiarity"]) + absf(delta) * 0.4 + 0.01, 0.0, 1.0)
    if tag == "trust" or effect in ["share", "defend"]:
        entry["trust"] = clampf(float(entry["trust"]) + absf(delta) * 0.9, 0.0, 1.0)
    if tag in ["conflict", "suspected", "distant"] or effect == "hide":
        entry["conflict"] = clampf(float(entry["conflict"]) + 0.05, 0.0, 1.0)
    if tag == "danger" and effect in ["help", "defend"]:
        entry["protection"] = clampf(float(entry["protection"]) + 0.10, 0.0, 1.0)
    var tags: Array = entry["tags"]
    for dim in ECHO_TAG_THRESHOLDS:
        var spec: Array = ECHO_TAG_THRESHOLDS[dim]
        if float(entry.get(dim, 0.0)) >= float(spec[1]) and str(spec[0]) not in tags:
            tags.append(str(spec[0]))
    entry["tags"] = tags
    voyage["echo"][who] = entry

func player_relationship_tone(who: String) -> String:
    if voyage.is_empty():
        return "PROFESSIONAL"
    return AstraLivingCrew.relationship_tone_with_player(
        float(voyage.get("bonds",{}).get(who,0.0)), _echo_entry(who)
    )

func _memory_has_tag(who: String, tag: String) -> bool:
    if tag == "":
        return true
    if (who + ":" + tag) in voyage.get("memory_tags",[]) or tag in voyage.get("memory_tags",[]):
        return true
    for event in voyage.get("dialogue_memory_052",{}).get(who,[]):
        if str(event.get("tag","")) == tag or str(event.get("memory_tag","")) == tag:
            return true
    return false

func _memory_action_count(who: String, action: String) -> int:
    var count := 0
    for event in voyage.get("dialogue_memory_052",{}).get(who,[]):
        if str(event.get("type","")) == "player_action" and str(event.get("action","")) == action:
            count += 1
    return count

func _apply_scene_variants(scene: Dictionary, who: String) -> Dictionary:
    var result := scene.duplicate(true)
    var tone := player_relationship_tone(who)
    var tone_lines: Dictionary = result.get("tone_lines",{})
    if tone_lines.has(tone):
        result["lines"] = [[who,str(tone_lines[tone])]]
    var tone_actions: Dictionary = result.get("tone_actions",{})
    if tone_actions.has(tone):
        result["action"] = str(tone_actions[tone])
    var role_lines: Dictionary = result.get("role_lines",{})
    if not role_lines.is_empty() and crew.has(who):
        var role_key := "NULL" if crew[who].is_null() else "CREW"
        if role_lines.has(role_key):
            result["lines"] = [[who,str(role_lines[role_key])]]
    return result


func _apply_consequence_memory(event: Dictionary) -> void:
    var tag := str(event.get("memory_tag",""))
    if tag == "":
        return
    var who := str(event.get("who",""))
    var stored := tag if ":" in tag else (who + ":" + tag if who != "" else tag)
    var tags: Array = voyage.get("memory_tags",[])
    if stored not in tags:
        tags.append(stored)
    voyage["memory_tags"] = tags

func _apply_consequence_event(event: Dictionary, allow_scene: bool = true) -> bool:
    if event.is_empty():
        return false
    _apply_consequence_memory(event)
    var timing := str(event.get("timing","DELAYED"))
    var stats_054: Dictionary = voyage.get("consequence_stats",{})
    stats_054[timing] = int(stats_054.get(timing,0)) + 1
    voyage["consequence_stats"] = stats_054
    var history_event: Dictionary = event.duplicate(true)
    history_event["applied_day"] = day
    history_event["visible_feedback"] = str(event.get("note","")) != "" and str(event.get("source_scene","")) != ""
    voyage["consequence_history"].append(history_event)
    var note := str(event.get("note",""))
    if note != "" and note not in voyage.get("notes",[]):
        voyage["notes"].append(note)
    var who := str(event.get("who",""))
    var bond_delta := float(event.get("bond_delta",0.0))
    if who != "" and bond_delta != 0.0:
        voyage["bonds"][who] = clampf(float(voyage["bonds"].get(who,0.0)) + bond_delta,-1.0,1.0)
    if not allow_scene:
        if note != "":
            _log("후속 · " + note)
        return false
    var followup_id := str(event.get("followup_scene",""))
    if followup_id != "":
        var followup := AstraVoyageContent.scene(followup_id)
        if not followup.is_empty():
            _queue_extra_scene(_apply_scene_variants(followup,str(followup.get("speaker",who))), "consequence")
            return true
    if note != "":
        _queue_extra_scene({
            "id":"054_consequence_" + str(event.get("id","event")).replace(":","_"),
            "speaker":who,"tag":"consequence","category":"CONSEQUENCE",
            "action":note,"lines":[],"choices":[]
        }, "consequence")
        return true
    return false

func _deliver_due_consequence(timing_filter: String = "") -> bool:
    var popped := AstraConsequenceModel.pop_due(
        voyage.get("consequence_queue",[]),int(voyage.get("actions",0)),
        int(voyage.get("loop",0)),day,timing_filter
    )
    voyage["consequence_queue"] = popped.get("queue",[])
    return _apply_consequence_event(popped.get("event",{}),true)

func _apply_next_day_consequences() -> void:
    if voyage.is_empty():
        return
    while true:
        var popped := AstraConsequenceModel.pop_due(
            voyage.get("consequence_queue",[]),int(voyage.get("actions",0)),
            int(voyage.get("loop",0)),day,"NEXT_DAY"
        )
        voyage["consequence_queue"] = popped.get("queue",[])
        var event: Dictionary = popped.get("event",{})
        if event.is_empty():
            break
        _apply_consequence_event(event,false)

func _autonomous_knowledge_share(actors: Array) -> void:
    if actors.size() < 2:
        return
    for source_raw in actors:
        var source := str(source_raw)
        for target_raw in actors:
            var target := str(target_raw)
            if source == target:
                continue
            for fact_id in AstraKnowledgeModel.known_facts(flags,source):
                if AstraKnowledgeModel.knows(flags,target,str(fact_id)) or AstraKnowledgeModel.is_public(flags,str(fact_id)):
                    continue
                var tendency := AstraLivingCrew.sharing_tendency(source,"unverified")
                var roll := _stable_noise("share:%s:%s:%s:%d" % [source,target,str(fact_id),int(voyage.get("actions",0))])
                if roll <= tendency:
                    if AstraKnowledgeModel.share_between(flags,str(fact_id),source,target,day,"autonomous_beat"):
                        AstraDecisionModel.append_trace(flags,AstraDecisionModel.trace(
                            source,"share",target,
                            [AstraDecisionModel.reason("operational_need",0.72,str(fact_id))],day
                        ))
                        var ownership: Dictionary = voyage.get("evidence_ownership",{})
                        if ownership.has(str(fact_id)):
                            var entry: Dictionary = ownership[str(fact_id)]
                            var knowers: Array = entry.get("knows",[])
                            if target not in knowers:
                                knowers.append(target)
                            entry["knows"] = knowers
                            ownership[str(fact_id)] = entry
                            voyage["evidence_ownership"] = ownership
                        return

const CURIOSITY_QUESTIONS := {
    "CALIBRATION": ["누가 수면실 잠금을 해제했나?", "실행자 서명은 왜 비어 있나?"],
    "DEAD_AIR": ["미라가 기억하는 지구 귀환 기록은 어디에서 왔나?", "두 목적지 문서가 모두 원본이라면 어느 항해를 기억한 걸까?"],
    "GLASS_GARDEN": ["세나와 준은 정말 예전부터 알던 사이였나?", "둘의 기억과 배치 기록 중 무엇이 먼저 달라졌나?"],
    "ECHO_WARD": ["소렌이 듣는 신호는 언제 녹음됐나?", "깨어 있지 않은 소렌의 목소리는 누구에게 보내진 걸까?"],
    "SILENT_ORBIT": ["ASTRA는 정말 19년 전에 도착했나?", "19년이 맞다면 왜 우리 몸은 그 시간을 지나지 않은 것처럼 보일까?"],
    "RED_SHIFT": ["출항보다 오래된 목적지 시료는 어디에서 왔나?", "마렌의 시료가 기억하는 환경은 어느 항해의 것일까?"],
    "LAST_LIGHT": ["서로 맞지 않는 사본이 모두 진짜일 수 있나?", "ASTRA가 끝까지 보존하려는 것은 항로일까, 사람의 기억일까?"]
}


const CURIOSITY_RELATED := {
    "calibration_question":["medbay","mira","power"],
    "calibration_question_after":["medbay","power"],
    "dead_air_question":["mira","noa","archive","destination"],
    "dead_air_question_after":["noa","archive","destination"],
    "glass_garden_question":["sena","rho","security"],
    "glass_garden_question_after":["sena","rho","security","archive"],
    "echo_ward_question":["vale","comms","signal"],
    "echo_ward_question_after":["vale","noa","comms","signal"],
    "silent_orbit_question":["eli","bridge","arrival"],
    "silent_orbit_question_after":["mira","eli","bridge","medbay"],
    "red_shift_question":["lyra","garden","sample"],
    "red_shift_question_after":["lyra","garden","archive"],
    "last_light_question":["noa","dax","archive"],
    "last_light_question_after":["mira","noa","archive","bridge"]
}

func _mark_changed_questions() -> void:
    if int(voyage.get("loop",0)) <= 0 or voyage.get("changes",[]).is_empty():
        return
    var questions: Dictionary = voyage.get("questions",{})
    var base_id := case_id.to_lower() + "_question"
    if questions.has(base_id):
        var entry: Dictionary = questions[base_id]
        if str(entry.get("status","")) in ["ANSWERED","PARTIAL"]:
            entry["status"] = "CHANGED"
            questions[base_id] = entry
    voyage["questions"] = questions

func _ensure_curiosity_questions() -> void:
    var questions: Dictionary = voyage.get("questions",{})
    var pair: Array = CURIOSITY_QUESTIONS.get(case_id,[])
    if pair.is_empty():
        return
    var base_id := case_id.to_lower() + "_question"
    if not questions.has(base_id):
        questions[base_id] = {"id":base_id,"case_id":case_id,"text":str(pair[0]),"status":"OPEN","related":Array(CURIOSITY_RELATED.get(base_id,[])).duplicate()}
    voyage["questions"] = questions

func _advance_curiosity_question(_fact_id: String) -> void:
    var pair: Array = CURIOSITY_QUESTIONS.get(case_id,[])
    var chapter := AstraVoyageContent.chapter(case_id)
    if pair.is_empty():
        pair = [str(chapter.get("goal","")),str(chapter.get("open_question",""))]
    var questions: Dictionary = voyage.get("questions",{})
    var base_id := case_id.to_lower() + "_question"
    if questions.has(base_id):
        var base: Dictionary = questions[base_id]
        base["status"] = "ANSWERED"
        questions[base_id] = base
    var next_id := base_id + "_after"
    var next_text := str(chapter.get("open_question",pair[1] if pair.size() > 1 else ""))
    if next_text != "" and not questions.has(next_id):
        questions[next_id] = {"id":next_id,"case_id":case_id,"text":next_text,"status":"OPEN","related":Array(CURIOSITY_RELATED.get(next_id,[])).duplicate()}
    if str(voyage.get("pinned_question","")) == base_id and questions.has(next_id):
        voyage["pinned_question"] = next_id
    voyage["questions"] = questions

func pin_question(question_id: String) -> bool:
    if voyage.is_empty():
        return false
    var questions: Dictionary = voyage.get("questions",{})
    if question_id == "":
        voyage["pinned_question"] = ""
        changed.emit()
        return true
    if not questions.has(question_id):
        return false
    var entry: Dictionary = questions[question_id]
    if str(entry.get("status","OPEN")) not in ["OPEN","PARTIAL","CHANGED"]:
        return false
    voyage["pinned_question"] = "" if str(voyage.get("pinned_question","")) == question_id else question_id
    changed.emit()
    return true

func pinned_question_entry() -> Dictionary:
    if voyage.is_empty():
        return {}
    var question_id := str(voyage.get("pinned_question",""))
    if question_id == "":
        return {}
    return Dictionary(voyage.get("questions",{}).get(question_id,{})).duplicate(true)

func current_questions() -> Array:
    if voyage.is_empty():
        return []
    var current: Array = []
    var others: Array = []
    for key in voyage.get("questions",{}):
        var entry: Dictionary = voyage["questions"][key]
        if str(entry.get("status","OPEN")) not in ["OPEN","PARTIAL","CHANGED"]:
            continue
        if str(entry.get("case_id","")) == case_id:
            current.append(entry.duplicate(true))
        else:
            others.append(entry.duplicate(true))
    current.append_array(others)
    var pinned_id := str(voyage.get("pinned_question",""))
    if pinned_id != "":
        current.sort_custom(func(a,b):
            if str(a.get("id","")) == pinned_id: return true
            if str(b.get("id","")) == pinned_id: return false
            return str(a.get("case_id","")) == case_id and str(b.get("case_id","")) != case_id
        )
    return current.slice(0, mini(3,current.size()))

func loop_difference_summary() -> Array:
    if voyage.is_empty():
        return []
    return Array(voyage.get("changes",[])).slice(0, mini(3,Array(voyage.get("changes",[])).size()))

func character_observations(npc_id: String) -> Array:
    var result: Array = []
    if voyage.is_empty() or npc_id not in voyage.get("met",[]):
        return result
    var baseline_limit := 3 if npc_id == "mira" else 2
    for item in AstraLivingCrew.baseline(npc_id).slice(0,baseline_limit):
        result.append(str(item))
    if npc_id == "mira":
        var seen_ever: Dictionary = voyage.get("seen_ever",{})
        if int(seen_ever.get("053_mira_mira_02",0)) > 0:
            result.append("다른 사람 검사를 끝낸 뒤에도 자기 상태 확인은 미루는 편이다.")
        if int(seen_ever.get("053_mira_mira_06",0)) > 0:
            result.append("의료실 음악을 아주 작게 틀어 두는 편이다.")
        if int(seen_ever.get("053_mira_mira_22",0)) > 0:
            result.append("[현재 기록] 위험 상황에서 당신보다 장비를 먼저 포기시킨 적이 있다.")
    var pairs: Array = []
    for other in roster:
        if str(other) == npc_id:
            continue
        var key := AstraCrewCatalog.pair_key(npc_id,str(other))
        if voyage.get("relationships",{}).has(key):
            pairs.append("%s %s" % [AstraJosa.wa(name_of(str(other))), relationship_status(npc_id,str(other))])
    if not pairs.is_empty():
        result.append("[현재 기록] " + str(pairs[0]))
    return result

func character_baseline(npc_id: String) -> Array:
    return AstraLivingCrew.baseline(npc_id)


# ---------------------------------------------------------------- 0.5.6 visible social feedback / observation Codex

func set_known_codex_entries(entry_ids: Array) -> void:
    if voyage.is_empty():
        return
    voyage["codex_known"] = entry_ids.duplicate()

func reconcile_codex_after_resume(entry_ids: Array) -> void:
    if voyage.is_empty():
        return
    voyage["codex_known"] = entry_ids.duplicate()
    var remaining: Array = []
    for raw_id in voyage.get("codex_unlocks_pending",[]):
        var entry_id: String = str(raw_id)
        if entry_id not in entry_ids:
            remaining.append(entry_id)
    voyage["codex_unlocks_pending"] = remaining

func _queue_codex_unlock(entry_id: String) -> void:
    if voyage.is_empty() or entry_id == "":
        return
    var known: Array = voyage.get("codex_known",[])
    var pending: Array = voyage.get("codex_unlocks_pending",[])
    if entry_id in known or entry_id in pending:
        return
    var entry := AstraCodex.character_entry(entry_id)
    if entry.is_empty():
        return
    pending.append(entry_id)
    voyage["codex_unlocks_pending"] = pending
    notice.emit("codex_unlock", {
        "id":entry_id,
        "character":str(entry.get("character","")),
        "scope":str(entry.get("scope","")),
        "title":str(entry.get("title",""))
    })

func _unlock_codex_from_scene(scene_id: String) -> void:
    for entry_id in AstraCodex.unlocks_for_scene(scene_id):
        _queue_codex_unlock(str(entry_id))

func codex_unlock_events() -> Array:
    var result: Array = []
    if voyage.is_empty():
        return result
    for entry_id in voyage.get("codex_unlocks_pending",[]):
        var entry := AstraCodex.character_entry(str(entry_id))
        if entry.is_empty():
            continue
        result.append({
            "id":str(entry.get("id","")),
            "character":str(entry.get("character","")),
            "scope":str(entry.get("scope","")),
            "title":str(entry.get("title",""))
        })
    return result

func _adjust_relationship(a_id: String, b_id: String, axis: String, amount: float, source_id: String, player_visible: bool, authored_social: bool = false) -> void:
    if voyage.is_empty() or a_id == "" or b_id == "" or a_id == b_id or axis not in AstraLivingCrew.AXES:
        return
    var key := AstraCrewCatalog.pair_key(a_id,b_id)
    var relationships: Dictionary = voyage.get("relationships",{})
    var relation: Dictionary = relationships.get(key,AstraLivingCrew.blank_relationship())
    var before := float(relation.get(axis,0.5))
    var after := clampf(before + amount,0.0,1.0)
    if is_equal_approx(before,after):
        return
    relation[axis] = after
    relationships[key] = relation
    voyage["relationships"] = relationships
    if not player_visible:
        return
    var feedback: Array = voyage.get("relationship_feedback",[])
    var direction := "UP" if after > before else "DOWN"
    feedback.append({
        "day":day,"a":a_id,"b":b_id,"axis":axis,"direction":direction,
        "magnitude":absf(after-before),"source":source_id,"visible":true,
        "authored_social":authored_social
    })
    while feedback.size() > 64:
        feedback.pop_front()
    voyage["relationship_feedback"] = feedback
    for entry_id in AstraCodex.relationship_unlocks(a_id,b_id,axis,direction):
        _queue_codex_unlock(str(entry_id))

func _relationship_feedback_text(axis: String, direction: String) -> String:
    match axis:
        "trust":
            return "서로의 판단을 조금 더 믿게 됐다." if direction == "UP" else "서로의 설명을 바로 믿지 못한다."
        "comfort":
            return "함께 있어도 전보다 편해 보인다." if direction == "UP" else "함께 있을 때 전보다 조심스러워 보인다."
        "tension":
            return "대화 뒤에도 긴장이 남았다." if direction == "UP" else "남아 있던 긴장이 조금 누그러졌다."
        "respect":
            return "업무 판단은 서로 인정한 것 같다." if direction == "UP" else "서로의 업무 판단에 의문이 남았다."
        "protectiveness":
            return "위험할 때 서로를 먼저 살피기 시작했다." if direction == "UP" else "서로를 먼저 감싸던 태도가 옅어졌다."
    return "서로를 대하는 태도가 달라졌다."

func _opinion_feedback_text(change: Dictionary) -> String:
    var actor := name_of(str(change.get("actor",change.get("voter",""))))
    var target_id := str(change.get("after",change.get("target","")))
    var target := name_of(target_id) if target_id != "" else ""
    var reason_tag := str(change.get("reason_tag","new_evidence"))
    if str(change.get("reason","")) != "":
        if target != "":
            return "%s · %s에 대한 판단을 바꿨다. %s" % [actor,target,str(change.get("reason",""))]
        return "%s · %s" % [actor,str(change.get("reason",""))]
    match reason_tag:
        "relationship_change":
            return "%s · 관계가 달라진 뒤 판단도 달라졌다." % actor
        "memory_change":
            return "%s · 앞선 행동을 다시 떠올린 뒤 판단을 바꿨다." % actor
        "uncertainty":
            return "%s · 확신이 줄어 판단을 다시 보게 됐다." % actor
        _:
            if target != "":
                return "%s · 새 기록을 본 뒤 %s에 대한 판단을 바꿨다." % [actor,target]
            return "%s · 새 기록을 본 뒤 판단을 바꿨다." % actor

func daily_social_summary(day_index: int = -1) -> Dictionary:
    var target_day := day if day_index < 0 else day_index
    var buckets := {}
    for raw in voyage.get("relationship_feedback",[]):
        var event: Dictionary = raw
        if not bool(event.get("visible",false)) or int(event.get("day",-1)) != target_day:
            continue
        var a := str(event.get("a",""))
        var b := str(event.get("b",""))
        var axis := str(event.get("axis",""))
        var pair_key := AstraCrewCatalog.pair_key(a,b)
        var key := pair_key + "|" + axis
        var bucket: Dictionary = buckets.get(key,{"a":a,"b":b,"axis":axis,"net":0.0,"authored":false})
        var sign := 1.0 if str(event.get("direction","UP")) == "UP" else -1.0
        bucket["net"] = float(bucket.get("net",0.0)) + float(event.get("magnitude",0.0)) * sign
        bucket["authored"] = bool(bucket.get("authored",false)) or bool(event.get("authored_social",false))
        buckets[key] = bucket
    var per_pair := {}
    for key in buckets:
        var bucket: Dictionary = buckets[key]
        var net := float(bucket.get("net",0.0))
        if absf(net) < 0.03 and not bool(bucket.get("authored",false)):
            continue
        var a := str(bucket.get("a",""))
        var b := str(bucket.get("b",""))
        var axis := str(bucket.get("axis",""))
        var direction := "UP" if net >= 0.0 else "DOWN"
        var pair_key := AstraCrewCatalog.pair_key(a,b)
        var score := absf(net) + (0.04 if bool(bucket.get("authored",false)) else 0.0)
        var candidate := {
            "a":a,"b":b,"pair":"%s ↔ %s" % [name_of(a),name_of(b)],
            "kind":axis,"direction":direction,
            "text":_relationship_feedback_text(axis,direction),
            "_score":score
        }
        if not per_pair.has(pair_key) or score > float(per_pair[pair_key].get("_score",0.0)):
            per_pair[pair_key] = candidate
    var relationship_changes: Array = per_pair.values()
    relationship_changes.sort_custom(func(a,b): return float(a.get("_score",0.0)) > float(b.get("_score",0.0)))
    for entry in relationship_changes:
        entry.erase("_score")
    relationship_changes = relationship_changes.slice(0,mini(3,relationship_changes.size()))
    var active_tensions: Array = []
    for entry in relationship_changes:
        if str(entry.get("kind","")) == "tension" and str(entry.get("direction","")) == "UP":
            active_tensions.append(entry.duplicate(true))
    var consequences: Array = []
    for raw in voyage.get("consequence_history",[]):
        var event: Dictionary = raw
        if int(event.get("applied_day",-1)) != target_day or not bool(event.get("visible_feedback",false)):
            continue
        var note := str(event.get("note",""))
        if note == "":
            continue
        var who := str(event.get("who",""))
        consequences.append({"character":name_of(who) if who != "" else "승무원","text":note})
        if consequences.size() >= 2:
            break
    var opinion_changes: Array = []
    for raw in voyage.get("opinion_changes",[]):
        var change: Dictionary = raw
        if int(change.get("day",-1)) != target_day or ("visible" in change and not bool(change.get("visible",true))):
            continue
        opinion_changes.append({"text":_opinion_feedback_text(change)})
        if opinion_changes.size() >= 2:
            break
    return {
        "day":target_day,
        "relationship_changes":relationship_changes,
        "active_tensions":active_tensions,
        "consequences":consequences,
        "opinion_changes":opinion_changes
    }

func night_feedback_summary() -> Dictionary:
    # Night is for immediate authored consequences only. Relationship/opinion
    # changes are deferred to the next briefing so the same sentence is not
    # repeated on two consecutive screens.
    var summary := daily_social_summary(day)
    summary["relationship_changes"] = []
    summary["active_tensions"] = []
    summary["opinion_changes"] = []
    summary["consequences"] = Array(summary.get("consequences",[])).slice(0,mini(2,Array(summary.get("consequences",[])).size()))
    return summary

func briefing_social_summary(day_index: int) -> Dictionary:
    # Briefing carries forward durable social interpretation, not the immediate
    # consequence line the player could already have read at night.
    var summary := daily_social_summary(day_index)
    summary["relationship_changes"] = Array(summary.get("relationship_changes",[])).slice(0,mini(2,Array(summary.get("relationship_changes",[])).size()))
    summary["opinion_changes"] = Array(summary.get("opinion_changes",[])).slice(0,mini(1,Array(summary.get("opinion_changes",[])).size()))
    summary["consequences"] = []
    return summary

func relationship_between(a_id: String, b_id: String) -> Dictionary:
    if voyage.is_empty():
        return AstraLivingCrew.blank_relationship()
    return Dictionary(voyage.get("relationships",{}).get(AstraCrewCatalog.pair_key(a_id,b_id),AstraLivingCrew.blank_relationship())).duplicate(true)

func relationship_status(a_id: String, b_id: String) -> String:
    return AstraLivingCrew.relationship_status(relationship_between(a_id,b_id))

func player_behavior_profile() -> Dictionary:
    return Dictionary(voyage.get("player_profile",AstraLivingCrew.blank_player_profile())).duplicate(true) if not voyage.is_empty() else AstraLivingCrew.blank_player_profile()

func _updated_recent_signatures() -> Array:
    var result: Array = Array(voyage.get("recent_signatures",[])).duplicate()
    var signature := str(voyage.get("replay_signature",""))
    if signature != "":
        result.append(signature)
    while result.size() > 5:
        result.pop_front()
    return result

func _updated_visible_signatures() -> Array:
    var result: Array = Array(voyage.get("visible_signatures",[])).duplicate()
    var signature := AstraStoryletScheduler.visible_signature(
        str(voyage.get("social_theme","")), voyage.get("loop_hook",{}),
        Array(voyage.get("visible_scene_ids",[])).slice(0,5),
        Array(voyage.get("visible_rare_ids",[])).slice(0,2),
        ",".join(PackedStringArray(voyage.get("active_arcs",[])))
    )
    if signature != "":
        result.append(signature)
    while result.size() > 5:
        result.pop_front()
    return result

func _updated_memory_tags() -> Array:
    var result: Array = Array(voyage.get("memory_tags",[])).duplicate()
    var mira_stance := player_stance_on("mira")
    if int(mira_stance.get("accused",0)) > 0 and "mira:accused_mira" not in result:
        result.append("mira:accused_mira")
    if int(mira_stance.get("defended",0)) > 0 and "mira:defended_mira" not in result:
        result.append("mira:defended_mira")
    while result.size() > 24:
        result.pop_front()
    return result


func _updated_micro_arc_recent() -> Array:
    var result: Array = Array(voyage.get("micro_arc_recent",[])).duplicate()
    for chain_id in voyage.get("active_arcs",[]):
        if int(voyage.get("micro_arc_state",{}).get(str(chain_id),0)) > 0:
            result.append(str(chain_id))
    while result.size() > 6:
        result.pop_front()
    return result

func _updated_recent_focus_families() -> Array:
    var result: Array = Array(voyage.get("recent_focus_families",[])).duplicate()
    for family in voyage.get("loop_focus_families",[]):
        var value := str(family)
        if value == "":
            continue
        result.append(value)
    while result.size() > 8:
        result.pop_front()
    return result

func voyage_memory() -> Dictionary:
    if voyage.is_empty(): return {}
    var meaningful: bool = (not voyage.get("loop_focus_families",[]).is_empty()) or (not voyage.get("motive_observations",[]).is_empty()) or (not voyage.get("foreknowledge_reactions",[]).is_empty()) or (not voyage.get("cooperative_history",[]).is_empty())
    var next_momentum := AstraForeknowledgeModel.update_momentum(voyage.get("momentum_state",{}),meaningful)
    var echo: Dictionary = {}
    var bonds: Dictionary = voyage.get("bonds",{}).duplicate(true)
    for id in roster:
        var stance := player_stance_on(id)
        bonds[id] = clampf(float(bonds.get(id,0.0)) + int(stance.get("defended",0))*0.03 - int(stance.get("accused",0))*0.02,-1.0,1.0)
        var bond_value := float(bonds[id])
        var entry := _echo_entry(str(id))
        entry["familiarity"] = lerpf(float(entry["familiarity"]), clampf(absf(bond_value) + 0.15, 0.0, 1.0), 0.25)
        entry["trust"] = lerpf(float(entry["trust"]), clampf(bond_value, 0.0, 1.0), 0.2)
        entry["conflict"] = lerpf(float(entry["conflict"]), clampf(-bond_value, 0.0, 1.0), 0.2)
        entry["protection"] = float(entry["protection"]) * 0.92
        if not casualties.is_empty():
            entry["grief"] = clampf(float(entry["grief"]) + 0.25, 0.0, 1.0)
        echo[id] = entry
    var choices: Dictionary = voyage.get("choices",{}).duplicate(true)
    choices["accuse"] = int(stats.get("accusations",0))
    var chapters: Array = voyage.get("chapters",[]).duplicate()
    # 0.8.0: a Stage counts as completed for this slot only when it is cleared.
    if outcome == "WIN" and case_id not in chapters: chapters.append(case_id)
    return {
        "mastered_guides":mastered_guides(),
        "first_review":str(voyage.get("previous_review","")),
        "loops":int(voyage.get("loop",0))+1,
        "echo":echo,
        "bonds":bonds,
        "memories":voyage.get("memories",{}).duplicate(true),
        "past":voyage.get("past",{}).duplicate(true),
        "recent":voyage.get("recent",[]).duplicate(),
        "recent_families":voyage.get("recent_families",[]).duplicate(),
        "recent_focus_families":_updated_recent_focus_families(),
        "rare_recent":voyage.get("rare_recent",[]).duplicate(),
        "recent_signatures":_updated_recent_signatures(),
        "seen_ever":voyage.get("seen_ever",{}).duplicate(true),
        "relationships":voyage.get("relationships",{}).duplicate(true),
        "dialogue_memory_052":voyage.get("dialogue_memory_052",{}).duplicate(true),
        "player_profile":voyage.get("player_profile",{}).duplicate(true),
        "questions":voyage.get("questions",{}).duplicate(true),
        "evidence_ownership":voyage.get("evidence_ownership",{}).duplicate(true),
        "storylet_pity":voyage.get("storylet_pity",{}).duplicate(true),
        "memory_tags":_updated_memory_tags(),
        "promise_history":voyage.get("promise_history",[]).duplicate(),
        "autonomous_recent":(Array(voyage.get("autonomous_recent",[])) + Array(voyage.get("autonomous_seen_loop",[]))).slice(-8),
        "visible_signatures":_updated_visible_signatures(),
        "micro_arc_recent":_updated_micro_arc_recent(),
        "micro_arc_pity":voyage.get("micro_arc_pity",{}).duplicate(true),
        "consequence_carry":AstraConsequenceModel.carry_for_next_loop(
            voyage.get("consequence_queue",[]),int(voyage.get("loop",0))
        ),
        "pinned_question":str(voyage.get("pinned_question","")),
        "incident_history":voyage.get("incident_history",[]).duplicate(true),
        "scene_seen_counts":voyage.get("scene_seen_counts",{}).duplicate(true),
        "momentum_state":next_momentum,
        "delegation_history":voyage.get("delegation_history",[]).duplicate(true),
        "canon_post_arrival_seen":voyage.get("canon_post_arrival_seen",[]).duplicate(),
        "changes":voyage.get("changes",[]).duplicate(),
        "choices":choices,
        "losses":casualties.duplicate(),
        "chapters":chapters,
        "echo_events":_echo_events() if outcome != "" else Array(voyage.get("echo_events_in", [])).duplicate(true),
        "echo_last_stage":int(voyage.get("echo_last_stage", 0)),
        "campaign_tally":_campaign_tally(),
        "death_echo":Dictionary(voyage.get("death_echo", {})).duplicate(true)
    }

func can_play_thread(scene: Dictionary) -> bool:
    var participants: Array = Array(scene.get("participants",[])).duplicate()
    for key in ["speaker","target"]:
        var who := str(scene.get(key,""))
        if who != "" and who not in participants: participants.append(who)
    for line in scene.get("lines",[]):
        if str(line[0]) != "" and str(line[0]) not in participants: participants.append(str(line[0]))
    for who in participants:
        if who not in active_participants(): return false
        var fact := str(scene.get("requires_fact",""))
        if fact != "" and not npc_knows_fact(str(who),fact): return false
    var visible := str(scene.get("action",""))+str(scene.get("lines",[]))+str(scene.get("choices",[]))
    for who in AstraCrewCatalog.ORDER:
        if who not in roster and (AstraCrewCatalog.name_ko(who) in visible or AstraCrewCatalog.latin_name(who) in visible): return false
    var seen_beats: Array = []
    for beat in scene.get("beats",[]):
        if str(beat.get("response_to","")) != "" and str(beat["response_to"]) not in seen_beats: return false
        var fact := str(beat.get("requires_fact",""))
        if fact != "" and not npc_knows_fact(str(beat.get("speaker","")),fact): return false
        seen_beats.append(str(beat.get("id","")))
    return true

