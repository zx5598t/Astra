class_name AstraMetaProgress
extends RefCounted

const SAVE_PATH := "user://astra_meta.cfg"
const SAVE_VERSION := 4
const CAMPAIGN_CASES := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]

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
    case_best_scores = cfg.get_value("progress", "case_best_scores", {}).duplicate(true)
    case_best_labels = cfg.get_value("progress", "case_best_labels", {}).duplicate(true)
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
    cfg.set_value("progress", "case_best_scores", case_best_scores)
    cfg.set_value("progress", "case_best_labels", case_best_labels)
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

func record_theory_result(result: Dictionary, case_id: String = "") -> void:
    theories_submitted += 1
    var matched: int = int(result.get("matched", 0))
    var grade: int = int(result.get("grade", 0))
    if matched >= 2:
        perfect_theories += 1
    best_theory_score = maxi(best_theory_score, grade)
    total_insight += int(grade / 10.0)
    if case_id != "":
        var previous_best := int(case_best_scores.get(case_id, -1))
        if grade > previous_best:
            case_best_scores[case_id] = grade
            case_best_labels[case_id] = str(result.get("label", ""))
    save_data()

func remember_relationship_event(event_key: String) -> void:
    if event_key == "" or event_key in relationship_events_seen:
        return
    relationship_events_seen.append(event_key)
    if relationship_events_seen.size() > 64:
        relationship_events_seen.pop_front()
    save_data()

func is_case_unlocked(case_id: String) -> bool:
    match case_id:
        "DEAD_AIR":
            return true
        "GLASS_GARDEN":
            return int(case_counts.get("DEAD_AIR", 0)) > 0
        "ECHO_WARD":
            return int(case_counts.get("GLASS_GARDEN", 0)) > 0
    return false

func case_status(case_id: String) -> String:
    if not is_case_unlocked(case_id):
        return "LOCKED"
    var count := int(case_counts.get(case_id, 0))
    if count <= 0:
        return "READY"
    var best := int(case_best_scores.get(case_id, -1))
    if best >= 0:
        return "CLEARED · BEST %d" % best
    return "CLEARED"

func best_case_score(case_id: String) -> int:
    return int(case_best_scores.get(case_id, -1))

func completed_campaign_cases() -> int:
    var completed := 0
    for case_id in CAMPAIGN_CASES:
        if int(case_counts.get(case_id, 0)) > 0:
            completed += 1
    return completed

func campaign_complete() -> bool:
    return completed_campaign_cases() >= CAMPAIGN_CASES.size()

func recommended_case_id() -> String:
    for case_id in CAMPAIGN_CASES:
        if is_case_unlocked(case_id) and int(case_counts.get(case_id, 0)) <= 0:
            return case_id
    var best_id := "DEAD_AIR"
    var lowest_count := 999999
    for case_id in CAMPAIGN_CASES:
        if not is_case_unlocked(case_id):
            continue
        var count := int(case_counts.get(case_id, 0))
        if count < lowest_count:
            lowest_count = count
            best_id = case_id
    return best_id

func case_display_name(case_id: String) -> String:
    match case_id:
        "DEAD_AIR": return "INCIDENT ZERO · DEAD AIR"
        "GLASS_GARDEN": return "INCIDENT ONE · GLASS GARDEN"
        "ECHO_WARD": return "INCIDENT TWO · ECHO WARD"
    return case_id

func campaign_summary() -> String:
    return "CAMPAIGN %d/%d · %s" % [completed_campaign_cases(), CAMPAIGN_CASES.size(), "COMPLETE" if campaign_complete() else "IN PROGRESS"]

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
