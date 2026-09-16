extends SceneTree

const TheoryModelScript = preload("res://scripts/case_theory_model.gd")

class FakeNpc:
    extends RefCounted
    var display_name: String
    func _init(name_in: String) -> void:
        display_name = name_in

class FakeState:
    extends RefCounted
    var game_over := false
    var day := 1
    var npcs := {
        "a": FakeNpc.new("A"),
        "b": FakeNpc.new("B"),
        "c": FakeNpc.new("C")
    }
    var manual_links: Array[Dictionary] = [
        {"kind":"suspect", "target_id":"a"},
        {"kind":"question", "target_id":"b"}
    ]
    var contradiction_register: Array[Dictionary] = [
        {"npc_id":"a"}
    ]
    var hidden_null_ids: Array[String] = ["a", "c"]
    func phase_name() -> String:
        return "VOTE"

func _init() -> void:
    var state := FakeState.new()
    var theory = TheoryModelScript.new()
    theory.reset()
    var result: Dictionary = theory.submit_theory(state, "a", "b", 60)
    if not bool(result.get("ok", false)) or not theory.theory_ready_for_vote(1):
        push_error("CI SMOKE: theory submission failed")
        quit(1)
        return
    var final_result: Dictionary = theory.finalize(state)
    if int(final_result.get("matched", -1)) != 1:
        push_error("CI SMOKE: expected one matched Null")
        quit(1)
        return
    if int(final_result.get("grade", -1)) < 0:
        push_error("CI SMOKE: grading failed")
        quit(1)
        return
    print("ASTRA CI SMOKE OK · ", theory.theory_summary(state), " · grade ", int(final_result.get("grade", 0)))
    quit(0)
