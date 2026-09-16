class_name AstraMetaProgress
extends RefCounted

const SAVE_PATH := "user://astra_meta.cfg"
const SAVE_VERSION := 3

var total_insight: int = 0
var total_cases_completed: int = 0
var correct_isolations: int = 0
var hypothesis_links_created: int = 0
var theories_submitted: int = 0
var perfect_theories: int = 0
var best_theory_score: int = 0
var case_counts: Dictionary = {}
var last_case_id: String = ""
var relationship_events_seen: Array[String] = []
var personal_event_choices: Dictionary = {}

func load_data() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        return
    total_insight = int(cfg.get_value("progress", "total_insight", 0))
    total_cases_completed = int(cfg.get_value("progress", "total_cases_completed", 0))
    correct_isolations = int(cfg.get_value("progress", "correct_isolations", 0))
    hypothesis_links_created = int(cfg.get_value("progress", "hypothesis_links_created", 0))
    theories_submitted = int(cfg.get_value("progress", "theories_submitted", 0))
    perfect_theories = int(cfg.get_value("progress", "perfect_theories", 0))
    best_theory_score = int(cfg.get_value("progress", "best_theory_score", 0))
    case_counts = cfg.get_value("progress", "case_counts", {}).duplicate(true)
    last_case_id = str(cfg.get_value("progress", "last_case_id", ""))
    personal_event_choices = cfg.get_value("progress", "personal_event_choices", {}).duplicate(true)
    relationship_events_seen.clear()
    for item in cfg.get_value("progress", "relationship_events_seen", []):
        relationship_events_seen.append(str(item))

func save_data() -> bool:
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "save_version", SAVE_VERSION)
    cfg.set_value("progress", "total_insight", total_insight)
    cfg.set_value("progress", "total_cases_completed", total_cases_completed)
    cfg.set_value("progress", "correct_isolations", correct_isolations)
    cfg.set_value("progress", "hypothesis_links_created", hypothesis_links_created)
    cfg.set_value("progress", "theories_submitted", theories_submitted)
    cfg.set_value("progress", "perfect_theories", perfect_theories)
    cfg.set_value("progress", "best_theory_score", best_theory_score)
    cfg.set_value("progress", "case_counts", case_counts)
    cfg.set_value("progress", "last_case_id", last_case_id)
    cfg.set_value("progress", "relationship_events_seen", relationship_events_seen)
    cfg.set_value("progress", "personal_event_choices", personal_event_choices)
    return cfg.save(SAVE_PATH) == OK

func record_case(case_id: String, insight_gain: int, correct_count: int) -> void:
    total_insight += maxi(0, insight_gain)
    total_cases_completed += 1
    correct_isolations += maxi(0, correct_count)
    case_counts[case_id] = int(case_counts.get(case_id, 0)) + 1
    last_case_id = case_id
    save_data()

func record_hypothesis_link() -> void:
    hypothesis_links_created += 1
    save_data()

func record_personal_choice(npc_id: String, choice_index: int) -> void:
    personal_event_choices[npc_id] = int(personal_event_choices.get(npc_id, 0)) + 1
    personal_event_choices["%s:last" % npc_id] = choice_index
    save_data()

func record_theory_result(result: Dictionary) -> void:
    theories_submitted += 1
    var matched := int(result.get("matched", 0))
    var grade := int(result.get("grade", 0))
    if matched >= 2:
        perfect_theories += 1
    best_theory_score = maxi(best_theory_score, grade)
    total_insight += grade / 10
    save_data()

func remember_relationship_event(event_key: String) -> void:
    if event_key == "" or event_key in relationship_events_seen:
        return
    relationship_events_seen.append(event_key)
    if relationship_events_seen.size() > 64:
        relationship_events_seen.pop_front()
    save_data()

func archive_rank() -> String:
    if total_insight >= 180:
        return "OBSERVER VI"
    if total_insight >= 120:
        return "OBSERVER V"
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
    return "%s · Insight %d · Cases %d · Correct %d · Theories %d · Perfect %d · Best %d" % [archive_rank(), total_insight, total_cases_completed, correct_isolations, theories_submitted, perfect_theories, best_theory_score]
