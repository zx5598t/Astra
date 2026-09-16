extends SceneTree

func _init() -> void:
    var state := AstraDeductionGameState.new()
    state.preferred_case_id = "DEAD_AIR"
    state.setup(909091)
    if state.crew_order.size() != 8:
        push_error("CI SMOKE: expected 8 crew")
        quit(1)
        return
    state.phase_index = AstraGameState.PHASES.find("INVESTIGATION")
    state.investigation_actions_left = 4
    state.investigate(str(state.truth.incident["locations"][0]))
    state.phase_index = AstraGameState.PHASES.find("VOTE")
    var p := state.crew_order[0]
    var s := state.crew_order[1]
    var result := state.submit_theory(p, s, 60)
    if not bool(result.get("ok", false)) or not state.theory_ready_for_vote():
        push_error("CI SMOKE: theory submission failed")
        quit(1)
        return
    print("ASTRA CI SMOKE OK · ", state.case_subtitle, " · ", state.theory_summary())
    quit(0)
