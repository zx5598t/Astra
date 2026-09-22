extends SceneTree
# 0.7.0 FIRST IMPRESSION (§6, §37): every crew member has a glimpse line, the
# mandatory Day 1-5 join threads no longer speak a self-introduction the
# glimpse chip already covers, glimpse state is per-slot and reset only by a
# fresh campaign, and playing through CALIBRATION's opening actually marks
# each of the four initial crew as glimpsed in speaking order without
# duplicating state on re-render.

var failures: Array[String] = []
var checks := 0
var app

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    _run.call_deferred()

func wait_frames(n: int = 4) -> void:
    for i in range(n):
        await process_frame

func _run() -> void:
    var save_path := "user://astra_070_glimpse_test.cfg"
    var settings_path := "user://astra_070_glimpse_test_settings.cfg"
    for path in [save_path, settings_path]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

    for npc_id in AstraCrewCatalog.ORDER:
        check(AstraCrewCatalog.glimpse_line(npc_id) != "", "%s has a FIRST IMPRESSION glimpse line" % npc_id)

    var first_wake: Dictionary = AstraVoyageContent.FIRST_THREADS["first_wake"]
    for line in first_wake["lines"]:
        var speaker := str(line[0])
        var job := str(AstraCrewCatalog.info(speaker).get("job", ""))
        check(job != "" and not str(line[1]).contains(job), "%s: first_wake line has no spoken job self-introduction" % speaker)
    for who in ["sena", "vale", "eli", "lyra"]:
        var arrival: Dictionary = AstraVoyageContent.ARRIVALS[who]
        var first_line := str(arrival["lines"][0][1])
        var job := str(AstraCrewCatalog.info(who).get("job", ""))
        check(job != "" and not first_line.contains(job), "%s: arrival first line has no spoken job self-introduction" % who)

    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(save_path)
    app.settings = AstraSettings.new(settings_path)
    root.add_child(app)
    await wait_frames()

    check(not app.meta.has_glimpsed(0, "mira"), "fresh meta: mira not glimpsed yet")
    app.meta.mark_glimpsed(0, "mira")
    check(app.meta.has_glimpsed(0, "mira"), "mark_glimpsed sets the flag")
    check(not app.meta.has_glimpsed(1, "mira"), "glimpse state is scoped per slot, not global")
    app.meta.reset_intro_for_slot(0)
    check(not app.meta.has_glimpsed(0, "mira"), "reset_intro_for_slot clears glimpse state for a fresh campaign")

    app.meta.mark_intro_seen_for_slot(0)
    app.start_case("CALIBRATION", "ANALYST", 0)
    await wait_frames()
    check(app.session != null, "CALIBRATION session started")
    check(app.session.phase == "EXPLORE", "CALIBRATION opens straight into EXPLORE, no opening-cinema gate in this test")
    check(app.meta.has_glimpsed(0, "mira"), "mira glimpsed as first_wake's first speaker")
    for id in ["rho", "dax", "noa"]:
        check(not app.meta.has_glimpsed(0, id), "%s not glimpsed before their first_wake line plays" % id)
    # first_wake starts at voyage["line"] == -1 (the scene-setting beat, shown
    # under the scene's default speaker "mira"); voyage_next() #1 only moves
    # it to line 0, which is still mira's own line. rho/dax/noa's lines are
    # 1/2/3, so four calls are needed to walk the whole four-line scene.
    for expected in ["mira", "rho", "dax", "noa"]:
        app.session.voyage_next()
        await wait_frames()
        check(app.meta.has_glimpsed(0, expected), "%s glimpsed by the time first_wake reaches their line" % expected)
    check(Array(app.meta.slot_crew_glimpsed.get("0", [])) == ["mira", "rho", "dax", "noa"], "all four initial crew glimpsed, in speaking order, none skipped or duplicated")

    var view = app._current
    check(view != null and view is AstraVoyageView, "voyage view is the active screen after CALIBRATION start")
    if view != null:
        var probe_stage := Control.new()
        root.add_child(probe_stage)
        var before: int = Array(app.meta.slot_crew_glimpsed.get("0", [])).size()
        view._maybe_glimpse(probe_stage, "mira")
        var after: int = Array(app.meta.slot_crew_glimpsed.get("0", [])).size()
        check(before == after, "re-glimpsing an already-seen npc does not duplicate slot state")
        root.remove_child(probe_stage)
        probe_stage.free()

    root.remove_child(app)
    app.free()
    await wait_frames()
    for path in [save_path, settings_path]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

    if failures.is_empty():
        print("ASTRA CREW GLIMPSE 070 TESTS OK · %d checks" % checks)
        quit(0)
    else:
        for failure in failures:
            printerr("FAIL · " + failure)
        quit(1)
