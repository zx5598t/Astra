extends SceneTree

const DeductionStateScript = preload("res://scripts/deduction_game_state.gd")

func _init() -> void:
    var state = DeductionStateScript.new()
    state.preferred_case_id = "DEAD_AIR"
    state.setup(909091)
    if state.crew_order.size() != 8:
        push_error("CI SMOKE: expected 8 crew")
        quit(1)
        return
    state.phase_index = 1
    state.investigation_actions_left = 4
    state.investigate(str(state.truth.incident["locations"][0]))
    state.phase_index = 4
    var p: String = str(state.crew_order[0])
    var s: String = str(state.crew_order[1])
    var result: Dictionary = state.submit_theory(p, s, 60)
    if not bool(result.get("ok", false)) or not state.theory_ready_for_vote():
        push_error("CI SMOKE: theory submission failed")
        quit(1)
        return
    print("ASTRA CI SMOKE OK · ", state.case_subtitle, " · ", state.theory_summary())
    quit(0)
