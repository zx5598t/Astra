extends SceneTree
# ASTRA 0.6.2 HUMAN AFTERMATH: player-facing ownership, provenance and
# continuation priority stay explicit without exposing hidden truth.

var checks := 0
var failures: Array[String] = []
const IDS := ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_reaction_ownership()
    test_residue_provenance()
    test_hook_ownership()
    test_selector_priority()
    test_character_safety()
    test_save_contract()
    if failures.is_empty():
        print("ASTRA 0.6.2 HUMAN AFTERMATH TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA 0.6.2 HUMAN AFTERMATH TESTS FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func test_reaction_ownership() -> void:
    for case_id in IDS:
        var beat := AstraVoyageContent.resolution_thread(case_id)
        for choice in beat.get("choices",[]):
            var tag := str(choice.get("memory_tag",""))
            var active := ["mira","rho","dax","noa","sena","vale","eli","lyra"]
            var reaction := AstraVoyageContent.resolution_reaction(case_id,tag,active)
            check(not reaction.is_empty(), "%s/%s: authored choice has a reaction" % [case_id,tag])
            check(str(reaction.get("aftermath_owner","")) == "dialogue", "%s/%s: reaction owns dialogue surface" % [case_id,tag])
            check(str(reaction.get("source_event","")) == tag, "%s/%s: reaction has source event" % [case_id,tag])
            check(bool(reaction.get("continuation",false)), "%s/%s: reaction is a continuation" % [case_id,tag])
            check(Array(reaction.get("choices",[])).is_empty(), "%s/%s: reaction never adds a second decision" % [case_id,tag])

func test_residue_provenance() -> void:
    var probes := {
        "DEAD_AIR":["dead_air_public_dual_destination","noa"],
        "GLASS_GARDEN":["glass_garden_keep_conflict_open","sena"],
        "ECHO_WARD":["echo_ward_preserve_signal","vale"],
        "SILENT_ORBIT":["silent_orbit_private_recheck","eli"],
        "RED_SHIFT":["red_shift_hide_handwriting","noa"],
        "LAST_LIGHT":["last_light_parallel_histories","noa"]
    }
    for case_id in probes:
        var spec: Array = probes[case_id]
        var tag := str(spec[0])
        var expected_speaker := str(spec[1])
        var callback := AstraVoyageContent.resolution_thread(case_id,[tag])
        check(bool(callback.get("human_trace_callback",false)), "%s: residue callback is reachable" % case_id)
        check(str(callback.get("aftermath_source_tag","")) == tag, "%s: residue names its source event" % case_id)
        check(str(callback.get("aftermath_owner","")) == "character_action", "%s: residue is shown as action, not duplicate explanation" % case_id)
        check(str(callback.get("speaker","")) == expected_speaker, "%s: residue portrait/speaker matches visible actor" % case_id)
        check(expected_speaker in Array(callback.get("participants",[])), "%s: residue speaker belongs to authored active participants" % case_id)
        check(str(callback.get("intent","")) == "callback" and bool(callback.get("continuation",false)), "%s: residue is selector-visible continuation" % case_id)
        var serialized := JSON.stringify(callback)
        check(not serialized.contains("raw_relationship") and not serialized.contains("null_id") and not serialized.contains("motive_id"), "%s: residue contains no hidden selector truth" % case_id)

func test_hook_ownership() -> void:
    for case_id in IDS:
        var hook := AstraVoyageContent.hook_thread(case_id)
        check(str(hook.get("aftermath_owner","")) == "story_hook", "%s: hook has one player-facing owner" % case_id)
        check(bool(hook.get("continuation",false)), "%s: hook remains continuation" % case_id)

func test_selector_priority() -> void:
    var callback := AstraVoyageContent.resolution_thread("DEAD_AIR",["dead_air_public_dual_destination"])
    check(AstraStoryletScheduler.salience(callback) == "MANDATORY", "mandatory aftermath outranks ordinary optional content")
    check(AstraStoryletScheduler.is_continuation(callback,{}), "aftermath callback is recognized as continuation")
    var ordinary := {"id":"ordinary_probe","speaker":"rho","tag":"everyday","category":"DAILY","family":"probe"}
    check(AstraStoryletScheduler.salience(ordinary) not in ["MANDATORY","FOLLOWUP"], "ordinary content is not promoted to aftermath")

func test_character_safety() -> void:
    var inactive := ["rho","dax","noa","sena","eli","lyra"]
    var reaction := AstraVoyageContent.resolution_reaction("ECHO_WARD","echo_ward_preserve_signal",inactive)
    check(reaction.is_empty(), "inactive callback speaker cannot speak")
    var active := inactive + ["vale"]
    reaction = AstraVoyageContent.resolution_reaction("ECHO_WARD","echo_ward_preserve_signal",active)
    check(str(reaction.get("speaker","")) == "vale", "active authored callback speaker is preserved")

func test_save_contract() -> void:
    check(AstraMetaProgress.SAVE_VERSION == 11, "0.6.2 keeps save schema v11")
