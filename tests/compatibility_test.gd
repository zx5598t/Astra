extends SceneTree
func _initialize() -> void:
    var s := AstraGameSession.new()
    var expected := ConfigFile.new()
    if not s.load_snapshot("user://astra_030_compat.cfg") or expected.load("user://astra_030_expected.cfg")!=OK:
        printerr("COMPAT FAIL: missing genuine 0.3.0 fixture")
        quit(1)
        return
    var good := s.hypotheses().is_empty() and not s.tutorial_active()
    s.cast_vote(str(s.living_ids()[0]))
    s.advance()
    if s.phase=="NIGHT":s.choose_night_action("protect",str(s.living_ids()[0]))
    good = good and s.last_vote==expected.get_value("expected","vote") and s.night_result==expected.get_value("expected","night") and s.rng.state==expected.get_value("expected","rng")
    if good: print("ASTRA 0.3.0 SAVE COMPATIBILITY OK · exact vote, night and RNG")
    else: printerr("ASTRA SAVE COMPATIBILITY FAILED")
    AstraGameSession.delete_snapshot("user://astra_030_compat.cfg")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://astra_030_expected.cfg"))
    quit(0 if good else 1)
