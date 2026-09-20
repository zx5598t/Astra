extends SceneTree
# First-play UX regression (design doc §21) and cross-chapter narrative
# continuity (design doc §S): run CALIBRATION through LAST_LIGHT back to back
# and check the seams, not just that each chapter loads without an error.

var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failures.append(label)

# Names from the retired 0.3.x/0.4.0 murder-mystery campaign. If any of these
# ever reach live case_data again, the old plot has leaked back in.
const RETIRED_NAMES := ["Ives", "Orin", "Sael", "Tess", "Ren", "Ari"]

func close_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 20:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            check(s.voyage_choose(0),"choice applied")
        else:
            s.voyage_next()

func _initialize() -> void:
    test_first_play_regression()
    test_narrative_continuity()
    if failures.is_empty():
        print("ASTRA STORY CONSISTENCY TESTS OK · %d checks" % checks)
        quit(0)
    else:
        for failure in failures: printerr("FAIL · " + failure)
        quit(1)

# ---------------------------------------------------------------- §21 first play

func test_first_play_regression() -> void:
    var s := AstraGameSession.new()
    s.setup("CALIBRATION", 4242)
    s.begin_voyage()

    check(s.voyage_rooms().size() <= 2, "CALIBRATION: at most two rooms (%d)" % s.voyage_rooms().size())
    check(s.voyage_rooms() == ["medbay"], "CALIBRATION: single room is medbay")
    close_scene(s) # dismiss the opening awakening scene

    # Exactly one required investigation point before the goal is found — no
    # optional distraction points (destination/signal) are shown yet.
    var open_points := 0
    for point in s.voyage_points():
        var key := str(s.voyage["room"]) + ":" + str(point[0])
        if key not in s.voyage["inspected"]:
            open_points += 1
    check(open_points == 1, "CALIBRATION: exactly one open investigation point (%d)" % open_points)
    for point in s.voyage_points():
        check(s.voyage_inspect(str(point[0])), "CALIBRATION: required point inspectable")
        close_scene(s)
    check(s.voyage["goal_done"], "CALIBRATION: goal found from the single required point")

    # Never required to hunt four talk buttons. The panel scene introduces
    # Jun/Noa/Daren automatically; only Mira is a direct guided conversation.
    check(s.voyage_visit_person("mira"), "CALIBRATION: Mira is reachable without travel")
    close_scene(s)
    check(s.voyage["visits"] == ["medbay"], "CALIBRATION: never left medbay")
    check("mira" in s.voyage["met"], "CALIBRATION: required direct conversation completed")

    check(s.voyage_can_finish(), "CALIBRATION: can finish after one guided conversation")
    check(s.finish_voyage(), "CALIBRATION: finishes")
    check(s.phase == "RESULT", "CALIBRATION: routes straight to RESULT")
    check(s.outcome == "CONTINUE", "CALIBRATION: no win/lose judgement")
    # The phases a first-time player must never be asked to use.
    check(s.phase not in ["MEETING", "VOTE", "NIGHT"], "CALIBRATION: never reaches meeting/vote/night")

# ---------------------------------------------------------------- §S continuity

func test_narrative_continuity() -> void:
    var memory := {}
    var ids := ["CALIBRATION"] + AstraCaseCatalog.CAMPAIGN
    for i in range(ids.size()):
        var case_id: String = ids[i]
        var s := AstraGameSession.new()
        s.setup(case_id, 7000 + i)
        _check_case_data_clean(s.case_data, case_id)
        s.begin_voyage(memory)

        # Nobody still asleep this chapter shows up as a met crewmate or as a
        # roster member — the roster itself is the source of truth for "who is
        # awake", and case_data.roster (built from the same voyage roster) must
        # agree with it chapter by chapter.
        check(s.roster == AstraVoyageContent.awake_roster(case_id), "%s: roster matches awakening order" % case_id)
        check(s.case_data.get("roster", []) == s.roster, "%s: case_data roster matches voyage roster" % case_id)

        close_scene(s)
        for who in s.roster:
            s.voyage_visit_person(who)
            close_scene(s)
        if not s.voyage["goal_done"]:
            s.voyage_ask_goal(str(s.voyage_people()[0]))
            close_scene(s)
        check(s.voyage_can_finish(), "%s: exploration completes" % case_id)
        check(s.finish_voyage(), "%s: finish_voyage succeeds" % case_id)
        memory = s.voyage_memory()

func _check_case_data_clean(case_data: Dictionary, case_id: String) -> void:
    var blob := JSON.stringify(case_data)
    for name in RETIRED_NAMES:
        check(not blob.contains(name), "%s: case_data free of retired name '%s'" % [case_id, name])
    # A "records" challenge can never ask for more op-records than the roster's
    # null_count actually produced (the 0.4.0-era mismatch this pass fixed).
    var challenge: Dictionary = case_data.get("challenge", {})
    if str(challenge.get("id", "")) == "records":
        check(int(challenge.get("target", 1)) <= case_data.get("ops", []).size(),
            "%s: records challenge target within available ops" % case_id)
