extends SceneTree
# Run after tests/legacy_fixture.gd in the unmodified 0.3.0 tree.
# Vote rules intentionally changed in 0.5.0; saved evidence and RNG must not.
func _initialize() -> void:
    var s := AstraGameSession.new()
    var expected := ConfigFile.new()
    if not s.load_snapshot("user://astra_030_compat.cfg") or expected.load("user://astra_030_expected.cfg") != OK:
        printerr("COMPAT FAIL: missing genuine 0.3.0 fixture")
        quit(1)
        return
    var good := s.roster.size() == 8 and s.null_count == 2 and s.phase == "VOTE"
    good = good and s.rng.state == expected.get_value("expected","saved_rng")
    good = good and s.clues == expected.get_value("expected","saved_clues")
    var resumed := AstraGameSession.new()
    good = good and resumed.load_snapshot("user://astra_030_compat.cfg")
    good = good and s.cast_vote(str(s.living_ids()[0])) == resumed.cast_vote(str(resumed.living_ids()[0]))
    s.advance()
    resumed.advance()
    if s.phase == "NIGHT":
        good = good and s.choose_night_action("protect",str(s.living_ids()[0])) == resumed.choose_night_action("protect",str(resumed.living_ids()[0]))
    good = good and s.rng.state == resumed.rng.state
    if good: print("ASTRA 0.3.0 SAVE COMPATIBILITY OK · original evidence/RNG and deterministic continuation")
    else: printerr("ASTRA SAVE COMPATIBILITY FAILED")
    AstraGameSession.delete_snapshot("user://astra_030_compat.cfg")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://astra_030_expected.cfg"))
    quit(0 if good else 1)
