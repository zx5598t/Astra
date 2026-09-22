extends SceneTree
# ASTRA 0.7.3 HUMAN SIGNAL — exact micro-arc / relationship visual pass.
const IDS := [
    "054_sena_overprotection_2",
    "054_noa_private_copy_2",
    "054_vale_vale_eli_direction",
    "054_dax_failed_model_3",
    "054_lyra_save_sample_2"
]
const ACT1_072 := ["CALIBRATION","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const ACT2_071 := ["SECOND_WATCH","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]
var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failures.append(label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
    check(IDS.size() == 5, "HUMAN SIGNAL has exactly five new scene images")
    var scenes := {}
    for scene in AstraStorylets054.scenes():
        scenes[str(scene.get("id",""))] = scene
    for id in IDS:
        var path := AstraArt.storylet_scene(id)
        check(path.begins_with("res://assets/art073/"), id + " maps to art073")
        check(FileAccess.file_exists(path), id + " art exists")
        check(ResourceLoader.exists(path), id + " art imports")
        var texture := AstraUI.texture(path)
        check(texture != null, id + " loads Texture2D")
        if texture != null:
            check(texture.get_width() >= 1200 and texture.get_height() >= 675, id + " is scene-scale")
        check(scenes.has(id), id + " remains authored/reachable content")
        if scenes.has(id):
            var scene: Dictionary = scenes[id]
            check(str(scene.get("speaker","")) != "", id + " keeps speaker")
            check(str(scene.get("action","")) != "", id + " keeps action")
            check(Array(scene.get("lines",[])).size() > 0, id + " keeps dialogue")
    check(str(scenes[IDS[2]].get("target","")) == "eli", "Soren/Lucan scene keeps pair target")
    for id in [IDS[0],IDS[1],IDS[4]]:
        check(Array(scenes[id].get("choices",[])).size() >= 2, id + " keeps meaningful choices")
        var consequence_count := 0
        for choice in Array(scenes[id].get("choices",[])):
            consequence_count += Array(choice.get("consequences",[])).size()
        check(consequence_count >= 2, id + " keeps consequences")
    check(AstraArt.storylet_scene("054_mira_self_neglect_2") == "", "unselected storylet falls back")
    check(AstraArt.storylet_scene("hidden_null_state") == "", "hidden state cannot select art")
    for case_id in ACT1_072:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art072/"), case_id + " keeps 0.7.2 art")
    for case_id in ACT2_071:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art071/"), case_id + " keeps 0.7.1 art")
    if failures.is_empty():
        print("ASTRA 0.7.3 HUMAN SIGNAL TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures: printerr("FAIL · " + failure)
    quit(1)
