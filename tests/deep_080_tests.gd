extends SceneTree

# DEEP RECONSTRUCTION: locked until the campaign is complete; depths grow in
# people and Nulls; every depth is generated from the run seed; a crash
# resumes the same depth; a death ends the run for good (no reload back to
# life); a cleared depth leads to the next one.
#   godot --headless --path . --script res://tests/deep_080_tests.gd

const META_PATH := "user://astra_deep080_meta.cfg"
const SETTINGS_PATH := "user://astra_deep080_settings.cfg"

var checks := 0
var failures: Array = []
var app

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _clean() -> void:
    for path in [META_PATH, SETTINGS_PATH, AstraDeepRun.RUN_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    AstraGameSession.delete_snapshot(AstraDeepRun.SESSION_PATH)

func _wait(n: int = 3) -> void:
    for i in range(n):
        await process_frame

func _run() -> void:
    _clean()
    test_mapping()
    test_setup_deep()
    test_run_file()
    await test_app_flow()
    _clean()
    if failures.is_empty():
        print("ASTRA DEEP 080 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA DEEP 080 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

func test_mapping() -> void:
    check(AstraDeepRun.case_for_depth(1) == "CALIBRATION", "depth 1 is the smallest room")
    for depth in range(1, 7):
        var data := AstraCaseCatalog.resolve(AstraDeepRun.case_for_depth(depth), 1)
        check(AstraCaseCatalog.null_count(data) == 1, "depths 1-6 have one Null")
        check(AstraDeepRun.modifier_for(1234, depth) == "" or depth >= 4, "no modifier before depth 4")
    for depth in range(7, 20):
        var data := AstraCaseCatalog.resolve(AstraDeepRun.case_for_depth(depth), 1)
        check(AstraCaseCatalog.null_count(data) == 2 and AstraCaseCatalog.roster(data).size() == 8, "depth 7+ is all eight awake with two Nulls")
        check(AstraDeepRun.modifier_for(1234, depth) in AstraDeepRun.MODIFIERS, "depth 7+ always announces a modifier")
    check(AstraDeepRun.depth_seed(99, 5) == AstraDeepRun.depth_seed(99, 5), "a depth is generated from the run seed alone")
    check(AstraDeepRun.depth_seed(99, 5) != AstraDeepRun.depth_seed(99, 6), "each depth has its own seed")

func test_setup_deep() -> void:
    var s := AstraGameSession.new()
    s.setup_deep("CALIBRATION", 777, "GUARDIAN", 1, "")
    check(s.is_deep() and s.deep_depth() == 1, "a depth session knows it is Deep")
    check(s.protocol == "GUARDIAN", "the run's protocol applies from depth 1")
    var kinds: Array = []
    for entry in s.story_queue():
        kinds.append(str(entry.get("kind", "")))
    check("deep" in kinds and "opening" not in kinds and "interlude" not in kinds, "Deep skips the campaign story and walking scenes (%s)" % str(kinds))
    var t := AstraGameSession.new()
    t.setup_deep("SILENT_ORBIT", 778, "ANALYST", 9, "SILENT_DECK")
    var announced := false
    for entry in t.story_queue():
        for line in entry.get("lines", []):
            if "고요한 갑판" in str(line[1]):
                announced = true
    check(announced, "the depth modifier is announced at the start")
    check(t.meeting_thread_budget() == 2, "SILENT_DECK takes one argument out of the meeting")
    var same := AstraGameSession.new()
    same.setup_deep("SILENT_ORBIT", 778, "ANALYST", 9, "SILENT_DECK")
    check(Array(same.truth.get("nulls", [])) == Array(t.truth.get("nulls", [])), "the same run seed and depth give the same Nulls")

func test_run_file() -> void:
    var run := AstraDeepRun.new_run("EMPATH")
    check(AstraDeepRun.save_run(run), "a run saves")
    var loaded := AstraDeepRun.load_run()
    check(int(loaded.get("run_seed", -1)) == int(run["run_seed"]) and str(loaded.get("protocol", "")) == "EMPATH", "a run loads as saved")
    check(not AstraDeepRun.active_run().is_empty(), "an unfinished run is active")
    loaded["ended"] = true
    AstraDeepRun.save_run(loaded)
    check(AstraDeepRun.active_run().is_empty(), "an ended run is never active again")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(AstraDeepRun.RUN_PATH))

func test_app_flow() -> void:
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(5)
    app.show_title()
    await _wait(3)
    check(not app.meta.deep_unlocked(), "Deep is locked before the campaign is complete")
    app.deep_start("GUARDIAN")
    await _wait(2)
    check(app.session == null or not app.session.is_deep(), "a locked archive cannot start a Deep run")
    # Finish the campaign's last Stage in the archive.
    app.meta.record_case_result("THRESHOLD", "GUARDIAN", {"outcome": "WIN", "nulls": [], "roster": []}, true)
    check(app.meta.deep_unlocked(), "clearing the last Stage opens Deep for the whole archive")
    app.deep_start("GUARDIAN")
    await _wait(3)
    var s: AstraGameSession = app.session
    check(s != null and s.is_deep() and s.deep_depth() == 1, "a new run starts at depth 1")
    var seed_first := s.seed_value
    var nulls_first := Array(s.truth.get("nulls", [])).duplicate()
    app._save_session()
    # "Crash": drop the session and come back.
    app.session = null
    app.deep_resume()
    await _wait(3)
    check(app.session != null and app.session.seed_value == seed_first and Array(app.session.truth.get("nulls", [])) == nulls_first, "a crash resumes the same depth exactly")
    # Clear depth 1.
    s = app.session
    for id in s.living_null_ids():
        s.crew[id].status = AstraCrewMember.STATUS_ISOLATED
    s._check_end("vote")
    check(s.outcome == "WIN", "isolating every Null clears the depth")
    s.phase = "RESULT"
    s._finalize()
    app.record_result(s)
    check(int(AstraDeepRun.load_run().get("depth_cleared", 0)) == 1, "a cleared depth is recorded")
    app.deep_next_depth()
    await _wait(3)
    check(int(AstraDeepRun.load_run().get("depth", 0)) == 2, "the run goes one depth deeper")
    app.deep_continue()
    await _wait(3)
    check(app.session != null and app.session.deep_depth() == 2 and app.session.case_id == AstraDeepRun.case_for_depth(2), "depth 2 starts in its own room")
    # Die at depth 2.
    s = app.session
    s.stage_state()["player_threat"] = {}
    for id in s.living_null_ids():
        s.stage_state()["player_threat"][id] = 99.0
    s._resolve_night()
    check(s.outcome == "LOSE", "the explorer can die in Deep")
    app._save_session()
    var ended := AstraDeepRun.load_run()
    check(bool(ended.get("ended", false)), "a death ends the run at once")
    check(not AstraGameSession.has_snapshot(AstraDeepRun.SESSION_PATH), "nothing is left to reload after a death")
    check(app.meta.deep_runs == 1 and app.meta.deep_best_depth == 1, "the local record keeps the deepest cleared depth")
    app.session = null
    app.deep_resume()
    await _wait(3)
    check(app.session == null or not app.session.is_deep() or app.session.outcome == "LOSE", "an ended run cannot be resumed")
    check(AstraDeepRun.active_run().is_empty(), "no active run after a death")
    app.queue_free()
    await _wait(2)
