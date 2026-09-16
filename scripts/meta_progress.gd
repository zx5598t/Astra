class_name AstraMetaProgress
extends RefCounted

const SAVE_PATH := "user://astra_meta.cfg"
const SAVE_VERSION := 1

var total_insight: int = 0
var total_cases_completed: int = 0
var correct_isolations: int = 0
var case_counts: Dictionary = {}
var last_case_id: String = ""
var relationship_events_seen: Array[String] = []

func load_data() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return
    total_insight = int(cfg.get_value("progress", "total_insight", 0))
    total_cases_completed = int(cfg.get_value("progress", "total_cases_completed", 0))
    correct_isolations = int(cfg.get_value("progress", "correct_isolations", 0))
    case_counts = cfg.get_value("progress", "case_counts", {}).duplicate(true)
    last_case_id = str(cfg.get_value("progress", "last_case_id", ""))
    relationship_events_seen.clear()
    for item in cfg.get_value("progress", "relationship_events_seen", []):
        relationship_events_seen.append(str(item))

func save_data() -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "save_version", SAVE_VERSION)
    cfg.set_value("progress", "total_insight", total_insight)
    cfg.set_value("progress", "total_cases_completed", total_cases_completed)
    cfg.set_value("progress", "correct_isolations", correct_isolations)
    cfg.set_value("progress", "case_counts", case_counts)
    cfg.set_value("progress", "last_case_id", last_case_id)
    cfg.set_value("progress", "relationship_events_seen", relationship_events_seen)
    return cfg.save(SAVE_PATH) == OK

func record_case(case_id: String, insight_gain: int, correct_count: int) -> void:
    total_insight += maxi(0, insight_gain)
    total_cases_completed += 1
    correct_isolations += maxi(0, correct_count)
    case_counts[case_id] = int(case_counts.get(case_id, 0)) + 1
    last_case_id = case_id
    save_data()

func remember_relationship_event(event_key: String) -> void:
    if event_key == "" or event_key in relationship_events_seen:
        return
    relationship_events_seen.append(event_key)
    if relationship_events_seen.size() > 64:
        relationship_events_seen.pop_front()
    save_data()

func archive_rank() -> String:
    if total_insight >= 80:
        return "OBSERVER IV"
    if total_insight >= 45:
        return "OBSERVER III"
    if total_insight >= 20:
        return "OBSERVER II"
    if total_insight >= 8:
        return "OBSERVER I"
    return "INITIATE"

func summary() -> String:
    return "%s · Archive Insight %d · Cases %d · Correct Isolations %d" % [archive_rank(), total_insight, total_cases_completed, correct_isolations]
