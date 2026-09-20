extends SceneTree

# Drives the real UI through a full case headlessly (title -> every phase ->
# result -> overlays). CI fails on any SCRIPT ERROR in the log or a missing
# success line. Uses separate save files so a player's archive is untouched.
#   godot --headless --path . --script res://tests/ui_smoke.gd

const META_PATH := "user://astra_smoke_meta.cfg"
const SETTINGS_PATH := "user://astra_smoke_settings.cfg"

var app
var failures: Array[String] = []

func _initialize() -> void:
    _run.call_deferred()

func _wait(frames: int = 3) -> void:
    for _i in range(frames):
        await process_frame

func _expect(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
        printerr("UI SMOKE FAIL · " + label)

func _run() -> void:
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(5)
    # 0.4.0: a first run opens on the cold open instead of the title. That path
    # gets its own check below; the rest of this run starts past it, the way a
    # returning player does.
    _expect(app._current is AstraOpeningView, "first run opens on the cold open")
    app._current._finish()
    await _wait(4)
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait(3)
    _expect(app._current is AstraVoyageView, "cold open enters real ship exploration")
    app.show_title()
    await _wait(3)
    _expect(app.settings.intro_seen, "compatibility intro flag is still written")
    _expect(app.meta.intro_seen_for_slot(app.active_slot), "finished opening is remembered for that save slot")
    var first_slot: int = int(app.active_slot)
    var second_slot: int = 1 if first_slot != 1 else 2
    app.start_new_campaign(second_slot)
    await _wait(3)
    _expect(app._current is AstraOpeningView, "new save slot shows calibration opening again")
    app._current._finish()
    await _wait(4)
    _expect(app.meta.intro_seen_for_slot(second_slot), "second save remembers its own opening")
    app.show_title()
    await _wait(2)
    app.start_case(AstraCaseCatalog.CALIBRATION, "ANALYST", second_slot)
    await _wait(3)
    _expect(not (app._current is AstraOpeningView), "same save slot does not repeat calibration opening")
    app.show_title()
    await _wait(2)
    app.active_slot = first_slot

    # The tutorial case has to be playable end to end before the campaign opens.
    await _play_case(AstraCaseCatalog.CALIBRATION, "ANALYST")
    app.meta.calibration_completed = true

    app.start_case("DEAD_AIR", "ANALYST")
    await _finish_exploration()
    app.session.advance()
    app.session.perform_mission()
    await _wait(3)
    var saved_seed: int = app.session.seed_value
    var saved_ap: int = app.session.investigation_ap
    app.show_title()
    await _wait(3)
    app.resume_case()
    await _wait(3)
    _expect(app.session.seed_value == saved_seed and app.session.investigation_ap == saved_ap, "resume exact case and AP")
    _expect(bool(app.session.flags.get("mission_complete", false)), "resume mission result")
    for case_id in AstraCaseCatalog.CAMPAIGN:
        app.meta.case_counts[case_id] = 1
    var plan := []
    for case_id in AstraCaseCatalog.CAMPAIGN:
        plan.append([case_id, "ANALYST"])
    for item in plan:
        await _play_case(str(item[0]), str(item[1]))

    app.show_help()
    await _wait()
    app.show_settings()
    await _wait()
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait()
    app.show_title()
    await _wait(4)
    _expect(app._current is AstraTitleScreen, "returned to title")

    AstraGameSession.delete_snapshot(app.snapshot_path())
    DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))

    # Tear the screen down before quitting. 0.4.0 builds far more nodes per
    # screen (relation cards, crew tags, sprite icons), and quitting with a full
    # tree plus a queue of pending queue_free()s makes Godot report leaked RIDs
    # at exit — which the release build treats as a failure.
    root.remove_child(app)
    app.free()
    app = null
    await _wait(4)

    if failures.is_empty():
        print("ASTRA UI SMOKE OK")
        quit(0)
    else:
        quit(1)

func _play_case(case_id: String, protocol: String) -> void:
    app.start_case(case_id, protocol)
    await _wait(4)
    # A fresh save slot owns its own calibration intro in 0.5.1. Complete that
    # short opening before expecting the voyage/game screen.
    if app._current is AstraOpeningView:
        app._current._finish()
        await _wait(4)
    # First-appearance cards stack up in front of a new roster; dismiss them the
    # way a player would before driving the case.
    for _pass in range(12):
        var open_modal := false
        for child in app.overlay_root().get_children():
            if child.has_method("close"):
                child.close(0)
                open_modal = true
        if not open_modal:
            break
        await _wait(2)
    await _finish_exploration()
    if app.session.phase == "RESULT":
        _expect(app.meta.calibration_completed,"first loop completes without voting")
        return
    var screen = app._current
    _expect(screen is AstraGameScreen, "%s game screen" % case_id)
    var s: AstraGameSession = app.session
    var guard := 0
    while s.phase != "RESULT" and guard < 80:
        guard += 1
        var view = screen._view
        match s.phase:
            "INVESTIGATION":
                view._perform_mission()
                await _wait(1)
                for room_id in s.room_ids():
                    if s.investigation_ap > 0:
                        view._search(str(room_id))
                        await _wait(1)
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    view._resolve_event(mini(1,s.pending_event["choices"].size()-1))
                    await _wait(2)
                for npc_id in s.living_ids():
                    if s.talk_ap <= 0:
                        break
                    screen.select(str(npc_id))
                    await _wait(1)
                    screen._view._do_ask(str(npc_id), "ALIBI", "")
                    await _wait(1)
            "MEETING":
                view._flush()
                if not s.found_clues().is_empty():
                    s.present_clue(str(s.found_clues()[0]["id"]))
                screen.select(str(s.living_ids()[0]))
                screen._view._accuse()
                await _wait(2)
                screen._view._flush()
            "VOTE":
                var ranked := AstraTestBots.ranked(s, true)
                s.set_mark(str(ranked[0]), "null")
                if ranked.size() > 1:
                    s.set_mark(str(ranked[1]), "null")
                screen.select(str(ranked[0]))
                await _wait(1)
                screen._view._cast(str(ranked[0]))
                await _wait(2)
            "NIGHT":
                screen.select(str(s.living_ids()[0]))
                await _wait(1)
                screen._view._choose("protect", str(s.living_ids()[0]))
                await _wait(2)
        s.advance()
        await _wait(2)
    _expect(s.phase == "RESULT", "%s/%s reached result" % [case_id, protocol])
    await _wait(4)
    _expect(not screen.archive_change.is_empty(), "%s/%s archive recorded" % [case_id, protocol])

func _close_scene() -> void:
    var s: AstraGameSession = app.session
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 20:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            s.voyage_choose(0)
        else:
            s.voyage_next()
    await _wait(2)

func _finish_exploration() -> void:
    var s: AstraGameSession = app.session
    if s.phase != "EXPLORE": return
    await _close_scene()
    for who in s.roster:
        s.voyage_visit_person(who)
        await _close_scene()
    if not s.voyage["goal_done"]:
        s.voyage_ask_goal(str(s.voyage_people()[0]))
        await _close_scene()
    _expect(s.voyage_can_finish(),"exploration has a reachable exit")
    s.finish_voyage()
    await _wait(3)
    if s.phase != "RESULT": app.show_session_screen()
    await _wait(3)
