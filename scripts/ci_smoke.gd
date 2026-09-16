extends SceneTree

const TheoryModelScript = preload("res://scripts/case_theory_model.gd")

func _init() -> void:
    var state := AstraHypothesisGameState.new()
    state.preferred_case_id = "DEAD_AIR"
    state.setup(909091)
    if state.crew_order.size() != 8:
        push_error("CI SMOKE: expected 8 crew")
        quit(1)
        return

    state.phase_index = 1
    state.investigation_actions_left = 4
    state.investigate(str(state.truth.incident["locations"][0]))

    var theory = TheoryModelScript.new()
    theory.reset()
    state.phase_index = 4
    var p: String = str(state.crew_order[0])
    var s: String = str(state.crew_order[1])
    var result: Dictionary = theory.submit_theory(state, p, s, 60)
    if not bool(result.get("ok", false)) or not theory.theory_ready_for_vote(int(state.day)):
        push_error("CI SMOKE: theory submission failed")
        quit(1)
        return

    var final_result: Dictionary = theory.finalize(state)
    if not final_result.has("grade"):
        push_error("CI SMOKE: theory grading failed")
        quit(1)
        return

    print("ASTRA CI SMOKE OK · ", state.case_subtitle, " · ", theory.theory_summary(state), " · grade ", int(final_result.get("grade", 0)))
    quit(0)
