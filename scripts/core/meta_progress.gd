class_name AstraMetaProgress
extends RefCounted

# Persistent archive: campaign unlocks, per-case records, lifetime stats and
# player-observed crew notes. Save v10 adds Codex observation ids without
# removing any v4-v9 field; missing fields are hydrated instead of migrated
# destructively.

const DEFAULT_SAVE_PATH := "user://astra_meta.cfg"
const SAVE_VERSION := 11
const CAMPAIGN_CASES := AstraCaseCatalog.CAMPAIGN
const RANK_ORDER := ["D", "C", "B", "A", "S"]

var save_path: String = DEFAULT_SAVE_PATH
var total_insight: int = 0
var total_cases_completed: int = 0
var correct_isolations: int = 0
var hypothesis_links_created: int = 0
var theories_submitted: int = 0
var perfect_theories: int = 0
var best_theory_score: int = 0
var case_counts: Dictionary = {}
var case_best_scores: Dictionary = {}
var case_best_labels: Dictionary = {}
var case_wins: Dictionary = {}
var case_best_totals: Dictionary = {}
var case_best_ranks: Dictionary = {}
var last_case_id: String = ""
var last_protocol: String = "ANALYST"
var relationship_events_seen: Array[String] = []
var personal_event_choices: Dictionary = {}
var mission_badges: Dictionary = {}
var chapter_challenges: Dictionary = {}

# 0.4.0. Every one of these defaults to the value a 0.3.1 archive implies, so an
# old save loads with no migration step and no lost progress (§47).
var calibration_completed: bool = false
var difficulty_mode: String = "STANDARD"
var null_history: Array[String] = []
var known_people: Array[String] = []
var introduced_locations: Array[String] = []
var unlocks_announced: Array[String] = []
var failed_case_count: int = 0
var loop_summaries: Array = []
var voyage_memory: Dictionary = {}
# Save v11: campaign memory is slot-scoped. `voyage_memory` remains as a legacy mirror for old saves/tools.
var slot_voyage_memory: Dictionary = {}
# 0.5.1 onboarding state. Intro is scoped to save slot rather than the PC-wide
# settings file; feature help is profile-wide and can always be reopened with H.
var slot_intro_seen: Dictionary = {}
var seen_help: Array[String] = []
# 0.5.6 permanent observation Codex. IDs only; entry text remains authored in AstraCodex.
var codex_entries_unlocked: Array[String] = []

func _init(path: String = DEFAULT_SAVE_PATH) -> void:
    save_path = path

func load_data() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(save_path) != OK:
        return
    voyage_memory = _dict(cfg.get_value("progress","voyage_memory",{}))
    slot_voyage_memory = _dict(cfg.get_value("progress","slot_voyage_memory",{}))
    slot_intro_seen = _dict(cfg.get_value("progress","slot_intro_seen",{}))
    _load_string_list(seen_help, cfg.get_value("progress","seen_help",[]))
    total_insight = int(cfg.get_value("progress", "total_insight", 0))
    total_cases_completed = int(cfg.get_value("progress", "total_cases_completed", 0))
    correct_isolations = int(cfg.get_value("progress", "correct_isolations", 0))
    hypothesis_links_created = int(cfg.get_value("progress", "hypothesis_links_created", 0))
    theories_submitted = int(cfg.get_value("progress", "theories_submitted", 0))
    perfect_theories = int(cfg.get_value("progress", "perfect_theories", 0))
    best_theory_score = int(cfg.get_value("progress", "best_theory_score", 0))
    case_counts = _dict(cfg.get_value("progress", "case_counts", {}))
    case_best_scores = _dict(cfg.get_value("progress", "case_best_scores", {}))
    case_best_labels = _dict(cfg.get_value("progress", "case_best_labels", {}))
    case_wins = _dict(cfg.get_value("progress", "case_wins", {}))
    case_best_totals = _dict(cfg.get_value("progress", "case_best_totals", {}))
    case_best_ranks = _dict(cfg.get_value("progress", "case_best_ranks", {}))
    last_case_id = str(cfg.get_value("progress", "last_case_id", ""))
    last_protocol = str(cfg.get_value("progress", "last_protocol", "ANALYST"))
    personal_event_choices = _dict(cfg.get_value("progress", "personal_event_choices", {}))
    mission_badges = _dict(cfg.get_value("progress", "mission_badges", {}))
    chapter_challenges = _dict(cfg.get_value("progress", "chapter_challenges", {}))
    relationship_events_seen.clear()
    for item in cfg.get_value("progress", "relationship_events_seen", []):
        relationship_events_seen.append(str(item))
    # A 0.3.1 archive has no calibration record. Any finished campaign case is
    # proof the player is already past the tutorial, so it counts as done.
    calibration_completed = bool(cfg.get_value("progress", "calibration_completed", campaign_cases_played() > 0 or total_cases_completed > 0))
    difficulty_mode = str(cfg.get_value("progress", "difficulty_mode", "STANDARD"))
    failed_case_count = int(cfg.get_value("progress", "failed_case_count", 0))
    loop_summaries = cfg.get_value("progress", "loop_summaries", [])
    _load_string_list(null_history, cfg.get_value("progress", "null_history", []))
    _load_string_list(known_people, cfg.get_value("progress", "known_people", []))
    _load_string_list(introduced_locations, cfg.get_value("progress", "introduced_locations", []))
    _load_string_list(unlocks_announced, cfg.get_value("progress", "unlocks_announced", []))
    _load_string_list(codex_entries_unlocked, cfg.get_value("progress", "codex_entries_unlocked", []))
    _migrate_codex_from_existing_progress()

func save_data() -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "save_version", SAVE_VERSION)
    cfg.set_value("progress","voyage_memory",voyage_memory)
    cfg.set_value("progress","slot_voyage_memory",slot_voyage_memory)
    cfg.set_value("progress","slot_intro_seen",slot_intro_seen)
    cfg.set_value("progress","seen_help",seen_help)
    cfg.set_value("progress","codex_entries_unlocked",codex_entries_unlocked)
    cfg.set_value("progress", "total_insight", total_insight)
    cfg.set_value("progress", "total_cases_completed", total_cases_completed)
    cfg.set_value("progress", "correct_isolations", correct_isolations)
    cfg.set_value("progress", "hypothesis_links_created", hypothesis_links_created)
    cfg.set_value("progress", "theories_submitted", theories_submitted)
    cfg.set_value("progress", "perfect_theories", perfect_theories)
    cfg.set_value("progress", "best_theory_score", best_theory_score)
    cfg.set_value("progress", "case_counts", case_counts)
    cfg.set_value("progress", "case_best_scores", case_best_scores)
    cfg.set_value("progress", "case_best_labels", case_best_labels)
    cfg.set_value("progress", "case_wins", case_wins)
    cfg.set_value("progress", "case_best_totals", case_best_totals)
    cfg.set_value("progress", "case_best_ranks", case_best_ranks)
    cfg.set_value("progress", "last_case_id", last_case_id)
    cfg.set_value("progress", "last_protocol", last_protocol)
    cfg.set_value("progress", "relationship_events_seen", relationship_events_seen)
    cfg.set_value("progress", "personal_event_choices", personal_event_choices)
    cfg.set_value("progress", "mission_badges", mission_badges)
    cfg.set_value("progress", "chapter_challenges", chapter_challenges)
    cfg.set_value("progress", "calibration_completed", calibration_completed)
    cfg.set_value("progress", "difficulty_mode", difficulty_mode)
    cfg.set_value("progress", "failed_case_count", failed_case_count)
    cfg.set_value("progress", "loop_summaries", loop_summaries)
    cfg.set_value("progress", "null_history", null_history)
    cfg.set_value("progress", "known_people", known_people)
    cfg.set_value("progress", "introduced_locations", introduced_locations)
    cfg.set_value("progress", "unlocks_announced", unlocks_announced)
    return cfg.save(save_path) == OK

func reset() -> void:
    total_insight = 0
    total_cases_completed = 0
    correct_isolations = 0
    hypothesis_links_created = 0
    theories_submitted = 0
    perfect_theories = 0
    best_theory_score = 0
    case_counts.clear()
    case_best_scores.clear()
    case_best_labels.clear()
    case_wins.clear()
    case_best_totals.clear()
    case_best_ranks.clear()
    last_case_id = ""
    relationship_events_seen.clear()
    personal_event_choices.clear()
    mission_badges.clear()
    chapter_challenges.clear()
    calibration_completed = false
    difficulty_mode = "STANDARD"
    null_history.clear()
    known_people.clear()
    introduced_locations.clear()
    unlocks_announced.clear()
    failed_case_count = 0
    loop_summaries.clear()
    voyage_memory.clear()
    slot_voyage_memory.clear()
    slot_intro_seen.clear()
    seen_help.clear()
    codex_entries_unlocked.clear()


# ---------------------------------------------------------------- 0.5.6 observation Codex

func unlock_codex_entry(entry_id: String) -> bool:
    if entry_id == "" or entry_id in codex_entries_unlocked:
        return false
    if AstraCodex.character_entry(entry_id).is_empty():
        return false
    codex_entries_unlocked.append(entry_id)
    return true

func unlock_codex_entries(entry_ids: Array) -> Array:
    var added: Array = []
    for raw_id in entry_ids:
        var entry_id := str(raw_id)
        if unlock_codex_entry(entry_id):
            added.append(entry_id)
    return added

func has_codex_entry(entry_id: String) -> bool:
    return entry_id in codex_entries_unlocked

func codex_entries_for(character_id: String) -> Array:
    var result: Array = []
    for entry_id in codex_entries_unlocked:
        var entry := AstraCodex.character_entry(str(entry_id))
        if not entry.is_empty() and str(entry.get("character","")) == character_id:
            result.append(entry)
    return result

func _migrate_codex_from_existing_progress() -> void:
    # Recover only observations for which old saves contain direct evidence.
    # Knowing a person proves their awakening was seen. seen_ever proves a
    # specific authored scene was actually displayed. We deliberately do not
    # infer lore from relationship floats, candidate storylets or hidden state.
    var recovered: Array = []
    for npc_id in known_people:
        recovered.append_array(AstraCodex.unlocks_for_scene(str(npc_id) + "_awakening"))
    var seen_ever: Dictionary = _dict(voyage_memory.get("seen_ever",{}))
    for scene_id in seen_ever:
        if int(seen_ever.get(scene_id,0)) > 0:
            recovered.append_array(AstraCodex.unlocks_for_scene(str(scene_id)))
    unlock_codex_entries(recovered)

# Records a finished case. Returns what changed so the result screen can show it.
func record_case_result(case_id: String, protocol: String, report: Dictionary, persist: bool = true) -> Dictionary:
    var was_unlocked := {}
    for campaign_case in CAMPAIGN_CASES:
        was_unlocked[campaign_case] = is_case_unlocked(campaign_case)
    total_cases_completed += 1
    case_counts[case_id] = int(case_counts.get(case_id, 0)) + 1
    last_case_id = case_id
    last_protocol = protocol
    correct_isolations += int(report.get("null_isolated", 0))
    if AstraCaseCatalog.is_calibration(case_id):
        calibration_completed = true
    record_null_roles(report.get("nulls", []))
    for npc_id in report.get("roster", []):
        meet_person(str(npc_id))
    if str(report.get("outcome", "")) not in ["WIN", "CONTINUE"]:
        note_failure()
    if report.has("loop_summary"):
        record_loop_summary(report.get("loop_summary", {}))
    var won := str(report.get("outcome", "")) == "WIN"
    if won:
        case_wins[case_id] = int(case_wins.get(case_id, 0)) + 1
    var new_badge := bool(report.get("mission_complete", false)) and not bool(mission_badges.get(case_id, false))
    if bool(report.get("mission_complete", false)):
        mission_badges[case_id] = true
    var objectives: Array = report.get("objectives", [])
    if objectives.size() >= 2 and bool(objectives[1].get("complete", false)):
        chapter_challenges[case_id] = true
    var total := int(report.get("total", 0))
    var new_best := total > int(case_best_totals.get(case_id, -1))
    if new_best:
        case_best_totals[case_id] = total
        case_best_ranks[case_id] = str(report.get("rank", "D"))
    var theory: Dictionary = report.get("theory", {})
    if not theory.get("suspects", []).is_empty():
        theories_submitted += 1
        if int(theory.get("matched", 0)) >= 2:
            perfect_theories += 1
        var grade := int(theory.get("grade", 0))
        best_theory_score = maxi(best_theory_score, grade)
        if grade > int(case_best_scores.get(case_id, -1)):
            case_best_scores[case_id] = grade
            case_best_labels[case_id] = str(theory.get("label", ""))
    var gain := maxi(1, int(total / 150.0))
    total_insight += gain
    var unlocked: Array = []
    for campaign_case in CAMPAIGN_CASES:
        if is_case_unlocked(campaign_case) and not bool(was_unlocked[campaign_case]):
            unlocked.append(campaign_case)
    if persist:
        save_data()
    return {"insight_gain": gain, "new_best": new_best, "unlocked": unlocked, "new_badge": new_badge}

func is_case_unlocked(case_id: String) -> bool:
    if AstraCaseCatalog.is_calibration(case_id):
        return true
    var index := CAMPAIGN_CASES.find(case_id)
    if index < 0:
        return false
    # The campaign opens once the calibration case has been finished once. An
    # archive from 0.3.1 has no calibration record but has finished cases, so it
    # is treated as already past it rather than sent back to the tutorial.
    if not past_calibration():
        return false
    return index == 0 or int(case_counts.get(CAMPAIGN_CASES[index - 1], 0)) > 0

func case_status(case_id: String) -> String:
    if not is_case_unlocked(case_id):
        return "잠김"
    if int(case_counts.get(case_id, 0)) <= 0:
        return "미해결"
    if int(case_wins.get(case_id, 0)) > 0:
        return "해결 · 최고 %s등급" % str(case_best_ranks.get(case_id, "-"))
    return "조사 기록 있음 · 최고 %s등급" % str(case_best_ranks.get(case_id, "-"))

func best_case_score(case_id: String) -> int:
    return int(case_best_scores.get(case_id, -1))

func best_case_rank(case_id: String) -> String:
    return str(case_best_ranks.get(case_id, ""))

func completed_campaign_cases() -> int:
    var completed := 0
    for case_id in CAMPAIGN_CASES:
        if int(case_counts.get(case_id, 0)) > 0:
            completed += 1
    return completed

func campaign_complete() -> bool:
    return completed_campaign_cases() >= CAMPAIGN_CASES.size()

func recommended_case_id() -> String:
    # Keep historical scores while giving returning 0.4 players the new opening.
    # Completed chapters are recorded separately from historical case wins.
    var chapters: Array = voyage_memory.get("chapters",[])
    for case_id in [AstraCaseCatalog.CALIBRATION] + CAMPAIGN_CASES:
        if case_id not in chapters: return str(case_id)
    return str(CAMPAIGN_CASES[CAMPAIGN_CASES.size() - 1])

func case_display_name(case_id: String) -> String:
    var data := AstraCaseCatalog.get_case(case_id)
    if data.is_empty():
        return case_id
    return "%s · %s" % [str(data.get("code", "")), str(data.get("title", ""))]

func campaign_summary() -> String:
    return "캠페인 %d/%d%s" % [completed_campaign_cases(), CAMPAIGN_CASES.size(), " · 완료" if campaign_complete() else ""]

func unlock_hint(case_id: String) -> String:
    var index := CAMPAIGN_CASES.find(case_id)
    if index > 0:
        return "%s 사건을 한 번 끝까지 조사하면 열립니다" % str(AstraCaseCatalog.get_case(str(CAMPAIGN_CASES[index - 1])).get("title", ""))
    return ""

# Read-only archive entries; unresolved chapters keep their ending hidden.
func story_archive() -> Array:
    var entries: Array = []
    for case_id in CAMPAIGN_CASES:
        var data := AstraCaseCatalog.get_case(case_id)
        var completed := int(case_counts.get(case_id, 0)) > 0
        var solved := int(case_wins.get(case_id, 0)) > 0
        entries.append({
            "id": case_id, "chapter": str(data.get("chapter", "")), "title": str(data.get("title", "")),
            "unlocked": is_case_unlocked(case_id), "completed": completed, "solved": solved,
            "text": str(data.get("story_outro", "")) if completed else "아직 확인하지 않은 기록입니다.",
            "mission_badge": bool(mission_badges.get(case_id, false)), "challenge_badge": bool(chapter_challenges.get(case_id, false))
        })
    return entries

func archive_rank() -> String:
    if total_insight >= 180:
        return "탐사요원 VI"
    if total_insight >= 120:
        return "탐사요원 V"
    if total_insight >= 80:
        return "탐사요원 IV"
    if total_insight >= 45:
        return "탐사요원 III"
    if total_insight >= 20:
        return "탐사요원 II"
    if total_insight >= 8:
        return "탐사요원 I"
    return "견습 탐사요원"

func _dict(value) -> Dictionary:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    return {}

# ---------------------------------------------------------------- 0.4.0

static func _load_string_list(target: Array[String], source) -> void:
    target.clear()
    if not source is Array:
        return
    for item in source:
        target.append(str(item))

func voyage_memory_for_slot(slot: int) -> Dictionary:
    var key := str(maxi(0, slot))
    if slot_voyage_memory.has(key):
        return _dict(slot_voyage_memory[key]).duplicate(true)
    # v10 and older had one campaign memory. Migrate it only into slot 0 so
    # starting another slot cannot inherit an unrelated campaign.
    if key == "0" and not voyage_memory.is_empty():
        return voyage_memory.duplicate(true)
    return {}

func set_voyage_memory_for_slot(slot: int, memory: Dictionary) -> void:
    var key := str(maxi(0, slot))
    slot_voyage_memory[key] = memory.duplicate(true)
    voyage_memory = memory.duplicate(true) # compatibility mirror

func clear_voyage_memory_for_slot(slot: int) -> void:
    slot_voyage_memory.erase(str(maxi(0, slot)))
    if maxi(0, slot) == 0:
        voyage_memory.clear()

func intro_seen_for_slot(slot: int) -> bool:
    return bool(slot_intro_seen.get(str(maxi(0, slot)), false))

func mark_intro_seen_for_slot(slot: int) -> void:
    slot_intro_seen[str(maxi(0, slot))] = true

func reset_intro_for_slot(slot: int) -> void:
    slot_intro_seen.erase(str(maxi(0, slot)))

func has_seen_help(feature: String) -> bool:
    return feature in seen_help

func mark_help_seen(feature: String) -> void:
    if not (feature in seen_help):
        seen_help.append(feature)

func past_calibration() -> bool:
    return calibration_completed or campaign_cases_played() > 0

func campaign_cases_played() -> int:
    var played := 0
    for case_id in CAMPAIGN_CASES:
        played += int(case_counts.get(case_id, 0))
    return played

func unlocked_features() -> Array:
    return AstraUnlocks.unlocked(calibration_completed, completed_campaign_cases())

func has_feature(feature: String) -> bool:
    return AstraUnlocks.has(unlocked_features(), feature)

# Features that have opened but whose card the player has not seen yet.
func pending_unlock_cards() -> Array:
    var pending: Array = []
    for feature in unlocked_features():
        if feature in AstraUnlocks.ALWAYS:
            continue
        if feature in unlocks_announced:
            continue
        pending.append(feature)
    return pending

func mark_unlock_announced(feature: String) -> void:
    if not (feature in unlocks_announced):
        unlocks_announced.append(feature)

# Who has been on screen before. The first time someone appears they get an
# introduction card; after that they are simply in the room (§21, §64).
func knows_person(npc_id: String) -> bool:
    return npc_id in known_people

func meet_person(npc_id: String) -> void:
    if not (npc_id in known_people):
        known_people.append(npc_id)

func unseen_people(roster: Array) -> Array:
    var fresh: Array = []
    for npc_id in roster:
        if not knows_person(str(npc_id)):
            fresh.append(str(npc_id))
    return fresh

func see_location(room_id: String) -> void:
    if not (room_id in introduced_locations):
        introduced_locations.append(room_id)

# Keeps the last dozen Null assignments so the generator can damp repeats. It is
# never shown to the player: seeing the history would make the next case
# guessable, which is the opposite of the point (§67, §100).
func record_null_roles(ids: Array) -> void:
    for npc_id in ids:
        null_history.append(str(npc_id))
    while null_history.size() > 12:
        null_history.remove_at(0)

func recent_null_history() -> Array:
    return null_history.duplicate()

func record_loop_summary(summary: Dictionary) -> void:
    loop_summaries.append(summary)
    while loop_summaries.size() > 8:
        loop_summaries.remove_at(0)

func last_loop_summary() -> Dictionary:
    if loop_summaries.is_empty():
        return {}
    return loop_summaries[loop_summaries.size() - 1]

func note_failure() -> void:
    failed_case_count += 1

# Story difficulty is offered for real after a couple of losses, instead of
# waiting for the player to go looking for a settings menu they do not know
# exists (§29).
func should_offer_assist() -> bool:
    return failed_case_count >= 2 and difficulty_mode != "STORY"
