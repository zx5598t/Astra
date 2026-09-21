extends SceneTree

var checks := 0
var failures: Array[String] = []
const V9_PATH := "user://astra_056_v9.cfg"
const V5_PATH := "user://astra_056_v5.cfg"
const PERSIST_PATH := "user://astra_056_codex_persist.cfg"
const RESUME_META_PATH := "user://astra_056_resume_meta.cfg"
const RESUME_SNAPSHOT_PATH := "user://astra_056_resume.session"

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_catalog_shape()
    test_v9_to_v10_migration()
    test_duplicate_and_persistence()
    test_resume_lifecycle()
    test_older_meta_save()
    for path in [V9_PATH,V5_PATH,PERSIST_PATH,RESUME_META_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    AstraGameSession.delete_snapshot(RESUME_SNAPSHOT_PATH)
    if failures.is_empty():
        print("ASTRA 0.5.6 CODEX TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.6 CODEX TESTS FAILED · %d/%d" % [failures.size(),checks])
        quit(1)

func test_catalog_shape() -> void:
    var counts := AstraCodex.observation_counts()
    check(int(counts.get("TOTAL",0)) == 32,"Codex has 32 observations")
    check(int(counts.get("STABLE",0)) == 14,"Codex STABLE count")
    check(int(counts.get("OBSERVED",0)) == 10,"Codex OBSERVED count")
    check(int(counts.get("ECHO",0)) == 8,"Codex ECHO count")
    for id in ["mira","rho","dax","noa","sena","vale","eli","lyra"]:
        check(AstraCodex.character_entries(id).size() == 4,"%s has four balanced observation entries" % id)
    for entry in AstraCodex.CHARACTER_OBSERVATIONS:
        var body := str(entry.get("body",""))
        check("Null" not in body and "정답" not in body,"Codex body does not reveal hidden truth: " + str(entry.get("id","")))
        if str(entry.get("scope","")) in ["OBSERVED","ECHO"]:
            check(("어떤 항해" in body) or ("기록" in body) or ("순간" in body),"variable/echo lore is framed as observation: " + str(entry.get("id","")))

func _write_v9_fixture() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("meta","save_version",9)
    cfg.set_value("progress","total_insight",77)
    cfg.set_value("progress","total_cases_completed",5)
    cfg.set_value("progress","case_counts",{"ECHO_WARD":2})
    cfg.set_value("progress","case_best_scores",{"ECHO_WARD":810})
    cfg.set_value("progress","relationship_events_seen",["pair_public_1"])
    cfg.set_value("progress","personal_event_choices",{"mira:event":"help"})
    cfg.set_value("progress","known_people",["mira","rho"])
    cfg.set_value("progress","difficulty_mode","STANDARD")
    cfg.set_value("progress","voyage_memory",{
        "loops":3,
        "seen_ever":{"054_rho_mistake_1":1,"054_noa_private_copy_1":0},
        "relationships":{"mira:rho":{"trust":0.6}},
        "memory_tags":["rho:054_rho_documented"]
    })
    cfg.save(V9_PATH)

func test_v9_to_v10_migration() -> void:
    _write_v9_fixture()
    var meta := AstraMetaProgress.new(V9_PATH)
    meta.load_data()
    check(meta.total_insight == 77,"v9 total insight preserved")
    check(meta.total_cases_completed == 5,"v9 campaign progress preserved")
    check(int(meta.case_counts.get("ECHO_WARD",0)) == 2,"v9 case counts preserved")
    check(meta.relationship_events_seen == ["pair_public_1"],"v9 relationship events preserved")
    check(str(meta.personal_event_choices.get("mira:event","")) == "help","v9 personal choices preserved")
    check(meta.known_people.has("mira") and meta.known_people.has("rho"),"v9 known people preserved")
    check(meta.has_codex_entry("mira_baseline_care"),"known Mira safely restores awakening observation")
    check(meta.has_codex_entry("rho_hands_first"),"known Jun safely restores awakening observation")
    check(meta.has_codex_entry("rho_mistake"),"seen_ever safely restores exact observed storylet")
    check(not meta.has_codex_entry("noa_copy"),"unseen scene is not inferred during migration")
    check(meta.save_data(),"migrated v9 profile saves")
    var cfg := ConfigFile.new()
    check(cfg.load(V9_PATH) == OK,"saved migrated profile reloads as config")
    check(int(cfg.get_value("meta","save_version",0)) == 10,"saving migrated profile writes save version 10")
    check(Array(cfg.get_value("progress","codex_entries_unlocked",[])).has("rho_mistake"),"v10 stores Codex unlock ids")

func test_duplicate_and_persistence() -> void:
    var meta := AstraMetaProgress.new(PERSIST_PATH)
    check(meta.unlock_codex_entry("mira_self_neglect"),"first Codex unlock changes state")
    check(not meta.unlock_codex_entry("mira_self_neglect"),"duplicate Codex unlock is a no-op")
    check(meta.unlock_codex_entries(["vale_silence","vale_silence"]).size() == 1,"bulk unlock de-duplicates")
    check(meta.save_data(),"Codex profile saves")
    var restored := AstraMetaProgress.new(PERSIST_PATH)
    restored.load_data()
    check(restored.has_codex_entry("mira_self_neglect"),"Codex entry persists across reload")
    check(restored.has_codex_entry("vale_silence"),"bulk Codex entry persists across reload")
    check(restored.codex_entries_for("mira").size() == 1,"character Codex API returns only unlocked entries")

func test_resume_lifecycle() -> void:
    AstraGameSession.delete_snapshot(RESUME_SNAPSHOT_PATH)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(RESUME_META_PATH))
    var meta := AstraMetaProgress.new(RESUME_META_PATH)
    var session := AstraGameSession.new()
    session.setup("LAST_LIGHT",560602)
    session.begin_voyage({"loops":3,"codex_entries_unlocked":[]})
    session.voyage["codex_known"] = []
    session.voyage["codex_unlocks_pending"] = []
    session._queue_codex_unlock("mira_self_neglect")
    check(session.codex_unlock_events().size() == 1,"runtime Codex unlock is pending before persistence")
    check(meta.unlock_codex_entry("mira_self_neglect"),"runtime Codex unlock persists to meta once")
    check(meta.save_data(),"resume lifecycle meta saves")
    check(session.save_snapshot(RESUME_SNAPSHOT_PATH),"resume lifecycle snapshot saves")

    var restored_meta := AstraMetaProgress.new(RESUME_META_PATH)
    restored_meta.load_data()
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(RESUME_SNAPSHOT_PATH),"resume lifecycle snapshot reloads")
    restored.reconcile_codex_after_resume(restored_meta.codex_entries_unlocked)
    check(restored.codex_unlock_events().is_empty(),"already persisted Codex is not reported new after resume")
    restored._queue_codex_unlock("mira_self_neglect")
    check(restored.codex_unlock_events().is_empty(),"same Codex trigger stays a no-op after resume")
    restored._queue_codex_unlock("noa_copy")
    var resumed_ids: Array = restored.codex_unlock_events().map(func(x): return str(x.get("id","")))
    check(resumed_ids == ["noa_copy"],"first different Codex trigger still unlocks after resume")

func test_older_meta_save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("meta","save_version",5)
    cfg.set_value("progress","total_insight",12)
    cfg.set_value("progress","case_counts",{"DEAD_AIR":1})
    cfg.set_value("progress","known_people",["noa"])
    cfg.save(V5_PATH)
    var meta := AstraMetaProgress.new(V5_PATH)
    meta.load_data()
    check(meta.total_insight == 12,"v5 insight still loads")
    check(int(meta.case_counts.get("DEAD_AIR",0)) == 1,"v5 case progress still loads")
    check(meta.known_people.has("noa"),"v5 known people still load")
    check(meta.has_codex_entry("noa_exact_words"),"safe old known-person evidence can hydrate Codex without breaking legacy save")
