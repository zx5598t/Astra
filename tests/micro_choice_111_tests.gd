extends SceneTree

# ASTRA 1.1.1 — exhaustive audit of the eight revived HUMAN RHYTHM micro-arcs.
const SCENES := [
    "054_vale_listening_fatigue_2",
    "054_eli_risk_route_2",
    "054_lyra_save_sample_2",
    "054_noa_private_copy_2",
    "054_sena_overprotection_2",
    "054_rho_mistake_2",
    "054_dax_failed_model_2",
    "054_mira_self_neglect_2"
]

var failures: Array[String] = []
var checks := 0
var report: PackedStringArray = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_audit()
    if failures.is_empty():
        print("ASTRA MICRO CHOICE 111 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA MICRO CHOICE 111 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _setup_for(scene: Dictionary, seed_value: int) -> AstraGameSession:
    var who := str(scene.get("speaker", ""))
    var allowed: Array = scene.get("chapters", [])
    var chosen := "BORROWED_DAYS"
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        if not allowed.is_empty() and case_id not in allowed:
            continue
        if who in AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id)):
            chosen = str(case_id)
            break
    var s := AstraGameSession.new()
    s.setup(chosen, seed_value)
    s.begin_voyage({})
    return s

func _install(s: AstraGameSession, scene: Dictionary) -> void:
    s._set_story_queue([s._scene_entry(scene, "micro_arc")])
    s.stage_state()["story_index"] = 0
    s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)

func _choice_signature(choice: Dictionary) -> Dictionary:
    var timings: Array[String] = []
    var followups: Array[String] = []
    var notes: Array[String] = []
    for event in choice.get("consequences", []):
        timings.append(str(event.get("timing", "")))
        followups.append(str(event.get("followup_scene", "")))
        notes.append(str(event.get("note", "")))
    timings.sort()
    followups.sort()
    notes.sort()
    return {
        "effect":str(choice.get("effect", "")),
        "memory":str(choice.get("memory_tag", "")),
        "timing":"|".join(timings),
        "followup":"|".join(followups),
        "notes":"|".join(notes)
    }

func _difference_count(a: Dictionary, b: Dictionary) -> int:
    var count := 0
    for key in ["effect","memory","timing","followup","notes"]:
        if str(a.get(key, "")) != str(b.get(key, "")):
            count += 1
    return count

func _event_ids(choice: Dictionary) -> Array[String]:
    var ids: Array[String] = []
    for event in choice.get("consequences", []):
        ids.append(str(event.get("id", "")))
    return ids

func run_audit() -> void:
    report.append("ASTRA 1.1.1 — revived micro-arc option audit")
    report.append("scene\toption\teffect\tmemory_tag\ttimings\tfollowup\truntime_consequence\tsave_load")
    var seed_value := 17111
    var total_options := 0
    for scene_id in SCENES:
        var scene := AstraVoyageContent.scene(scene_id)
        check(not scene.is_empty(), scene_id + " exists")
        var choices: Array = scene.get("choices", [])
        check(choices.size() >= 2, scene_id + " retains a real choice")
        var signatures: Array = []
        for choice in choices:
            signatures.append(_choice_signature(choice))
        for a in range(signatures.size()):
            for b in range(a + 1, signatures.size()):
                check(_difference_count(signatures[a], signatures[b]) >= 2,
                    "%s options %d/%d differ in 2+ meaningful dimensions" % [scene_id, a, b])
        var seen_event_ids := {}
        for index in range(choices.size()):
            total_options += 1
            var choice: Dictionary = choices[index]
            var events: Array = choice.get("consequences", [])
            check(not events.is_empty(), "%s/%d has a consequence" % [scene_id, index])
            var local_ids := {}
            for event_id in _event_ids(choice):
                check(event_id != "", "%s/%d consequence has id" % [scene_id, index])
                check(not local_ids.has(event_id), "%s/%d has no duplicate event id" % [scene_id, index])
                local_ids[event_id] = true
                check(not seen_event_ids.has(event_id), "%s event %s is unique across options" % [scene_id, event_id])
                seen_event_ids[event_id] = true

            var s := _setup_for(scene, seed_value)
            seed_value += 31
            _install(s, scene)
            var history_before := Array(s.voyage.get("consequence_history", [])).size()
            var queue_before := Array(s.voyage.get("consequence_queue", [])).size()
            check(s.story_choose(index), "%s/%d is selectable" % [scene_id, index])
            var history_after := Array(s.voyage.get("consequence_history", [])).size()
            var queue_after := Array(s.voyage.get("consequence_queue", [])).size()
            var fired := history_after > history_before or queue_after > queue_before
            check(fired, "%s/%d produces runtime consequence state" % [scene_id, index])
            var tag := str(choice.get("memory_tag", ""))
            if tag != "":
                var scoped_tag := (str(scene.get("speaker", "")) + ":" + tag) if str(scene.get("speaker", "")) != "" else tag
                check(scoped_tag in Array(s.voyage.get("memory_tags", [])), "%s/%d records scoped memory tag" % [scene_id, index])

            var save_path := "user://micro_111_%d.cfg" % seed_value
            AstraGameSession.delete_snapshot(save_path)
            check(s.save_snapshot(save_path), "%s/%d snapshot saves" % [scene_id, index])
            var loaded := AstraGameSession.new()
            check(loaded.load_snapshot(save_path), "%s/%d snapshot reloads" % [scene_id, index])
            check(Array(loaded.voyage.get("consequence_history", [])).size() == history_after,
                "%s/%d history survives save/load without duplication" % [scene_id, index])
            check(Array(loaded.voyage.get("consequence_queue", [])).size() == queue_after,
                "%s/%d queue survives save/load without duplication" % [scene_id, index])
            AstraGameSession.delete_snapshot(save_path)

            var sig: Dictionary = signatures[index]
            report.append("%s\t%d\t%s\t%s\t%s\t%s\t%s\tPASS" % [
                scene_id, index, str(sig["effect"]), str(sig["memory"]), str(sig["timing"]),
                str(sig["followup"]), "PASS" if fired else "FAIL"])
    report.append("")
    report.append("scenes\t%d" % SCENES.size())
    report.append("options\t%d" % total_options)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/micro_choice_111.txt", FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
