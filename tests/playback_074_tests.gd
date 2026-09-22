extends SceneTree
# ASTRA 0.7.4 PLAYBACK — narrative-flow regression.
# Uses only player-visible focus context. Hidden truth, motive assignments and
# raw relationship values must never become presentation/scheduling inputs.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT", 740074, "ANALYST", "STANDARD")
    s.begin_voyage()
    var focus := {
        "id":"playback_probe","speaker":"noa","tag":"personal","category":"RELATIONSHIP",
        "family":"playback_probe","intent":"micro_arc","chain_id":"playback_probe",
        "action":"노아가 방금 본 기록을 덮지 않고 그대로 둔다.","lines":[["noa","이건 다음 기록이랑 같이 볼게요."]],"choices":[]
    }
    s._voyage_scene(focus)
    check(s._recent_focus_needs_space(), "fresh high-salience scene creates one-action breathing room")
    check(not s._maybe_trigger_incident(), "unrelated incident cannot interrupt fresh focus beat")
    s.voyage["scene"] = {}
    s.voyage["actions"] = int(s.voyage.get("actions",0)) + 2
    check(not s._recent_focus_needs_space(), "breathing room expires without persistent state")
    var ctx := s._focus_context()
    check(not ctx.has("truth") and not ctx.has("nulls") and not ctx.has("motives") and not ctx.has("relationships"), "selector context remains player-safe")
    check(AstraMetaProgress.SAVE_VERSION == 11, "save schema remains v11")
    for id in ["054_sena_overprotection_2","054_noa_private_copy_2","054_vale_vale_eli_direction","054_dax_failed_model_3","054_lyra_save_sample_2"]:
        check(AstraArt.storylet_scene(id).begins_with("res://assets/art073/"), id + " keeps HUMAN SIGNAL art")
    for case_id in ["CALIBRATION","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art072/"), case_id + " keeps ACT I art")
    for case_id in ["SECOND_WATCH","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art071/"), case_id + " keeps ACT II art")
    if failures.is_empty():
        print("ASTRA 0.7.4 PLAYBACK TESTS OK · %d checks" % checks)
        quit(0)
    quit(1)
