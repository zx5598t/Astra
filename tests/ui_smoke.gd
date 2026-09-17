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
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(5)
    _expect(app._current is AstraTitleScreen, "title screen shown")

    for case_id in AstraCaseCatalog.CAMPAIGN:
        app.meta.case_counts[case_id] = 1
    var plan := [["DEAD_AIR", "ANALYST"], ["GLASS_GARDEN", "EMPATH"], ["ECHO_WARD", "AUDITOR"]]
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

    DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
    if failures.is_empty():
        print("ASTRA UI SMOKE OK")
        quit(0)
    else:
        quit(1)

func _play_case(case_id: String, protocol: String) -> void:
    app.start_case(case_id, protocol)
    await _wait(4)
    var screen = app._current
    _expect(screen is AstraGameScreen, "%s game screen" % case_id)
    var s: AstraGameSession = app.session
    var guard := 0
    while s.phase != "RESULT" and guard < 80:
        guard += 1
        var view = screen._view
        match s.phase:
            "INVESTIGATION":
                for room_id in s.room_ids():
                    if s.investigation_ap > 0:
                        view._search(str(room_id))
                        await _wait(1)
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    view._resolve_event(1)
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
